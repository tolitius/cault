#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "usage: $0 token"
    exit 1
fi

: ${VAULT_ADDR?"env variable VAULT_ADDR needs to be set"}
: ${VAULT_TOKEN?"env variable VAULT_TOKEN needs to be set"}

token=$1

echo $(curl -s \
            -H "X-Vault-Token: $VAULT_TOKEN" \
            -X POST \
            --data "{\"token\": \"$token\"}" \
            $VAULT_ADDR/v1/sys/wrapping/unwrap \
            | jq -r '.data, .errors')
