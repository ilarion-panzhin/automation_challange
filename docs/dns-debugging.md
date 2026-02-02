# DNS Debugging Runbook (Kubernetes)

## Symptom
Pods intermittently cannot resolve DNS names (e.g., `kubernetes.default`).

## What components matter
- Pods (clients making DNS queries)
- kube-dns Service (ClusterIP)
- CoreDNS pods (DNS server)
- Node networking (iptables/conntrack/MTU)
- Upstream DNS (Azure/VNet resolver) for external names

## Fast checks
```powershell
kubectl -n kube-system get pods | findstr coredns
kubectl -n kube-system logs deploy/coredns
kubectl -n kube-system get svc kube-dns
```

## In-pod verification
```powershell
kubectl -n hello exec -it deploy/hello -- sh -lc "nslookup kubernetes.default.svc.cluster.local"
kubectl -n hello exec -it deploy/hello -- sh -lc "cat /etc/resolv.conf"
```

## Deeper node-level analysis (netshoot)
```powershell
kubectl debug node/<node-name> -it --image=nicolaka/netshoot
tcpdump -ni any udp port 53
```

## Common root causes
- CoreDNS under-provisioned (CPU throttling / memory pressure)
- Node networking issues / conntrack saturation
- Upstream DNS problems
- CNI / iptables rules issues
- MTU / packet drops

## Fix approaches
- Increase CoreDNS resources; enable autoscaling
- Consider NodeLocal DNSCache for high scale
- Monitor CoreDNS metrics and node pressure
- Investigate CNI and node networking health