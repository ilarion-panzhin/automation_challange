# Architecture (C4 + Components)

This document explains what was built, why, and how requests flow through the system.

## 1. Summary

The solution runs the same stateless "hello" application in two Azure Kubernetes Service (AKS) clusters located in two regions.  
Ingress is handled by `ingress-nginx` in each cluster.  
Global routing is done via Azure Traffic Manager (DNS-based failover).  
Monitoring is enabled via Azure Monitor / Container Insights (Log Analytics).

## 2. System goals

- Public access to the app via browser
- Round-robin distribution across pods (multiple replicas)
- Autoscaling based on CPU (HPA)
- TLS termination on the ingress layer
- Multi-region setup with a global routing/failover mechanism
- Basic monitoring and a runbook-style debugging approach

## 3. C4 Context (high level)

**Actors**
- User (browser/curl)

**Main systems**
- Azure Traffic Manager (global DNS routing)
- AKS Cluster A (Region A)
- AKS Cluster B (Region B)
- Azure Monitor / Log Analytics (observability)

> Diagram source: `docs/diagrams/c4-context.wsd`  
> Rendered image: `docs/diagrams/c4-context.png`

![context](c4-context.png)

## 4. Main components

### 4.1 Azure components

- **AKS Cluster A + AKS Cluster B**
  - Two independent Kubernetes clusters in different regions.
- **Azure Traffic Manager**
  - DNS-based routing.
  - Priority (active/passive) failover.
  - Health probe: HTTP `GET /healthz` (used to decide whether an endpoint is healthy).
- **Log Analytics Workspace (Azure Monitor / Container Insights)**
  - Collects cluster logs/metrics (MVP monitoring).

### 4.2 Kubernetes components (in each cluster)

- **ingress-nginx**
  - Public entry point inside the cluster.
  - Terminates TLS.
  - Routes HTTP paths to Kubernetes Services.
- **hello Deployment (nginx)**
  - Stateless web app.
  - Exposes:
    - `/` for the Hello page
    - `/healthz` returns 200 OK (probe endpoint)
- **hello Service (ClusterIP)**
  - Stable in-cluster load-balancing to hello pods.
- **HPA (HorizontalPodAutoscaler)**
  - Scales hello replicas based on CPU usage.

## 5. Request flow (end-to-end)

1. Client resolves the Traffic Manager name (DNS).
2. Traffic Manager returns **IP_A** if cluster A is healthy, otherwise **IP_B** (priority failover).
3. Client connects to the returned IP (HTTP/HTTPS).
4. The ingress public Load Balancer forwards traffic to `ingress-nginx`.
5. `ingress-nginx` terminates TLS (HTTPS) and routes to `hello` Service.
6. The Service load-balances across hello pods.
7. A hello pod returns the response.

## 6. Stateless vs stateful

- The application layer is **stateless** in this demo.
- No database is included, so multi-region failover is simplified (no data replication concerns).

## 7. Minimal verification

### 7.1 Show the workload is running

```bash
kubectl -n hello get pods -o wide
kubectl -n hello get svc,ingress
```

### 7.2 Show ingress is exposed publicly

```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
```

### 7.3 Show Traffic Manager resolves and routes

```bash
nslookup tm-devops-ilar.trafficmanager.net
curl http://tm-devops-ilar.trafficmanager.net/healthz
```