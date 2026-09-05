#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECTPATH="${REPO_DIR}/configuration/atpg"

mkdir -p "${PROJECTPATH}/work"
cd "${PROJECTPATH}"

PYTHON="${PYTHON:-python3}"

"${PYTHON}" ./atpg_stanford.py -p 10 -f stanford-10.sqlite > "${PROJECTPATH}/work/stanford-10.txt"
"${PYTHON}" ./atpg_stanford.py -p 40 -f stanford-40.sqlite > "${PROJECTPATH}/work/stanford-40.txt"
"${PYTHON}" ./atpg_stanford.py -p 70 -f stanford-70.sqlite > "${PROJECTPATH}/work/stanford-70.txt"
"${PYTHON}" ./atpg_stanford.py -p 100 -f stanford-100.sqlite > "${PROJECTPATH}/work/stanford-100.txt"
"${PYTHON}" ./atpg_stanford.py -p 100 -e -f stanford-100-edge.sqlite > "${PROJECTPATH}/work/stanford-100-edge.txt"
