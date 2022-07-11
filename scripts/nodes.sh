#!/bin/bash
#
# Setup for Node servers

set -euxo pipefail

FIRST_RUN_WORKER=$HOME/first-run-worker.txt

if [[ -f "$FIRST_RUN_WORKER" ]]; then
    echo "Worker node alredy bootstraped"
    exit 0
fi

/bin/bash $CONFIGS_PATH/join.sh -v

touch $FIRST_RUN_WORKER
