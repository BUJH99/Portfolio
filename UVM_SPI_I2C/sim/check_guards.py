#!/usr/bin/env python3
"""Elaborate board wrappers separately and prove topology mismatch is rejected."""
import argparse
import json
from pathlib import Path
import re
from run_regression import ROOT, execute, tool

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--vivado-bin')
    args=parser.parse_args()
    out=args.output.resolve(); out.mkdir(parents=True,exist_ok=True)
    results=[]
    for role in ('master','slave'):
        work=ROOT/'sim/.build'/('board_'+role); work.mkdir(parents=True,exist_ok=True)
        files=[ROOT/'src/common/serial_protocol_pkg.sv',*sorted((ROOT/'src'/role).glob('*.sv')),ROOT/'src/boards'/role/'TOP.sv']
        command=[tool('xvlog',args.vivado_bin),'--sv',*map(str,files)]
        code,text=execute(command,work,out/f'board_{role}_compile.log')
        ok=code==0 and not re.search(r'^ERROR:',text,re.M)
        if ok:
            command=[tool('xelab',args.vivado_bin),'TOP','-s','board_'+role,'-timescale','1ns/1ps']
            code,text=execute(command,work,out/f'board_{role}_elaborate.log')
            ok=code==0 and 'Built simulation snapshot' in text
        results.append({'check':role+'_board_elaboration','passed':ok,'executed_hardware':False})
    work=ROOT/'sim/.build/xsim'
    command=[tool('xsim',args.vivado_bin),'serial_0','-runall','-sv_seed','1','-testplusarg','UVM_TESTNAME=SpiSlaveUnitTest','-cov_db_name','topology_guard']
    code,text=execute(command,work,out/'topology_mismatch.log')
    ok='[TOPOLOGY_MISMATCH]' in text and re.findall(r'^UVM_FATAL\s*:\s*(\d+)',text,re.M)==['1'] and '[SERIAL_RESULT]' not in text
    results.append({'check':'reject_spi_unit_test_on_loopback_harness','passed':ok,'expected_fatal':'TOPOLOGY_MISMATCH'})
    result={'passed':all(r['passed'] for r in results),'checks':results}
    (out/'guard_checks.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result,indent=2))
    return 0 if result['passed'] else 1

if __name__=='__main__': raise SystemExit(main())
