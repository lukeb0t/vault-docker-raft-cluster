#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

VAULT_IMAGE='hashicorp/vault-enterprise:1.7.1_ent'
export VAULT_CONTAINERS=('vault-0' 'vault-1' 'vault-2')
export VAULT_ADDR=http://localhost:8203

#cleanup script to ensure no conflicts with previous instances
${DIR?}/cleanup.sh &> /dev/null

set -e

docker network create --driver bridge vault &> /dev/null

port=8203
echo "starting vault port address mapping is ::8200 >> $port
"

for container in ${VAULT_CONTAINERS[@]}
do
    echo "Creating ${container?}...
    "
    echo "${container?} vault mapped port is localhost:$port
    "
    docker run \
      --name=${container?} \
      --hostname=${container?} \
      --network=vault \
      -p ${port?}:8200 \
      -e VAULT_ADDR="http://localhost:8200" \
      -e VAULT_CLUSTER_ADDR="http://${container?}:8201" \
      -e VAULT_API_ADDR="http://${container?}:8200" \
      -e VAULT_RAFT_NODE_ID="${container?}" \
      -v ${DIR?}:/vault/config \
      -v ${container?}:/vault/file:z \
      --privileged \
      --detach \
      ${VAULT_IMAGE?} vault server -config=/vault/config/config.hcl &> /dev/null 

     port=$((port+1))
done

echo 'initilizing cluster + exporting seal keys and tokens...
'
# -n = number of key shares. 
# -t threshold for unseal.
initRaw=$(docker exec -ti ${VAULT_CONTAINERS[0]?} vault operator init -format=json -n 1 -t 1)
unseal=$(echo ${initRaw?} | jq -r '.unseal_keys_b64[0]')
rootToken=$(echo ${initRaw?} | jq -r '.root_token')

echo "unsealing ${VAULT_CONTAINERS[0]?}..."
docker exec -ti ${VAULT_CONTAINERS[0]?} vault operator unseal ${unseal?} &> /dev/null

echo 'Waiting cluster initialization and unseal operation...
'
sleep 10

for container in "${VAULT_CONTAINERS[@]}"
do
    if [[ "${container?}" == "${VAULT_CONTAINERS[0]?}" ]]
    then
        continue
    fi
    echo "joining ${container?} to raft cluster...
    "
    docker exec -ti ${container?} vault operator raft join http://${VAULT_CONTAINERS[0]?}:8200 &> /dev/null

    echo "unsealing ${container?}
    "
    sleep 2
    docker exec -ti ${container?} vault operator unseal ${unseal?} &> /dev/null

done

echo "Vault Raft Cluster is initialized, unsealed and Raft cluster is ready!"
echo "In case you need them: "
echo "Root Token: ${rootToken?}"
echo "Unseal Key: ${unseal?}
"

echo "Attempting login...
"
vault login ${rootToken?}

echo "Displaying Raft Peers...
"
vault operator raft list-peers