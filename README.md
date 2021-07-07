# vault-docker-raft-cluster
Simple Docker desktop script for a 3-Node Raft Cluster of Hashicorp Vault 1.7 Enterprise for Linux / OSX. Due to license restrictions, the cluster will seal itself after 6 hours if no license file is applied. 

---
Disclaimer: DO NOT RUN IN PRODUCTION. This is for test/dev only.
---


----
Requirements
----
  - Docker Desktop
  - Vault Client Installed in $Path

----
Stand-up Cluster
----
sh run.sh

----
Teardown Cluster
----
sh cleanup.sh
