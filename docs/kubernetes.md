# Kubernetes deployment (AKS) runbook

This project deploys a simple "hello" NGINX workload to AKS and exposes it via NGINX Ingress Controller.
I deployed it to two AKS clusters (Region A and Region B) as part of the HA demo setup.

---

## What is deployed

### Cluster add-on
- NGINX Ingress Controller installed via Helm in namespace `ingress-nginx`
- Exposed externally via a Kubernetes Service of type `LoadBalancer` (Azure creates a Public IP + LB)

### Application
Namespace `hello` with:
- `ConfigMap` for NGINX config and HTML content
- `Deployment` for `nginx:1.27`
- `Service` (ClusterIP)
- `Ingress` that routes `/` to the service
- `HorizontalPodAutoscaler` (HPA)

Repo structure:
- `k8s/hello/00-namespace.yaml`
- `k8s/hello/01-configmap.yaml`
- `k8s/hello/02-deployment.yaml`
- `k8s/hello/03-service.yaml`
- `k8s/hello/04-ingress.yaml`
- `k8s/hello/05-hpa.yaml`

---

## Prerequisites

### Tools
- Azure CLI
- kubectl
- Helm

Install on Windows (if missing):
```powershell
winget install -e --id Kubernetes.kubectl
winget install -e --id Helm.Helm
```

Then reopen the terminal and check:
```bash
kubectl version --client
helm version
```

---

## Connect to AKS

### For Region A cluster:
```bash
az aks get-credentials -g rg-devops-challenge-ilar -n devops-challenge-aks --overwrite-existing
kubectl config current-context
kubectl get nodes -o wide
```

### For Region B cluster:
```bash
az aks get-credentials -g rg-devops-challenge-ilar -n devops-challenge-aks-b --overwrite-existing
kubectl config current-context
kubectl get nodes -o wide
```

---

## Install ingress-nginx (per cluster)

### Add/update repo (once per machine):
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

### Install controller (per cluster):
```bash
kubectl create ns ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --set controller.service.type=LoadBalancer
```

### Wait for external IP:
```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller -w
```

### Show details:
```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
kubectl -n ingress-nginx get deploy,po,svc -o wide
```

**Important mental model:**
- The Ingress Controller is a Deployment (controller pods)
- The external entrypoint is the Service `ingress-nginx-controller` with type=LoadBalancer

---

## Deploy the hello app (per cluster)

### Apply everything:
```bash
kubectl apply -f k8s/hello/
```

### Expected resources created:
- `namespace/hello`
- `configmap/hello-nginx` (or `hello-html` depending on version)
- `deployment.apps/hello`
- `service/hello`
- `ingress.networking.k8s.io/hello`
- `horizontalpodautoscaler/...`

---

## Validate that everything is OK

### 1) Workload status
```bash
kubectl -n hello get pods -o wide
kubectl -n hello describe deploy hello
kubectl -n hello get events --sort-by=.lastTimestamp
```

### 2) Service and endpoints
```bash
kubectl -n hello get svc
kubectl -n hello get endpoints hello -o wide
```

### 3) Ingress
```bash
kubectl -n hello get ingress -o wide
kubectl -n hello describe ingress hello
```

### 4) Ingress controller health
```bash
kubectl -n ingress-nginx get pods -o wide
kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=200
```

### 5) Test via browser or curl
Use the external IP of `ingress-nginx-controller`:
```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
```

Then open:
```
http://<EXTERNAL-IP>/
```

The HTML prints pod identity and request details (helpful for demo and debugging).

---

## Health checks

### What was configured
- `/healthz` endpoint inside NGINX
- `readinessProbe` hits `/healthz` (pod receives traffic only when ready)
- `livenessProbe` hits `/healthz` (pod is restarted if it becomes unhealthy)

This is implemented in the Deployment manifest.

### How to test health checks quickly

**Inside the cluster:**
```bash
kubectl -n hello exec -it deploy/hello -- sh -lc "wget -qO- http://127.0.0.1/healthz; echo"
```

**From your machine through ingress:**
```bash
curl -i http://<EXTERNAL-IP>/healthz
```

**Note:** `startupProbe` not added because NGINX starts fast and readiness/liveness were enough for MVP. If the app had slow initialization (DB migrations, caches warmup), add `startupProbe` to avoid premature liveness kills.

---

## Logs you should know for troubleshooting

### App logs (NGINX container)
```bash
kubectl -n hello logs deploy/hello --tail=200
kubectl -n hello logs deploy/hello -c nginx --tail=200
```

### Ingress controller logs
```bash
kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=200
```

### Describe to spot misconfig fast
```bash
kubectl -n hello describe pod <pod-name>
kubectl -n hello describe ingress hello
kubectl -n ingress-nginx describe svc ingress-nginx-controller
```

---

## Monitoring (MVP) via Azure Monitor / Log Analytics

### 1) Confirm Azure Monitor Agent is running in both clusters
```bash
kubectl -n kube-system get pods | findstr ama
```
Expected: `ama-logs-*` pods Running.

### 2) Useful KQL queries (Log Analytics workspace)

**Pods in namespace hello (both clusters):**
```kql
KubePodInventory
| where Namespace == "hello"
| project TimeGenerated, ClusterName, Name, PodStatus, PodIp, Computer
| order by TimeGenerated desc
```

**Pod status summary:**
```kql
KubePodInventory
| where Namespace == "hello"
| summarize Pods=count() by ClusterName, PodStatus
| order by ClusterName asc
```

**Restarts:**
```kql
KubePodInventory
| where Namespace == "hello"
| project TimeGenerated, ClusterName, Name, PodStatus, PodRestartCount, ContainerRestartCount, Computer
| order by TimeGenerated desc
```

**Clusters last seen:**
```kql
KubePodInventory
| summarize LastSeen=max(TimeGenerated) by ClusterName
| order by LastSeen desc
```

**Note:** Telemetry ingestion can lag a few minutes.

---

## Things to consider if this project continues

### DNS and host-based ingress
Right now we access via IP. For a normal URL you would:
- Create a DNS record (A or CNAME) pointing to the ingress public IP
- Set `spec.rules.host` in Ingress
- Optionally use ExternalDNS to automate DNS record management

### TLS automation
I referenced a TLS secret in Ingress in one version.
For production-style TLS:
- Install cert-manager
- Use Let's Encrypt (ClusterIssuer)
- Automatically issue/renew certs instead of manual secrets

### Reliability and scaling
- Tune HPA thresholds and verify metrics pipeline (metrics-server / Azure Monitor metrics)
- Add a PodDisruptionBudget (PDB)
- Consider multi-replica ingress controller, node pool sizing, and zone redundancy (if required)

### Security hardening
- Add NetworkPolicies (namespace isolation)
- Use workload identity or managed identity patterns (avoid long-lived secrets)
- Add Pod Security (runAsNonRoot, readOnlyRootFilesystem where possible)

### Packaging and delivery
- Keep ingress-nginx as Helm (standard)
- Optionally package hello as Helm chart or Kustomize overlays for envs
- Add GitOps (Argo CD / Flux) for continuous deployment

### Observability improvements
- Dashboards and alerts in Azure Monitor (pod restarts, 5xx from ingress, latency)
- Consider Prometheus/Grafana if the stack grows beyond MVP

---