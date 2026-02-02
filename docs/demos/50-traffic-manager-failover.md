# Demo: Multi-region failover (Azure Traffic Manager)

Goal:
- Prove global DNS routing works.
- Simulate failover by disabling endpoint A.

Facts:
- IP_A: 20.126.210.29
- IP_B: 20.54.97.214
- Fully Qualified Domain Name (FQDN): tm-devops-ilar.trafficmanager.net
- Probe: HTTP /healthz port 80
- Routing: Priority (Active/Passive)

## Validate endpoints directly
```bash
curl http://20.126.210.29/healthz
curl http://20.54.97.214/healthz
```

## Validate Traffic Manager resolution
```bash
nslookup tm-devops-ilar.trafficmanager.net
curl http://tm-devops-ilar.trafficmanager.net/healthz
```

## Failover (disable endpoint A)
```powershell
$RG="rg-devops-challenge-ilar"
$TM="tm-devops-ilar"

az network traffic-manager endpoint update -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --endpoint-status Disabled

ipconfig /flushdns
nslookup tm-devops-ilar.trafficmanager.net
curl http://tm-devops-ilar.trafficmanager.net/healthz
```

Expected:

- DNS resolves to IP_B after failover.

- /healthz still returns 200.

## Rollback
```powershell
az network traffic-manager endpoint update -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --endpoint-status Enabled
```

If it does not switch immediately:

DNS caching/TTL is the reason; show endpoint status in Portal.