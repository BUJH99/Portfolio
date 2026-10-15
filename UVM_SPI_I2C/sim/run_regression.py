#!/usr/bin/env python3
"""Compile and run the UVM matrix with XSim; fail on diagnostics, vacuous or stale results."""
from __future__ import annotations
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
MODES = ['LOOPBACK', 'SPI_SLAVE_UNIT', 'I2C_SLAVE_UNIT', 'DUAL_SLAVE_UNIT']

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def tool(name: str, vivado_bin: str | None) -> str:
    suffix = '.bat' if os.name == 'nt' else ''
    executable = str(Path(vivado_bin) / (name + suffix)) if vivado_bin else shutil.which(name + suffix)
    if not executable or not Path(executable).is_file():
        raise RuntimeError(f'{name} not found; add Vivado/bin to PATH or pass --vivado-bin')
    return executable

def execute(command: list[str], cwd: Path, log: Path, timeout: int = 300) -> tuple[int, str]:
    # cmd.exe treats unquoted '=' as a batch argument separator. Keep simulator
    # generic/plusarg assignments intact when invoking AMD's Windows wrappers.
    invocation = command
    if os.name == 'nt' and command[0].lower().endswith('.bat'):
        invocation = ' '.join('"'+arg+'"' if '=' in arg and not any(c in arg for c in ' \t"')
                              else subprocess.list2cmdline([arg]) for arg in command)
    try:
        result = subprocess.run(invocation, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                encoding='utf-8', errors='replace', timeout=timeout)
        code, output = result.returncode, result.stdout
    except subprocess.TimeoutExpired as exc:
        code = 124
        output = (exc.stdout or b'').decode('utf-8', 'replace') if isinstance(exc.stdout, bytes) else (exc.stdout or '')
        output += '\nRUNNER_TIMEOUT\n'
    log.parent.mkdir(parents=True, exist_ok=True)
    log.write_text(output, encoding='utf-8')
    return code, output

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--test', action='append', help='Exact UVM class name; repeat for multiple classes')
    parser.add_argument('--topology', choices=MODES)
    parser.add_argument('--seed', type=int, help='Replace matrix seeds with one seed')
    parser.add_argument('--vivado-bin')
    parser.add_argument('--output', type=Path)
    parser.add_argument('--waves', action='store_true')
    args = parser.parse_args()
    jobs = json.loads((ROOT/'sim/tests.json').read_text(encoding='utf-8'))['tests']
    if args.test:
        unknown = set(args.test) - {j['test'] for j in jobs}
        if unknown: parser.error(f'Unknown tests: {sorted(unknown)}')
        jobs = [j for j in jobs if j['test'] in args.test]
    if args.topology: jobs = [j for j in jobs if j['topology'] == args.topology]
    if args.seed is not None:
        jobs = list({(j['test'], j['topology']): dict(j, seed=args.seed) for j in jobs}.values())
    if not jobs: parser.error('No jobs selected')
    output = args.output or ROOT/'results'/dt.datetime.now().strftime('%Y-%m-%d_%H%M%S')
    output = output.resolve()
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        parser.error('Use a new empty output directory for regression results')
    output.mkdir(parents=True, exist_ok=True)
    build = ROOT/'sim/.build/xsim'
    build.mkdir(parents=True, exist_ok=True)
    executables = {name: tool(name, args.vivado_bin) for name in ('xvlog','xelab','xsim')}
    code, version = execute([executables['xvlog'],'-version'], build, output/'tool_version.log')
    if code: raise RuntimeError(version)
    paths = sorted([p for folder in ('src','tb') for p in (ROOT/folder).rglob('*') if p.suffix in ('.sv','.svh')])
    hashes = {p.relative_to(ROOT).as_posix(): sha(p) for p in paths}
    source_hash = hashlib.sha256(json.dumps(hashes,sort_keys=True).encode()).hexdigest()
    filelist_hash = sha(ROOT/'sim/files.f')
    fingerprint = source_hash + filelist_hash + version
    compile_stamp = build/'compiled.json'
    prior = json.loads(compile_stamp.read_text()) if compile_stamp.exists() else {}
    sources = [str(ROOT/p) for p in (ROOT/'sim/files.f').read_text().splitlines() if p and not p.startswith('#')]
    commands = []
    if prior.get('fingerprint') != fingerprint:
        command = [executables['xvlog'],'--sv','-L','uvm','-i',str(ROOT),*sources]
        commands.append(command)
        code, text = execute(command,build,output/'compile.log')
        if code or re.search(r'^ERROR:',text,re.M):
            print(text[-12000:]); return 2
        prior = {'fingerprint':fingerprint,'topologies':[]}
        compile_stamp.write_text(json.dumps(prior))
    for mode in sorted({j['topology_id'] for j in jobs}):
        if mode not in prior['topologies']:
            command = [executables['xelab'],'TbTop','-L','uvm','-s',f'serial_{mode}',
                       '-debug','typical','-timescale','1ns/1ps','-generic_top',f'P_TOPOLOGY={mode}']
            commands.append(command)
            code, text = execute(command,build,output/f'elaborate_{mode}.log')
            if code or re.search(r'^ERROR:',text,re.M):
                print(text[-12000:]); return 2
            prior['topologies'].append(mode)
            compile_stamp.write_text(json.dumps(prior))
    results = []
    for job in jobs:
        label = f"{job['test']}__{job['topology']}__seed{job['seed']}"
        command = [executables['xsim'],f"serial_{job['topology_id']}",'-runall',
                   '-sv_seed',str(job['seed']),'-testplusarg',f"UVM_TESTNAME={job['test']}",
                   '-testplusarg','UVM_NO_RELNOTES','-cov_db_name',label]
        if args.waves: command += ['-testplusarg','WAVES']
        commands.append(command)
        started = time.monotonic()
        code, text = execute(command,build,output/(label+'.log'))
        matches = re.findall(r'\[SERIAL_RESULT\]\s*(\{[^\r\n]+\})',text)
        metrics = json.loads(matches[-1]) if matches else {}
        errors = re.findall(r'^UVM_ERROR\s*:\s*(\d+)',text,re.M)
        fatals = re.findall(r'^UVM_FATAL\s*:\s*(\d+)',text,re.M)
        hdl_errors = bool(re.search(r'^(?:Error:|Fatal:|ERROR:)|RUNNER_TIMEOUT',text,re.M))
        passed = (code==0 and len(matches)==1 and errors==['0'] and fatals==['0'] and not hdl_errors
                  and metrics.get('pending')==0 and metrics.get('unexpected_errors')==0
                  and metrics.get('spi_verified',0)+metrics.get('i2c_verified',0)>0)
        acceptance_errors = []
        for key, expected in job.get('expect_equal',{}).items():
            if metrics.get(key)!=expected: acceptance_errors.append(f'{key}: expected {expected}, got {metrics.get(key)}')
        for key, minimum in job.get('expect_min',{}).items():
            if metrics.get(key,-1)<minimum: acceptance_errors.append(f'{key}: expected >= {minimum}, got {metrics.get(key)}')
        if job['topology']=='DUAL_SLAVE_UNIT' and metrics:
            frames=[]
            for match in re.finditer(r'\[WIRE_VERIFIED\] endpoint=(\d+) epoch=(\d+) config=(\d+) read=(\d+) start_ns=(\d+) end_ns=(\d+)',text):
                frames.append(tuple(map(int,match.groups())))
            overlaps=sum(a[1]==b[1] and a[4]<b[5] and b[4]<a[5]
                         for a in frames if a[0]==0 for b in frames if b[0]==1)
            if overlaps!=metrics['overlap_pairs']:
                acceptance_errors.append(f'Physical interval audit: {overlaps} pairs vs reported {metrics["overlap_pairs"]}')
        passed = passed and not acceptance_errors
        result = dict(job, passed=passed, returncode=code, seconds=round(time.monotonic()-started,3),
                      log=label+'.log', metrics=metrics, acceptance_errors=acceptance_errors)
        results.append(result)
        print(f"{'PASS' if passed else 'FAIL'} {label} {json.dumps(metrics,separators=(',',':'))}",flush=True)
        if not passed:
            if acceptance_errors: print('\n'.join(acceptance_errors),flush=True)
            diagnostics = list(dict.fromkeys(line for line in text.splitlines()
                                            if re.search(r'UVM_ERROR |UVM_FATAL |Error:|Fatal:|ERROR:',line)))
            print('\n'.join(diagnostics[:12])[:8000],flush=True)
    summary = {'created_at':dt.datetime.now().astimezone().isoformat(),'simulator':version.strip(),'uvm':'1.2',
               'source_sha256':source_hash,'source_files':hashes,'runner_sha256':sha(Path(__file__)),
               'filelist_sha256':filelist_hash,'test_matrix_sha256':sha(ROOT/'sim/tests.json'),
               'commands':commands,'passed':sum(j['passed'] for j in results),'total':len(results),'runs':results}
    (output/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
    print(f"Results: {output / 'summary.json'}",flush=True)
    return 0 if summary['passed']==summary['total'] else 1

if __name__=='__main__':
    raise SystemExit(main())
