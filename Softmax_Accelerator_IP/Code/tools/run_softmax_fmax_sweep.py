#!/usr/bin/env python3
"""Run post-route Fmax sweeps for SOFTMAX_ACC format candidates."""

from __future__ import annotations

import argparse
import csv
import json
import re
import shutil
import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CANDIDATES = (
    "qdrop0_explow4_ln10_shift11",
    "qdrop0_explow4_ln9_shift11",
    "qdrop0_explow4_ln8_shift11",
)


def find_vivado() -> str:
    for name in ("vivado.bat", "vivado"):
        found = shutil.which(name)
        if found:
            return found
    default_path = Path("C:/AMDDesignTools/2025.2/Vivado/bin/vivado.bat")
    if default_path.exists():
        return str(default_path)
    raise FileNotFoundError("Vivado executable not found")


@dataclass(frozen=True)
class FmaxCandidate:
    name: str
    ln_mant_bits: int

    @property
    def mant_drop_bits(self) -> int:
        return 10 - self.ln_mant_bits


def candidate_from_name(name: str) -> FmaxCandidate:
    match = re.fullmatch(r"qdrop0_explow4_ln(\d+)_shift11", name)
    if not match:
        raise ValueError(f"Unsupported Fmax candidate: {name}")
    ln_mant_bits = int(match.group(1))
    if ln_mant_bits not in (8, 9, 10):
        raise ValueError(f"Unsupported Ln mantissa width for Fmax sweep: {ln_mant_bits}")
    return FmaxCandidate(name=name, ln_mant_bits=ln_mant_bits)


def copy_tree(src: Path, dst: Path) -> None:
    if src.exists():
        shutil.copytree(src, dst)


def prepare_candidate_project(candidate: FmaxCandidate, run_root: Path, clock_period_ns: float) -> Path:
    work_dir = run_root / candidate.name
    work_dir.mkdir(parents=True, exist_ok=False)

    shutil.copy2(PROJECT_ROOT / "fpga_auto.yml", work_dir / "fpga_auto.yml")
    manifest = work_dir / "fpga_auto.yml"
    manifest.write_text(manifest.read_text(encoding="utf-8").replace("Source/", "src/").replace("Constraints/", "constrs/"), encoding="utf-8")
    copy_tree(PROJECT_ROOT / "Source", work_dir / "src")
    copy_tree(PROJECT_ROOT / "include", work_dir / "include")
    copy_tree(PROJECT_ROOT / "inc", work_dir / "inc")
    copy_tree(PROJECT_ROOT / "Constraints", work_dir / "constrs")
    (work_dir / "output" / "reports").mkdir(parents=True, exist_ok=True)
    (work_dir / "log").mkdir(parents=True, exist_ok=True)

    xdc_path = work_dir / "constrs" / "timing_100mhz.xdc"
    xdc_path.write_text(
        "\n".join(
            [
                "# Fmax sweep timing constraint.",
                f"create_clock -name iClk -period {clock_period_ns:.3f} [get_ports iClk]",
                "",
            ]
        ),
        encoding="utf-8",
    )

    if candidate.mant_drop_bits:
        format_path = work_dir / "include" / "SoftmaxFormat.vh"
        text = format_path.read_text(encoding="utf-8")
        original = "`define DEF_SOFTMAX_LN_MANT_LSB_DROP  0"
        replacement = f"`define DEF_SOFTMAX_LN_MANT_LSB_DROP  {candidate.mant_drop_bits}"
        if original not in text:
            raise RuntimeError(f"Could not patch Ln mantissa drop in {format_path}")
        format_path.write_text(text.replace(original, replacement), encoding="utf-8")

    return work_dir


