# Demo: App is reachable + round robin across pods

Goal:
- Prove app is deployed.
- Prove multiple replicas serve traffic (refresh shows different pod).

## AKS-A

```bash
kubectl config use-context devops-challenge-aks
kubectl -n hello get pods -o wide
kubectl -n hello get svc,ingress
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
```

Open in browser:

https://20.126.210.29/

Refresh page a few times:

"Served by pod: ..." should change (round robin).

---

## AKS-B

```bash
kubectl config use-context devops-challenge-aks-b
kubectl -n hello get pods -o wide
kubectl -n hello get svc,ingress
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
```

Open:

https://20.54.97.214/

---

Service load-balances to pod endpoints (kube-proxy).

Ingress-nginx is reverse proxy in front.