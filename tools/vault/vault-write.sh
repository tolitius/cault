#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "usage: $0 [vault path] [creds file path]"
    exit 1
fi

: ${VAULT_ADDR?"env variable VAULT_ADDR needs to be set"}
: ${VAULT_TOKEN?"env variable VAULT_TOKEN needs to be set"}

path=$1
creds=$2

echo $(curl -H "X-Vault-Token: $VAULT_TOKEN" \
            -H "Content-Type: application/json" \
            -X POST \
            -sd @$creds \
            $VAULT_ADDR/v1$path)
