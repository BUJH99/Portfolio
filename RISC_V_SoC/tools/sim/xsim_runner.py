#!/usr/bin/env python3
"""Compatibility entry point for the standalone portfolio regression."""
import argparse, subprocess, sys
from pathlib import Path
root=Path(__file__).resolve().parents[2]
groups={
 "axi_apb_bus":["DataBusAxiLiteMaster","AxiLiteToApbBridge","APB_Timer","CsrFile_Timer","TrapController_Timer"],
 "uart_inst_dma":["uart_inst_dma"],"bubble_sort_e2e":["bubble_sort_e2e"],
 "master_slave_preflight":["board_preflight"]}
ap=argparse.ArgumentParser(); ap.add_argument("scenario",choices=groups); args,extra=ap.parse_known_args()
cmd=[sys.executable,str(root.parent/"tools/run_xsim.py"),str(root/"tests.json")]
for name in groups[args.scenario]: cmd += ["--job",name]
raise SystemExit(subprocess.call(cmd+extra))
