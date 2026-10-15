#!/usr/bin/env python3
"""Run a checked-in HDL test matrix with Vivado XSim and retain auditable logs.

Paths in a matrix are relative to its parent directory. Build products are kept
outside result folders; each invocation creates fresh results and never reuses a
compiled snapshot. A successful tool exit alone does not count as a test pass.
"""
from __future__ import annotations
import argparse, datetime as dt, hashlib, json, os, re, shutil, subprocess, sys, time
from pathlib import Path

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def execute(command, cwd, logfile, timeout=300):
    invocation=command
    if os.name=='nt' and command[0].lower().endswith('.bat'):
        invocation=' '.join('"'+s+'"' if '=' in s and not any(c in s for c in ' \t"')
                            else subprocess.list2cmdline([s]) for s in command)
    started=time.monotonic()
    try:
        p=subprocess.run(invocation,cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
                         encoding='utf-8',errors='replace',timeout=timeout)
        rc,output=p.returncode,p.stdout
    except subprocess.TimeoutExpired as e:
        rc=124; output=e.stdout or b''
        if isinstance(output,bytes): output=output.decode('utf-8','replace')
        output+='\nRUNNER_TIMEOUT\n'
    logfile.write_text(output,encoding='utf-8')
    return rc,output,round(time.monotonic()-started,3)

