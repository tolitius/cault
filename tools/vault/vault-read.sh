#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "usage: $0 [vault path]"
    exit 1
fi

: ${VAULT_ADDR?"env variable VAULT_ADDR needs to be set"}
: ${VAULT_TOKEN?"env variable VAULT_TOKEN needs to be set"}

path=$1

echo $(curl -s \
            -H "X-Vault-Token: $VAULT_TOKEN" \
            -H "Content-Type: application/json" \
            -X GET \
            $VAULT_ADDR/v1$path \
            | jq -r .data)