def write_impl_tcl(work_dir: Path, clock_period_ns: float) -> Path:
    tcl_path = work_dir / "run_fmax_impl.tcl"
    lines = [
        "set project_root [file normalize [lindex $argv 0]]",
        f"set clock_period_ns {clock_period_ns:.3f}",
        "set output_dir [file join $project_root output]",
        "set report_dir [file join $output_dir reports]",
        "file mkdir $report_dir",
        "create_project -in_memory -part xczu3eg-sbva484-1-i",
        "set_property include_dirs [list [file join $project_root include] [file join $project_root inc]] [get_filesets sources_1]",
        "set src_files [glob -nocomplain -directory [file join $project_root src] *.v]",
        "read_verilog $src_files",
        "read_xdc [file join $project_root constrs timing_100mhz.xdc]",
        "synth_design -top TOP -part xczu3eg-sbva484-1-i -flatten_hierarchy rebuilt",
        "write_checkpoint -force [file join $output_dir post_synth.dcp]",
        "opt_design",
        "place_design",
        "phys_opt_design",
        "route_design",
        "write_checkpoint -force [file join $output_dir post_route.dcp]",
        "report_timing_summary -file [file join $report_dir timing_summary.rpt]",
        "report_utilization -file [file join $report_dir post_route_util.rpt]",
        "set setup_paths [get_timing_paths -max_paths 1 -setup]",
        "if {[llength $setup_paths] == 0} { set wns -999.0 } else { set wns [get_property SLACK [lindex $setup_paths 0]] }",
        "set fmax_est_mhz 0.0",
        "if {$wns > -999.0 && ($clock_period_ns - $wns) > 0.0} { set fmax_est_mhz [expr {1000.0 / ($clock_period_ns - $wns)}] }",
        "set fh [open [file join $output_dir fmax_metrics.json] w]",
        "puts $fh [format {{\"clockPeriodNs\":%.3f,\"wnsNs\":%.6f,\"fmaxEstMHz\":%.6f}} $clock_period_ns $wns $fmax_est_mhz]",
        "close $fh",
        "exit 0",
        "",
    ]
    tcl_path.write_text("\n".join(lines), encoding="utf-8")
    return tcl_path


def parse_utilization(report_path: Path) -> dict[str, int | None]:
    text = report_path.read_text(encoding="utf-8", errors="ignore") if report_path.exists() else ""

    def find_row(label: str) -> int | None:
        match = re.search(rf"\|\s*{re.escape(label)}\*?\s*\|\s*(\d+)", text)
        return int(match.group(1)) if match else None

    return {
        "lutUsed": find_row("Slice LUTs"),
        "ffUsed": find_row("Slice Registers"),
        "dspUsed": find_row("DSPs"),
    }


def run_candidate(candidate: FmaxCandidate, run_root: Path, clock_period_ns: float) -> dict[str, object]:
    work_dir = prepare_candidate_project(candidate, run_root, clock_period_ns)
    tcl_path = write_impl_tcl(work_dir, clock_period_ns)
    log_path = work_dir / "log" / "vivado_fmax.log"
    jou_path = work_dir / "log" / "vivado_fmax.jou"

    cmd = [
        find_vivado(),
        "-mode",
        "batch",
        "-log",
        str(log_path),
        "-journal",
        str(jou_path),
        "-notrace",
        "-source",
        str(tcl_path),
        "-tclargs",
        str(work_dir),
    ]
    result = subprocess.run(cmd, cwd=work_dir, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    metrics_path = work_dir / "output" / "fmax_metrics.json"
    metrics = json.loads(metrics_path.read_text(encoding="utf-8")) if metrics_path.exists() else {}
    util = parse_utilization(work_dir / "output" / "reports" / "post_route_util.rpt")

    return {
        "name": candidate.name,
        "ln_mant_bits": candidate.ln_mant_bits,
        "clock_period_ns": clock_period_ns,
        "vivado_rc": result.returncode,
        "wns_ns": metrics.get("wnsNs"),
        "fmax_est_mhz": metrics.get("fmaxEstMHz"),
        **util,
        "work_dir": str(work_dir),
        "timing_report": str(work_dir / "output" / "reports" / "timing_summary.rpt"),
        "util_report": str(work_dir / "output" / "reports" / "post_route_util.rpt"),
        "vivado_log": str(log_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--clock-period-ns", type=float, default=10.0)
    parser.add_argument("--candidates", nargs="*", default=list(DEFAULT_CANDIDATES))
    parser.add_argument("--out-dir", default=str(PROJECT_ROOT / "output" / "fmax_sweep"))
    args = parser.parse_args()

    candidates = [candidate_from_name(name) for name in args.candidates]
    out_dir = Path(args.out_dir).resolve()
    run_id = datetime.now().strftime("%Y%m%d_%H%M%S")
    run_root = out_dir / "work" / run_id
    run_root.mkdir(parents=True, exist_ok=False)

    rows = []
    for candidate in candidates:
        print(f"[RUN] {candidate.name}", flush=True)
        rows.append(run_candidate(candidate, run_root, args.clock_period_ns))

    rows.sort(key=lambda row: (row.get("fmax_est_mhz") is None, -(float(row.get("fmax_est_mhz") or 0.0))))
    summary = {
        "schemaVersion": 1,
        "project": "SOFTMAX_ACC",
        "clockPeriodNs": args.clock_period_ns,
        "runRoot": str(run_root),
        "winner": rows[0] if rows else None,
        "rows": rows,
    }

    out_dir.mkdir(parents=True, exist_ok=True)
    json_path = out_dir / "softmax_fmax_sweep.json"
    csv_path = out_dir / "softmax_fmax_sweep.csv"
    json_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    print(json.dumps({"winner": summary["winner"], "json": str(json_path), "csv": str(csv_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