def main():
    if hasattr(sys.stdout,'reconfigure'): sys.stdout.reconfigure(encoding='utf-8',errors='replace')
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('matrix',type=Path)
    ap.add_argument('--job',action='append')
    ap.add_argument('--output',type=Path)
    ap.add_argument('--vivado-bin',default=os.environ.get('VIVADO_BIN'))
    a=ap.parse_args(); matrix=a.matrix.resolve(); root=matrix.parent
    config=json.loads(matrix.read_text(encoding='utf-8'))
    jobs=[j for j in config['jobs'] if not a.job or j['name'] in a.job]
    if not jobs or (a.job and set(a.job)-{j['name'] for j in jobs}): ap.error('Unknown or empty job selection')
    suffix='.bat' if os.name=='nt' else ''
    commands={n:str(Path(a.vivado_bin)/(n+suffix)) if a.vivado_bin else shutil.which(n+suffix) for n in ('xvlog','xelab','xsim')}
    if not all(p and Path(p).is_file() for p in commands.values()): ap.error('Set VIVADO_BIN, --vivado-bin, or add Vivado/bin to PATH')
    stamp=dt.datetime.now().strftime('%Y-%m-%d_%H%M%S_%f')
    out=(a.output or root/'results'/stamp).resolve()
    if out.exists() and any(out.iterdir()): ap.error('Use a new empty output directory to preserve earlier results')
    out.mkdir(parents=True,exist_ok=True)
    build=root/'.sim_build'/stamp; build.mkdir(parents=True)
    rc,version,_=execute([commands['xvlog'],'-version'],build,out/'tool_version.log')
    if rc: raise RuntimeError(version)
    summary={'created_at':dt.datetime.now().astimezone().isoformat(),'tool':version.strip(),
             'matrix_sha256':digest(matrix),'runner_sha256':digest(Path(__file__)),
             'source_files':{},'commands':[],'runs':[]}
    for setname in dict.fromkeys(j['fileset'] for j in jobs):
        spec=config['filesets'][setname]; work=build/setname; work.mkdir()
        sources=[]
        for pattern in spec['sources']:
            found=sorted(root.glob(pattern))
            if not found: raise FileNotFoundError(pattern)
            sources.extend(str(p.resolve()) for p in found if str(p.resolve()) not in sources)
        for p in sources: summary['source_files'][Path(p).relative_to(root).as_posix()]=digest(Path(p))
        if spec.get('vendor_glbl'):
            glbl=Path(commands['xvlog']).resolve().parent.parent/'data/verilog/src/glbl.v'
            if not glbl.is_file(): raise FileNotFoundError(glbl)
            sources.append(str(glbl)); summary['source_files']['@vivado/glbl.v']=digest(glbl)
        for pattern in spec.get('audit',[]):
            for p in root.glob(pattern):
                if p.is_file(): summary['source_files'][p.relative_to(root).as_posix()]=digest(p)
        includes=[root/p for p in spec.get('include',[])]
        for folder in includes:
            for p in folder.rglob('*.svh'): summary['source_files'][p.relative_to(root).as_posix()]=digest(p)
            for p in folder.rglob('*.vh'): summary['source_files'][p.relative_to(root).as_posix()]=digest(p)
        for item in spec.get('inputs',[]):
            src=root/item['source']; dst=work/item['destination']; dst.parent.mkdir(parents=True,exist_ok=True)
            if src.is_dir(): shutil.copytree(src,dst,dirs_exist_ok=True)
            else: shutil.copy2(src,dst)
        lib=['-L','uvm'] if spec.get('uvm') else []
        for name in spec.get('libraries',[]): lib+=['-L',name]
        compile_cmd=[commands['xvlog'],'--sv',*lib]
        for p in includes: compile_cmd+=['-i',str(p.resolve())]
        for d in spec.get('defines',[]): compile_cmd+=['-d',d]
        filelist=work/'sources.f'
        filelist.write_text('\n'.join('"'+p.replace('\\','/')+'"' for p in sources)+'\n',encoding='utf-8')
        compile_cmd+=['-f',str(filelist)]
        summary['commands'].append(compile_cmd)
        rc,txt,_=execute(compile_cmd,work,out/(setname+'_compile.log'),600)
        compiled=rc==0 and not re.search(r'^ERROR:',txt,re.M)
        if compiled:
            elab=[commands['xelab'],spec['top'],*spec.get('extra_tops',[]),*lib,'-s',setname,'-debug','typical','-timescale','1ns/1ps',*spec.get('elab_args',[])]
            summary['commands'].append(elab)
            rc,txt,_=execute(elab,work,out/(setname+'_elaborate.log'),600)
            compiled=rc==0 and not re.search(r'^ERROR:',txt,re.M)
        if not compiled: print(txt[-6000:],flush=True)
        for j in [j for j in jobs if j['fileset']==setname]:
            run=[commands['xsim'],setname,'-runall','-sv_seed',str(j.get('seed',1))]
            for arg in j.get('plusargs',[]): run+=['-testplusarg',arg]
            if compiled:
                summary['commands'].append(run)
                rc,txt,seconds=execute(run,work,out/(j['name']+'.log'),j.get('timeout',600))
            else: rc,seconds=2,0
            required=j.get('require',[])
            missing=[p for p in required if not re.search(p,txt,re.M)]
            bad=bool(re.search(r'^(?:ERROR:|Error:|Fatal:|FATAL:)|RUNNER_TIMEOUT|\[FAIL\]',txt,re.M))
            if spec.get('uvm'):
                bad|=re.findall(r'^UVM_ERROR\s*:\s*(\d+)',txt,re.M)!=['0']
                bad|=re.findall(r'^UVM_FATAL\s*:\s*(\d+)',txt,re.M)!=['0']
            passed=compiled and rc==0 and bool(required) and not missing and not bad
            result=dict(j,passed=passed,returncode=rc,seconds=seconds,missing=missing,log=j['name']+'.log')
            summary['runs'].append(result)
            for pattern in spec.get('artifacts',[]):
                for p in work.glob(pattern):
                    if p.is_file():
                        dst=out/(j['name']+'_artifacts')/p.relative_to(work)
                        dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(p,dst)
            print(('PASS' if passed else 'FAIL')+' '+j['name'],flush=True)
            if not passed: print(txt[-6000:],flush=True)
    summary['total']=len(summary['runs']); summary['passed']=sum(r['passed'] for r in summary['runs'])
    summary['source_sha256']=hashlib.sha256(json.dumps(summary['source_files'],sort_keys=True).encode()).hexdigest()
    (out/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
    print(f"{summary['passed']}/{summary['total']} passed; {out / 'summary.json'}",flush=True)
    return 0 if summary['passed']==summary['total'] else 1

if __name__=='__main__': raise SystemExit(main())
