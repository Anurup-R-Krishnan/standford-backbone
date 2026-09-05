#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECTPATH="${REPO_DIR}/configuration/atpg"

mkdir -p "${PROJECTPATH}/work"
cd "${PROJECTPATH}"

PYTHON="${PYTHON:-python3}"

"${PYTHON}" ./atpg_internet2.py -p 10 -f i2-10.sqlite > "${PROJECTPATH}/work/i2-10.txt"
"${PYTHON}" ./atpg_internet2.py -p 40 -f i2-40.sqlite > "${PROJECTPATH}/work/i2-40.txt"
"${PYTHON}" ./atpg_internet2.py -p 70 -f i2-70.sqlite > "${PROJECTPATH}/work/i2-70.txt"
"${PYTHON}" ./atpg_internet2.py -p 100 -f i2-100.sqlite > "${PROJECTPATH}/work/i2-100.txt"
"${PYTHON}" ./atpg_internet2.py -p 100 -e -f i2-100-edge.sqlite > "${PROJECTPATH}/work/i2-100-edge.txt"
