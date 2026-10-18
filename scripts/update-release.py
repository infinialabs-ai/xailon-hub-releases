#!/usr/bin/env python3
"""Verify a complete artifact set, then update portal download metadata."""
from pathlib import Path
import argparse,json,hashlib,subprocess
p=argparse.ArgumentParser();p.add_argument('artifacts',type=Path);a=p.parse_args()
root=Path(__file__).resolve().parents[1];release=json.loads((root/'release.json').read_text())
for asset in release['desktop']:
 path=a.artifacts/asset['filename']
 if not path.is_file() or path.stat().st_size<1000000:raise SystemExit('Missing/incomplete artifact: '+str(path))
 digest=hashlib.sha256()
 with path.open('rb') as f:
  for block in iter(lambda:f.read(1024*1024),b''):digest.update(block)
 asset.update(available=True,size_bytes=path.stat().st_size,size_label=f'{path.stat().st_size/1024/1024:.1f} MB',sha256=digest.hexdigest())
(root/'release.json').write_text(json.dumps(release,indent=2)+'\n')
subprocess.run(['python3',str(root/'scripts/build-site.py')],check=True)
