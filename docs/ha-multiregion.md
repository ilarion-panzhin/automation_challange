# High Availability (Multi-Region) – AKS + Azure Traffic Manager

## Goal

A multi-region high availability setup for Kubernetes is provided, and global traffic routing is simulated using a cloud-native PaaS service (DNS-based routing + health probing + failover).

## Topology

- Region A (West Europe): AKS `devops-challenge-aks`  
  - ingress-nginx public IP: `20.126.210.29` 
- Region B (North Europe): AKS `devops-challenge-aks-b`  
  - ingress-nginx public IP: `20.54.97.214` 
- Global routing: Azure Traffic Manager profile: `tm-devops-ilar.trafficmanager.net` 
- Health probe: HTTP `GET /healthz` on port `80` 
- Routing method: **Priority** (Active/Passive)

## Why Azure Traffic Manager

- Cloud-native PaaS service for global routing (DNS-based).
- Built-in health probing and automatic failover.
- Simple, fast to demo, and sufficient for this challenge scenario.

> Note: Traffic Manager operates at the DNS layer. Failover speed depends on DNS caching/TTL and client resolver behavior.

## Preconditions

Before configuring Traffic Manager, both ingress endpoints must be reachable and return `200 OK` on `/healthz`:
- `http://20.126.210.29/healthz` 
- `http://20.54.97.214/healthz` 

## Configuration steps (what was done)

1. The Traffic Manager health probe was configured:
   - protocol: HTTP
   - port: 80
   - path: `/healthz`
2. Two endpoints were created:
   - `ep-aks-a` → target IP_A, priority 1 (primary)
   - `ep-aks-b` → target IP_B, priority 2 (secondary)
3. The following was validated:
   - both endpoints show as **Online** in Azure
   - Traffic Manager DNS resolves to IP_A when endpoint A is healthy

## Demo / Validation

### 1) Verify direct endpoints

```bash
curl http://20.126.210.29/healthz
curl http://20.54.97.214/healthz
```

Expected: both return 200 OK.

### 2) Verify Traffic Manager resolves to primary (A)

```bash
nslookup tm-devops-ilar.trafficmanager.net
curl http://tm-devops-ilar.trafficmanager.net/healthz
```

Expected:
- DNS resolves to IP_A (most of the time, depending on caching).
- `/healthz` via the TM name returns 200 OK.

### 3) Failover simulation

Endpoint `ep-aks-a` is disabled, local DNS cache is flushed, resolution is performed again, and confirmation is made that IP_B is returned.

### 4) Rollback

Endpoint `ep-aks-a` is re-enabled.

## Commands (copy/paste)

```powershell
$RG="rg-devops-challenge-ilar"
$TM="tm-devops-ilar"
$IP_A="20.126.210.29"
$IP_B="20.54.97.214"

# Configure health probe
az network traffic-manager profile update -g $RG -n $TM `
  --protocol HTTP --port 80 --path "/healthz"

# Create endpoints
az network traffic-manager endpoint create -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --target $IP_A --priority 1

az network traffic-manager endpoint create -g $RG --profile-name $TM `
  -n ep-aks-b --type externalEndpoints --target $IP_B --priority 2

# List endpoints (status / priority)
az network traffic-manager endpoint list -g $RG --profile-name $TM -o table

# Failover demo: disable primary endpoint A
az network traffic-manager endpoint update -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --endpoint-status Disabled

ipconfig /flushdns
nslookup tm-devops-ilar.trafficmanager.net

# Rollback: enable endpoint A again
az network traffic-manager endpoint update -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --endpoint-status Enabled
```

## Troubleshooting notes

**If nslookup still shows IP_A after disabling:**
- DNS cache expiry must be waited for (local cache and upstream resolvers)
- Local DNS cache should be flushed again (`ipconfig /flushdns`)
- Endpoint status should be verified in Azure Portal (endpoint A should show as Disabled/Degraded)

**If /healthz fails for a region:**
- Ingress service external IP should be checked in that cluster
- Ingress routes to `/healthz` should be confirmed to reach the app
- App response of 200 on `/healthz` should be confirmed