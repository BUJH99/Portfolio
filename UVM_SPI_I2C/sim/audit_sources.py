#!/usr/bin/env python3
"""Check compilation inputs, independent agent packages, and HDL naming conventions."""
import argparse
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path)
    args=parser.parse_args()
    errors=[]
    files=[line.strip() for line in (ROOT/'sim/files.f').read_text().splitlines()
           if line.strip() and not line.lstrip().startswith('#')]
    if len(files)!=len(set(files)): errors.append('Duplicate filelist entries')
    for filename in files:
        if not (ROOT/filename).is_file(): errors.append(f'Missing compilation input: {filename}')
        if '/boards/' in filename: errors.append('Board TOP wrappers must not share the simulation filelist')
    agent_packages={'serial_ctrl_uvm_pkg':'ctrl','spi_uvm_pkg':'spi','i2c_uvm_pkg':'i2c'}
    for package,folder in agent_packages.items():
        package_path=ROOT/'tb/pkg'/f'{package}.sv'
        if not package_path.is_file():
            errors.append(f'Missing agent package: {package}')
            continue
        text=package_path.read_text(encoding='utf-8')
        includes=re.findall(r'`include\s+"([^"]+)"',text)
        for filename in includes:
            if filename=='uvm_macros.svh': continue
            if not filename.startswith(f'tb/agents/{folder}/'):
                errors.append(f'Agent package crosses component boundary: {package} -> {filename}')
            path=ROOT/filename
            if not path.is_file(): errors.append(f'Missing agent include: {filename}')
            else: text+='\n'+path.read_text(encoding='utf-8')
        code=re.sub(r'/\*.*?\*/|//[^\n]*','',text,flags=re.S)
        dependencies=set(re.findall(r'\bimport\s+(\w+)::',code))
        for dependency in sorted(dependencies-{'uvm_pkg','serial_tb_types_pkg'}):
            errors.append(f'Agent package must be independent: {package} imports {dependency}')
    for path in (ROOT/'src').rglob('*.sv'):
        text=path.read_text(encoding='utf-8')
        if '[MODULE_INFO_START]' not in text: errors.append(f'Module documentation missing: {path.name}')
        if re.search(r'\bw\w+2\w+_\w+\b',text): errors.append(f'Instance-routed signal name: {path.name}')
        code=re.sub(r'/\*.*?\*/|//[^\n]*','',text,flags=re.S)
        if re.search(r'\bstate(?:_d)?\b',code): errors.append(f'Lowercase state register: {path.name}')
        if re.search(r'\b(class|mailbox|semaphore|fork)\b',code): errors.append(f'TB-only construct in RTL: {path.name}')
        for kind,name in re.findall(r'\b(module|package)\s+(\w+)',code):
            if name!=path.stem: errors.append(f'{kind}/filename mismatch: {path.name} -> {name}')
    for path in (ROOT/'tb').rglob('*.svh'):
        text=path.read_text()
        for name in re.findall(r'\bclass\s+(\w+)\s+extends',text):
            if not re.fullmatch(r'[A-Z]\w*(?:Item|Seq|Sequencer|Driver|Monitor|Agent|Env|Cfg|Predictor|Scoreboard|Coverage|Filter|Test)',name):
                errors.append(f'TB class naming: {name}')
        if re.search(r'\bvirtual\s+\w+_if\s+(?!vif_)\w+',text): errors.append(f'Virtual interface naming: {path.name}')
    result={'passed':not errors,'agent_packages':sorted(agent_packages),
            'compile_inputs':len(files),'errors':errors}
    if args.output:
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False,indent=2))
    return 0 if not errors else 1

if __name__=='__main__':
    raise SystemExit(main())
