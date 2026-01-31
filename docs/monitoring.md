# Monitoring (MVP) – Azure Monitor / Container Insights

## What is implemented
- Log Analytics workspace: `devops-challenge-law`
- Container Insights enabled
- Azure Monitor Agent (AMA) is running on both AKS clusters (`ama-logs-*` pods)

## Quick proof from cluster

```powershell
kubectl -n kube-system get pods | findstr ama
```

## KQL examples (Log Analytics → Logs)

List hello pods across clusters:

```kql
KubePodInventory
| where Namespace == "hello"
| project TimeGenerated, ClusterName, Name, PodStatus, PodIp, Computer
| order by TimeGenerated desc
```

Pod status summary:

```kql
KubePodInventory
| where Namespace == "hello"
| summarize Pods=count() by ClusterName, PodStatus
| order by ClusterName asc
```

Restarts overview:

```kql
KubePodInventory
| where Namespace == "hello"
| project TimeGenerated, ClusterName, Name, PodStatus, PodRestartCount, ContainerRestartCount, Computer
| order by TimeGenerated desc
```