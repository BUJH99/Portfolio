#!/usr/bin/env python3
"""Sweep SOFTMAX_ACC fixed-point precision candidates against regression frames."""

from __future__ import annotations

import argparse
import csv
import json
import math
import struct
import sys
from dataclasses import dataclass
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
MODEL_TOOLS = PROJECT_ROOT / "Testbench" / "UVM" / "TOP_tb" / "tools"
sys.path.insert(0, str(MODEL_TOOLS))

from top_golden_model import RtlModel, highest_set_bit, signed16  # noqa: E402


def bits_to_float(value: int) -> float:
    return struct.unpack(">f", struct.pack(">I", value & 0xFFFFFFFF))[0]


def load_jsonl(path: Path) -> list[dict[str, object]]:
    if not path.exists():
        return []
    rows: list[dict[str, object]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            rows.append(json.loads(line))
    return rows


def iter_regression_pairs(tb_runtime: Path) -> list[tuple[dict[str, object], dict[str, object]]]:
    pairs: list[tuple[dict[str, object], dict[str, object]]] = []
    for input_path in sorted(tb_runtime.glob("test_*/input_frames.jsonl")):
        expected_path = input_path.with_name("expected_frames.jsonl")
        inputs = load_jsonl(input_path)
        expected = load_jsonl(expected_path)
        for frame_in, frame_exp in zip(inputs, expected):
            pairs.append((frame_in, frame_exp))
    return pairs


def csv_u32(value: object) -> list[int]:
    text = str(value or "")
    return [int(token, 16) for token in text.split(",") if token]


def csv_hex(values: list[int], width: int) -> str:
    return ",".join(f"{value & ((1 << (width * 4)) - 1):0{width}x}" for value in values)


def quantize_signed_q78(value: int, lsb_drop: int) -> int:
    if lsb_drop <= 0:
        return signed16(value)
    signed_value = signed16(value)
    rounded = (signed_value + (1 << (lsb_drop - 1))) if signed_value >= 0 else (signed_value - (1 << (lsb_drop - 1)))
    quantized = (rounded >> lsb_drop) << lsb_drop
    if quantized > 32767:
        return 32767
    if quantized < -32768:
        return -32768
    return signed16(quantized)


@dataclass(frozen=True)
class FormatCandidate:
    name: str
    q78_lsb_drop: int
    exp_low_bits: int
    ln_mant_bits: int
    sum_shift_bits: int

    @property
    def sum_acc_w(self) -> int:
        return self.sum_shift_bits + 16

    @property
    def estimated_cost(self) -> int:
        exp_cost = 100 if self.exp_low_bits == 4 else 82 if self.exp_low_bits == 2 else 68 if self.exp_low_bits == 0 else 90
        ln_cost = 40 + (1 << self.ln_mant_bits) // 32
        q_cost = 20 - (self.q78_lsb_drop * 2)
        sum_cost = self.sum_acc_w
        return exp_cost + ln_cost + q_cost + sum_cost


class VariantModel(RtlModel):
    def __init__(self, src_dir: Path, candidate: FormatCandidate) -> None:
        super().__init__(src_dir)
        self.candidate = candidate

    def exp_approx(self, value: int) -> int:
        abs_value = self.abs_sat_q78(value)
        if self.candidate.exp_low_bits < 4:
            drop = 4 - self.candidate.exp_low_bits
            abs_value = (abs_value >> drop) << drop

        high_coeff_en = ((abs_value >> 12) & 0x7) == 0
        coeff_high = self.exp_high.get((abs_value >> 8) & 0xF, 0xFFFF) if high_coeff_en else 0
        coeff_mid = self.exp_mid.get((abs_value >> 4) & 0xF, 0xFFFF)
        coeff_low = self.exp_low.get(abs_value & 0xF, 0xFFFF)
        prod_mid_low = coeff_mid * coeff_low
        prod_high_scale = coeff_high * ((prod_mid_low >> 16) & 0xFFFF)
        return (prod_high_scale >> 16) & 0xFFFF

    def ln_approx(self, value: int) -> int:
        if value == 0:
            exp_addr = 0
            mant_addr = 0
        else:
            msb_idx = highest_set_bit(value & 0xFFFF)
            exp_addr = msb_idx + 10
            norm_shift = (value & 0xFFFF) << (15 - msb_idx)
            mant_addr = (norm_shift >> 5) & 0x3FF

        if self.candidate.ln_mant_bits < 10:
            drop = 10 - self.candidate.ln_mant_bits
            mant_addr = (mant_addr >> drop) << drop

        ln_exp_term = self.ln_exp[exp_addr]
        ln_mant_term = self.ln_mant[mant_addr]
        ln_sum_q4p16 = (ln_exp_term << 5) + ln_mant_term
        ln_round_q78 = (ln_sum_q4p16 >> 8) + ((ln_sum_q4p16 >> 7) & 0x1)
        return signed16(ln_round_q78)

    def process_frame(self, frame: dict[str, object]) -> dict[str, object]:
        input_values = csv_u32(frame["data_hex_csv"])
        keep_values = [int(token, 16) for token in str(frame["keep_hex_csv"]).split(",") if token]

        q78_inputs = [quantize_signed_q78(self.fp32_to_q78(value), self.candidate.q78_lsb_drop) for value in input_values]
        q78_max = max(q78_inputs) if q78_inputs else 0
        downscale = [self.q78_sub_sat(value, q78_max) for value in q78_inputs]
        exp_sum_values = [self.exp_approx(value) for value in downscale]

        acc_mask = (1 << self.candidate.sum_acc_w) - 1
        sum_acc = 0
        for value in exp_sum_values:
            sum_acc = (sum_acc + value) & acc_mask
        round_bias = 1 << (self.candidate.sum_shift_bits - 1)
        sum_round_acc = (sum_acc + round_bias) & acc_mask
        sum_q78 = (sum_round_acc >> self.candidate.sum_shift_bits) & 0xFFFF

        scalar_q78 = self.ln_approx(sum_q78)
        sub_values = [self.q78_sub_sat(value, scalar_q78) for value in downscale]
        exp_out_values = [self.exp_approx(value) for value in sub_values]
        output_values = [self.u16_to_fp32(value) for value in exp_out_values]

        argmax_value = max(q78_inputs) if q78_inputs else 0
        quantized_argmax_set = [idx for idx, value in enumerate(q78_inputs) if value == argmax_value]

        return {
            "frame_id": int(frame["frame_id"]),
            "scenario": frame["scenario"],
            "scalar_q78": signed16(scalar_q78),
            "sum_q78": signed16(sum_q78),
            "raw_argmax": quantized_argmax_set[0] if quantized_argmax_set else 0,
            "argmax_csv": ",".join(str(idx) for idx in quantized_argmax_set),
            "input_hex_csv": csv_hex(input_values, 8),
            "output_hex_csv": csv_hex(output_values, 8),
            "keep_hex_csv": ",".join("f" for _ in output_values),
            "input_keep_hex_csv": ",".join(f"{value:01x}" for value in keep_values),
        }


def build_candidates() -> list[FormatCandidate]:
    candidates: list[FormatCandidate] = []
    for q_drop in (0, 1, 2):
        for exp_low_bits in (4, 2, 0):
            for ln_bits in (10, 9, 8):
                for sum_shift in (10, 11, 12):
                    candidates.append(
                        FormatCandidate(
                            name=f"qdrop{q_drop}_explow{exp_low_bits}_ln{ln_bits}_shift{sum_shift}",
                            q78_lsb_drop=q_drop,
                            exp_low_bits=exp_low_bits,
                            ln_mant_bits=ln_bits,
                            sum_shift_bits=sum_shift,
                        )
                    )
    return candidates


def exp_component_mismatches(candidate: FormatCandidate) -> int:
    if candidate.exp_low_bits == 4:
        return 0
    baseline = VariantModel(PROJECT_ROOT / "Source", FormatCandidate("baseline", 0, 4, 10, 11))
    model = VariantModel(PROJECT_ROOT / "Source", candidate)
    mismatches = 0
    for value in range(-32768, 32768):
        if baseline.exp_approx(value) != model.exp_approx(value):
            mismatches += 1
    return mismatches


def ln_component_mismatches(candidate: FormatCandidate) -> int:
    if candidate.ln_mant_bits == 10:
        return 0
    baseline = VariantModel(PROJECT_ROOT / "Source", FormatCandidate("baseline", 0, 4, 10, 11))
    model = VariantModel(PROJECT_ROOT / "Source", candidate)
    mismatches = 0
    for value in range(0, 65536):
        if baseline.ln_approx(value) != model.ln_approx(value):
            mismatches += 1
    return mismatches


def evaluate_candidate(candidate: FormatCandidate, pairs: list[tuple[dict[str, object], dict[str, object]]]) -> dict[str, object]:
    model = VariantModel(PROJECT_ROOT / "Source", candidate)
    total_beats = 0
    mismatches = 0
    max_abs_err = 0.0
    sum_abs_err = 0.0
    max_rel_err = 0.0
    sum_rel_err = 0.0
    numeric_count = 0
    argmax_mismatch_frames = 0
    first_mismatch = ""

    for frame_in, frame_exp in pairs:
        actual = model.process_frame(frame_in)
        exp_outputs = csv_u32(frame_exp.get("output_hex_csv", ""))
        act_outputs = csv_u32(actual.get("output_hex_csv", ""))
        total_beats += max(len(exp_outputs), len(act_outputs))

        if str(frame_exp.get("argmax_csv", "")) != str(actual.get("argmax_csv", "")):
            argmax_mismatch_frames += 1

        for idx in range(max(len(exp_outputs), len(act_outputs))):
            exp_bits = exp_outputs[idx] if idx < len(exp_outputs) else None
            act_bits = act_outputs[idx] if idx < len(act_outputs) else None
            if exp_bits != act_bits:
                mismatches += 1
                if not first_mismatch:
                    first_mismatch = f"{frame_in.get('scenario')} beat {idx}: exp={exp_bits!r} act={act_bits!r}"
            if exp_bits is None or act_bits is None:
                continue
            exp_float = bits_to_float(exp_bits)
            act_float = bits_to_float(act_bits)
            if not (math.isfinite(exp_float) and math.isfinite(act_float)):
                continue
            abs_err = abs(act_float - exp_float)
            rel_err = abs_err / max(abs(exp_float), 1.0e-12)
            max_abs_err = max(max_abs_err, abs_err)
            sum_abs_err += abs_err
            max_rel_err = max(max_rel_err, rel_err)
            sum_rel_err += rel_err
            numeric_count += 1

    mismatch_rate = (100.0 * mismatches / total_beats) if total_beats else 0.0
    avg_abs_err = (sum_abs_err / numeric_count) if numeric_count else 0.0
    avg_rel_err = (sum_rel_err / numeric_count) if numeric_count else 0.0
    exact_pass = mismatches == 0 and argmax_mismatch_frames == 0
    tolerance_pass = (
        argmax_mismatch_frames == 0
        and mismatch_rate <= 5.0
        and avg_abs_err <= 1.0e-4
        and max_abs_err <= 2.0e-3
    )
    exp_mismatches = exp_component_mismatches(candidate)
    ln_mismatches = ln_component_mismatches(candidate)
    safe_exact_pass = (
        exact_pass
        and candidate.q78_lsb_drop == 0
        and candidate.sum_shift_bits == 11
        and exp_mismatches == 0
        and ln_mismatches == 0
    )

    return {
        "name": candidate.name,
        "q78_lsb_drop": candidate.q78_lsb_drop,
        "exp_low_bits": candidate.exp_low_bits,
        "ln_mant_bits": candidate.ln_mant_bits,
        "sum_shift_bits": candidate.sum_shift_bits,
        "sum_acc_w": candidate.sum_acc_w,
        "estimated_cost": candidate.estimated_cost,
        "total_beats": total_beats,
        "mismatch_beats": mismatches,
        "mismatch_rate_pct": mismatch_rate,
        "argmax_mismatch_frames": argmax_mismatch_frames,
        "avg_abs_err": avg_abs_err,
        "max_abs_err": max_abs_err,
        "avg_rel_err_pct": avg_rel_err * 100.0,
        "max_rel_err_pct": max_rel_err * 100.0,
        "exact_pass": exact_pass,
        "safe_exact_pass": safe_exact_pass,
        "tolerance_pass": tolerance_pass,
        "exp_component_mismatches": exp_mismatches,
        "ln_component_mismatches": ln_mismatches,
        "first_mismatch": first_mismatch,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tb-runtime", default=str(PROJECT_ROOT / "tb_runtime"))
    parser.add_argument("--out", default=str(PROJECT_ROOT / "output" / "qor" / "softmax_format_sweep.json"))
    parser.add_argument("--csv", default=str(PROJECT_ROOT / "output" / "qor" / "softmax_format_sweep.csv"))
    args = parser.parse_args()

    pairs = iter_regression_pairs(Path(args.tb_runtime))
    if not pairs:
        raise SystemExit("No regression frames found under tb_runtime/test_*")

    rows = [evaluate_candidate(candidate, pairs) for candidate in build_candidates()]
    rows.sort(key=lambda row: (not bool(row["exact_pass"]), row["estimated_cost"], row["mismatch_rate_pct"], row["max_abs_err"]))

    exact_rows = [row for row in rows if row["exact_pass"]]
    safe_exact_rows = [row for row in rows if row["safe_exact_pass"]]
    tolerance_rows = sorted(
        [row for row in rows if row["tolerance_pass"]],
        key=lambda row: (row["estimated_cost"], row["mismatch_rate_pct"], row["max_abs_err"]),
    )
    baseline = next(row for row in rows if row["name"] == "qdrop0_explow4_ln10_shift11")

    summary = {
        "schemaVersion": 1,
        "project": "SOFTMAX_ACC",
        "frameCount": len(pairs),
        "candidateCount": len(rows),
        "baseline": baseline,
        "recommendedRegressionExact": exact_rows[0] if exact_rows else None,
        "recommendedSafeExact": safe_exact_rows[0] if safe_exact_rows else None,
        "recommendedTolerance": tolerance_rows[0] if tolerance_rows else None,
        "thresholds": {
            "exact": "0 output beat mismatches and 0 argmax-set mismatches against current bit-accurate golden",
            "safeExact": "exact plus no exhaustive Exp/Ln component mismatches, q78_lsb_drop == 0, sum_shift_bits == 11",
            "tolerance": "argmax mismatches 0, mismatch_rate <= 5%, avg_abs_err <= 1e-4, max_abs_err <= 2e-3",
        },
        "topExact": exact_rows[:10],
        "topSafeExact": safe_exact_rows[:10],
        "topTolerance": tolerance_rows[:10],
        "rows": rows,
    }

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    csv_path = Path(args.csv)
    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    print(json.dumps({
        "frameCount": len(pairs),
        "candidateCount": len(rows),
        "recommendedRegressionExact": summary["recommendedRegressionExact"],
        "recommendedSafeExact": summary["recommendedSafeExact"],
        "recommendedTolerance": summary["recommendedTolerance"],
        "json": str(out_path),
        "csv": str(csv_path),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
