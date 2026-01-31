# High Availability (Multi-Region) – AKS + Azure Traffic Manager

## Goal
Provide a multi-region high availability setup for Kubernetes and simulate global traffic routing using a cloud-native PaaS service.

## Topology
- Region A (West Europe): AKS `devops-challenge-aks` + ingress-nginx LB public IP: **20.126.210.29**
- Region B (North Europe): AKS `devops-challenge-aks-b` + ingress-nginx LB public IP: **20.54.97.214**
- Global routing: Azure Traffic Manager profile **tm-devops-ilar.trafficmanager.net**
- Health probe: HTTP `GET /healthz` on port 80
- Routing method: **Priority** (Active/Passive)

## Why Traffic Manager
- DNS-based global routing (PaaS)
- Built-in health probing and endpoint failover
- Simple and sufficient for the challenge scenario

## Demo / Validation
1. Verify both regions return 200:
   - http://20.126.210.29/healthz
   - http://20.54.97.214/healthz

2. Verify Traffic Manager resolves to primary (A):
   ```
   nslookup tm-devops-ilar.trafficmanager.net
   ```

3. Failover simulation:
   - Disable endpoint `ep-aks-a`
   - Flush DNS cache and resolve again
   - Confirm it returns IP_B

## Commands (copy/paste)

```powershell
$RG="rg-devops-challenge-ilar"
$TM="tm-devops-ilar"
$IP_A="20.126.210.29"
$IP_B="20.54.97.214"

az network traffic-manager profile update -g $RG -n $TM --protocol HTTP --port 80 --path "/healthz"

az network traffic-manager endpoint create -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --target $IP_A --priority 1

az network traffic-manager endpoint create -g $RG --profile-name $TM `
  -n ep-aks-b --type externalEndpoints --target $IP_B --priority 2

az network traffic-manager endpoint list -g $RG --profile-name $TM -o table

# Failover demo:
az network traffic-manager endpoint update -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --endpoint-status Disabled

ipconfig /flushdns
nslookup tm-devops-ilar.trafficmanager.net

# Rollback:
az network traffic-manager endpoint update -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --endpoint-status Enabled
```