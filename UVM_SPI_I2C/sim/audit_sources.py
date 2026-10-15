#!/usr/bin/env python3
"""Audit immutable evidence, compilation inputs, and the applied HDL naming conventions."""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-root',type=Path,help='Optional original managed Project directory')
    parser.add_argument('--output',type=Path)
    args=parser.parse_args()
    errors=[]
    data=json.loads((ROOT/'docs/source_provenance.json').read_text(encoding='utf-8'))
    preserved=[]
    for entry in data['preserved_artifacts']:
        path=ROOT/entry['path']
        ok=path.is_file() and sha(path)==entry['sha256']
        preserved.append(dict(path=entry['path'],unchanged=ok,sha256=entry['sha256']))
        if not ok: errors.append(f'Historical artifact changed or missing: {entry["path"]}')
    originals=[]
    if args.source_root:
        for entry in data['inputs']:
            path=args.source_root/entry['source']
            ok=path.is_file() and sha(path)==entry['sha256']
            originals.append(dict(path=entry['source'],unchanged=ok))
            if not ok: errors.append(f'Refactoring input changed or missing: {entry["source"]}')
    files=(ROOT/'sim/files.f').read_text().splitlines()
    if len(files)!=len(set(files)): errors.append('Duplicate filelist entries')
    for filename in files:
        if not (ROOT/filename).is_file(): errors.append(f'Missing compilation input: {filename}')
        if '/boards/' in filename: errors.append('Board TOP wrappers must not share the simulation filelist')
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
    result={'passed':not errors,'preserved_artifacts':preserved,'original_inputs':originals,
            'compile_inputs':len(files),'errors':errors}
    if args.output:
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'passed':result['passed'],'preserved_artifacts':len(preserved),'original_inputs':len(originals),
                      'compile_inputs':len(files),'errors':errors},ensure_ascii=False,indent=2))
    return 0 if not errors else 1

if __name__=='__main__':
    raise SystemExit(main())
