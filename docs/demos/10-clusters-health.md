# Demo: Cluster health (AKS-A + AKS-B)

Goal:
- Prove both clusters exist and have >=2 nodes Ready.

## Commands

```bash
kubectl config get-contexts
kubectl config use-context devops-challenge-aks
kubectl get nodes -o wide

kubectl config use-context devops-challenge-aks-b
kubectl get nodes -o wide
```

Expected:

- Each cluster shows at least 2 nodes in Ready state.

Configured in Terraform AKS node pool configuration (node_count / default_node_pool).