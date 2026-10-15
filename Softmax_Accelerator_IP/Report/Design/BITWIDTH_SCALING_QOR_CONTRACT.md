# SOFTMAX_ACC Bit-Width, Scaling, and QoR Contract

This project treats the softmax datapath as a fixed-point pipeline with explicit format boundaries. Timing margin is accepted only when the numerical contract, timing constraint, resource budget, and generated artifacts can be reproduced from the project files.

## Numeric Contract

| Boundary | Format | Width | Fraction | Owner |
| --- | --- | ---: | ---: | --- |
| AXI-stream input/output | IEEE-754 FP32 | 32 | n/a | `TOP`, `Fp32ToQ78`, `U16ToFp32` |
| Downscaled logits | signed Q7.8 | 16 | 8 | `Fp32ToQ78`, `Q78SubSat`, `Q78Ram`, `FrameBuf` |
| Exponential terms | unsigned U0.16 | 16 | 16 | `ExpSum`, `ExpOut`, `Sum`, `U16ToFp32` |
| Frame sum accumulator | unsigned fixed-point | 27 | 16 before downshift | `Sum` |
| Natural-log internal sum | signed Q4.16 | 21 | 16 | `Ln` |
| Natural-log output | signed Q7.8 | 16 | 8 | `Ln`, `Sub`, `ExpOut` |

The single source of truth for these widths is `include/SoftmaxFormat.vh`. RTL modules keep localparams near their logic, but derive shared widths and scaling points from that header. `DEF_SOFTMAX_LN_MANT_LSB_DROP` defaults to `0`; Fmax-only trials set it to `2` in temporary candidate builds for `qdrop0_explow4_ln8_shift11`.

## Objective Gates

| Gate | Pass condition | Current target |
| --- | --- | --- |
| Internal clock timing | `WNS >= 0 ns` and `TNS == 0 ns` | `iClk = 10.000 ns` |
| Functional regression | Golden testbench summary passes | `tb_runtime/report_all.html` all pass |
| LUT budget | `LUT <= 2500` | XC7A35T |
| FF budget | `FF <= 800` | XC7A35T |
| DSP budget | `DSP <= 4` | Keep multiply mapping bounded |
| Bitstream | At least one `.bit` under `output/` | Requires real board `PACKAGE_PIN`/`LOC` and `IOSTANDARD` constraints |
| Signoff constraints | No unconstrained clocks/internal endpoints; board I/O constraints reviewed | Current smoke XDC constrains only `iClk` |

## Fast Workflow

1. Update numeric widths only through `include/SoftmaxFormat.vh` and the module-local scaling constants that consume it.
2. Run the functional regression before timing if the arithmetic behavior changed.
3. Run `tools/run_softmax_qor.ps1 -RunBuild` to launch Doctor, Vivado build, summary capture, and QoR extraction.
4. Review `output/qor/softmax_qor_summary.json` for WNS/TNS, utilization, power, bitstream existence, and unconstrained path checks.
5. Treat the result as timing-smoke clean only until real board pin, IOSTANDARD, and input/output delay constraints are added.

## Latest Smoke Result

Captured on 2026-06-23 with `iClk = 10.000 ns`:

| Metric | Result |
| --- | ---: |
| WNS | 2.249 ns |
| TNS | 0.000 ns |
| WHS | 0.093 ns |
| LUT | 1924 |
| FF | 478 |
| DSP | 4 |
| Total on-chip power | 0.090 W |

Internal timing, clock constraints, and resource budgets pass. Bitstream generation is blocked by Vivado DRC `NSTD-1` and `UCIO-1` because the top-level ports do not yet have board `IOSTANDARD` and pin/LOC constraints. The workflow intentionally does not downgrade those DRC checks.

## Format Sweep Result

`tools/sweep_softmax_formats.py` evaluates RTL-compatible precision candidates against the saved regression frames and adds exhaustive component checks for `Exp` and `Ln`.

| Decision | Format |
| --- | --- |
| Safe exact recommendation | `qdrop0_explow4_ln10_shift11` |
| Q format | signed Q7.8, 16-bit |
| Exp format | U0.16, 16-bit, full low 4-bit segment |
| Sum scaling | shift 11, accumulator 27-bit |
| Ln mantissa address | 10-bit |

The regression-only winner was `qdrop0_explow4_ln8_shift11`, but it is rejected for source-level optimization because exhaustive `Ln` input checking finds 17,513 mismatches across the 16-bit `Ln` input space. The safe exact result therefore keeps the current `Ln` mantissa width.

## Fmax Sweep Result

`tools/run_softmax_fmax_sweep.py` runs direct Vivado synth/place/phys_opt/route implementations for the regression-exact candidates and records post-route WNS, utilization, and WNS-derived Fmax. The sweep intentionally excludes non-exact candidates from the Fmax race because they already change saved regression-frame outputs.

| Candidate | Best sampled pass | WNS | Fmax estimate | LUT | FF | DSP | Note |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `qdrop0_explow4_ln8_shift11` | 5.400 ns | 0.040 ns | 186.567 MHz | 1865 | 476 | 4 | Fmax-only winner |
| `qdrop0_explow4_ln10_shift11` | 5.600 ns | 0.176 ns | 184.366 MHz | 1976 | 478 | 4 | Safe-exact/current winner |
| `qdrop0_explow4_ln9_shift11` | 5.600 ns | 0.009 ns | 178.859 MHz | 1906 | 477 | 4 | Middle precision |

At 5.350 ns all sampled candidates missed setup timing; the best failing result was `qdrop0_explow4_ln8_shift11` with WNS `-0.012 ns`. Vivado QoR is not strictly monotonic across target periods because tighter constraints can trigger different placement and routing choices. For that reason, the Fmax recommendation is based on the best sampled passing implementation, not a single relaxed-clock WNS extrapolation.

Decision split:

| Objective | Recommendation |
| --- | --- |
| Preserve current safe exact behavior | Keep `qdrop0_explow4_ln10_shift11` |
| Maximize observed post-route Fmax among regression-exact candidates | Use `qdrop0_explow4_ln8_shift11` |
