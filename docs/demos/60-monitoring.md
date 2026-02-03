# Demo: Monitoring (Azure Monitor / Container Insights)

Goal:
- Show monitoring is enabled.
- Prove logs/metadata exist via a simple KQL query.

Portal:
- Log Analytics Workspace -> Logs

Example KQL:
```kusto
KubePodInventory
| where Namespace == "hello"
| project TimeGenerated, ClusterName, Name, PodStatus, PodIp, Node
| order by TimeGenerated desc
```

Explain:

Container Insights provides baseline observability (logs/metrics).

Next step would be alerts + dashboards + SLOs.