#!/usr/bin/env python3
# Copyright 2026 LoveSy
# SPDX-License-Identifier: Apache-2.0
"""Restore exact oversized upstream data files, without replacing different files."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tarfile
import tempfile
import urllib.request

def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,required=True)
    parser.add_argument('--verify-only',action='store_true')
    parser.add_argument('--cache',type=Path,help='Directory containing downloaded archives')
    args=parser.parse_args();root=args.root.resolve(strict=True)
    manifest=Path(__file__).resolve().parent.parent/'large-assets.json'
    for spec in json.loads(manifest.read_text()):
        project=(root/spec['project']).resolve(strict=True)
        project.relative_to(root)
        missing=[]
        for member in spec['members']:
            file=project/member['path'];file.resolve().relative_to(project)
            if file.exists():
                if file.is_symlink() or sha(file)!=member['sha256']:
                    raise SystemExit(f'Refusing to replace different asset: {file}')
            else:missing.append(member)
        if not missing:
            print('Verified',spec['project']);continue
        if args.verify_only:raise SystemExit(f'Missing assets in {project}')
        with tempfile.TemporaryDirectory(prefix='.source-assets-',dir=project) as temp:
            temp=Path(temp)
            archive=(args.cache/spec['archive']) if args.cache else temp/spec['archive']
            if not archive.exists():
                if args.cache:raise SystemExit(f'Missing cached archive: {archive}')
                with urllib.request.urlopen(spec['url'],timeout=60) as src,archive.open('wb') as dst:
                    shutil.copyfileobj(src,dst,4*1024*1024)
            if sha(archive)!=spec['sha256']:raise SystemExit(f'Archive checksum mismatch: {archive}')
            with tarfile.open(archive,'r:gz') as tar:
                for i,member in enumerate(missing):
                    info=tar.getmember(member['path'])
                    if not info.isfile():raise SystemExit('Expected regular asset')
                    staged=temp/str(i)
                    with tar.extractfile(info) as src,staged.open('wb') as dst:
                        shutil.copyfileobj(src,dst,4*1024*1024)
                    if sha(staged)!=member['sha256']:raise SystemExit('Asset checksum mismatch')
                    dest=project/member['path'];dest.parent.mkdir(parents=True,exist_ok=True)
                    if dest.exists():raise SystemExit(f'Destination appeared concurrently: {dest}')
                    staged.chmod(0o644);staged.rename(dest)
            print('Restored and verified',spec['project'])

if __name__=='__main__':main()
