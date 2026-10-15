#!/usr/bin/env bash
# Build and run one UVM test with the selected topology and seed.
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
topology="${1:-0}"
test_name="${2:-SerialSmokeTest}"
seed="${3:-1}"
[[ "$topology" =~ ^[0-3]$ && "$test_name" =~ ^[A-Za-z][A-Za-z0-9_]*$ && "$seed" =~ ^[0-9]+$ ]] || {
  echo 'Usage: sim/run_vcs.sh <topology 0..3> <UVM test class> <seed>' >&2
  exit 2
}
build_path="$project_root/sim/.build/vcs/$topology"
mkdir -p "$build_path"
cd "$project_root"
vcs -full64 -sverilog -ntb_opts uvm-1.2 +incdir+. -f sim/files.f -top TbTop \
  "-pvalue+TbTop.P_TOPOLOGY=$topology" -timescale=1ns/1ps \
  "-Mdir=$build_path/csrc" -o "$build_path/simv" -l "$build_path/compile.log"
cd "$build_path"
./simv "+UVM_TESTNAME=$test_name" "+ntb_random_seed=$seed" -l run.log
python3 - <<'PY'
import json, re
from pathlib import Path
text=Path('run.log').read_text(errors='replace')
matches=re.findall(r'\[SERIAL_RESULT\]\s*(\{[^\r\n]+\})',text)
ok=len(matches)==1 and re.findall(r'^UVM_ERROR\s*:\s*(\d+)',text,re.M)==['0'] and re.findall(r'^UVM_FATAL\s*:\s*(\d+)',text,re.M)==['0']
ok=ok and not re.search(r'^(?:Error|Fatal|ERROR|FATAL)\s*[:\[]',text,re.M)
if matches:
    result=json.loads(matches[-1])
    ok=ok and result['pending']==0 and result['unexpected_errors']==0 and result['spi_verified']+result['i2c_verified']>0
raise SystemExit(0 if ok else 1)
PY
