# Cloud & DevOps Automation Challenge – AKS Multi-Region Demo

This repository documents the implementation of the challenge as a walkthrough:
- what was built
- why each decision was made
- how to validate it live (terminal + Azure Portal)

## Agenda
1. Context & Requirements
2. Architecture (C4)
3. Live Demo (terminal + browser)
4. Observability
5. Backup & Recovery concept
6. DNS debugging runbook
7. Wrap-up (next steps)

---

## 1) Context & Requirements (Checklist)

| # | Requirement | Status | Evidence |
|---|------------|--------|----------|
| 1 | Deploy K8s cluster with at least 2 nodes | Done | `kubectl get nodes` |
| 2 | Run Hello World container (browser accessible) | Done | Ingress URL / IP |
| 3 | Round robin + autoscaling (CPU) | Done | HPA + multiple pods |
| 4 | Ingress controller with TLS termination | Done | HTTPS via ingress |
| 5 | Multi-region HA + traffic routing simulation | Done | Traffic Manager failover |
| 6 | Monitoring concept (endpoint availability) | Done | Container Insights + KQL |
| 7 | Backup/Recovery concept (zero downtime + MTTR<=4h) | Done (concept) | docs |
| 8 | DNS hiccups debugging on node + packet analysis | Done (runbook) | docs |

Detailed docs:
- Architecture: `docs/architecture.md`
- Multi-region HA: `docs/ha-multiregion.md`
- Monitoring: `docs/monitoring.md`
- Backup/Recovery: `docs/backup-recovery.md`
- DNS Debugging: `docs/dns-debugging.md`

---

## 2) Architecture (C4)
High-level request flow:
`Internet → Traffic Manager (DNS) → Ingress Public IP (AKS A/B) → ingress-nginx → hello Service → hello pods`

Diagram:
- Source: `docs/diagrams/c4-context.puml`
- Render: `docs/diagrams/c4-context.png`

See details: `docs/architecture.md`

---

## 3) Live Demo Script

### 3.1 Show both clusters are healthy (2 nodes each)
```bash
kubectl config get-contexts
kubectl config use-context devops-challenge-aks
kubectl get nodes -o wide

kubectl config use-context devops-challenge-aks-b
kubectl get nodes -o wide
```

### 3.2 Show hello app runs and pods are load-balanced
```bash
kubectl -n hello get pods -o wide
kubectl -n hello get svc,ingress
```

The app can be opened in a browser and refreshed:

- Region A ingress IP: 20.126.210.29
- Region B ingress IP: 20.54.97.214

### 3.3 Show HPA is configured
```bash
kubectl -n hello get hpa
kubectl -n hello describe hpa hello
```

The HPA scales replicas based on CPU; Service/ingress load-balance across endpoints.

### 3.4 Show TLS termination (self-signed is allowed)
The following URL can be opened:

https://20.126.210.29/

The browser will show a self-signed certificate warning (expected for this demo).
In production, cert-manager with a real domain should be used.

### 3.5 Multi-region failover via Traffic Manager
Traffic Manager FQDN:

```
tm-devops-ilar.trafficmanager.net
```

Validation:

```bash
nslookup tm-devops-ilar.trafficmanager.net
curl http://tm-devops-ilar.trafficmanager.net/healthz
```

Failover simulation (disable endpoint A, then resolve again):

```powershell
$RG="rg-devops-challenge-ilar"
$TM="tm-devops-ilar"

az network traffic-manager endpoint update -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --endpoint-status Disabled

ipconfig /flushdns
nslookup tm-devops-ilar.trafficmanager.net
curl http://tm-devops-ilar.trafficmanager.net/healthz
```

Rollback:

```powershell
az network traffic-manager endpoint update -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --endpoint-status Enabled
```

See details: `docs/ha-multiregion.md`

---

## 4) Observability
Monitoring MVP:

- Azure Monitor / Container Insights connected to Log Analytics
- Pods can be validated via KQL

Example KQL:

```kql
KubePodInventory
| where Namespace == "hello"
| project TimeGenerated, ClusterName, Name, PodStatus, PodIp, Node
| order by TimeGenerated desc
```

See details: `docs/monitoring.md`

---

## 5) Backup & Recovery concept
Two approaches have been documented:

- Near zero downtime (active-active concept)
- MTTR <= 4h (active-passive concept)

See details: `docs/backup-recovery.md`

---

## 6) DNS debugging runbook
If DNS hiccups happen in the cluster:

- Tests should start from pod tests → CoreDNS → node debug → tcpdump (UDP/53)
- Packets should be captured and analyzed to prove where the failure happens

See details: `docs/dns-debugging.md`

---

## 7) Wrap-up
The following steps would be taken next in a production setup:

- Real domain + cert-manager (ACME) for TLS
- GitOps (ArgoCD/Flux) to manage cluster add-ons and apps
- Alerts (availability / latency / saturation), dashboards, SLOs