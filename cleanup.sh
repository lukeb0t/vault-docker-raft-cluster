#!/bin/bash

VAULT_CONTAINERS=('vault-0' 'vault-1' 'vault-2')

for container in ${VAULT_CONTAINERS[@]}
do
    docker rm ${container?} --force
    docker volume rm ${container?}
done

docker network rm vault
