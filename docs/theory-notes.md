# Theory Notes for the Challenge

This file contains short, interview-ready theory notes that cover the key concepts behind the challenge implementation.

## 1) Round robin load balancing and alternatives

### What "round robin" means
Round robin is a simple load balancing strategy where incoming requests are distributed across multiple backends in a rotating order. The goal is to spread traffic evenly when all backends are assumed to be similar.

### Where round robin happens in Kubernetes
There are multiple layers where balancing can occur:
- External load balancer (Azure Load Balancer) distributes traffic across nodes or NodePorts.
- Ingress controller (ingress-nginx) proxies HTTP and can balance requests to Service endpoints.
- Kubernetes Service selects a pod endpoint, implemented by kube-proxy (iptables or IPVS).

### Common alternatives and when to use them
- Least connections
  - Sends new requests to the backend with the fewest active connections.
  - Good when request duration varies a lot.
- Least response time (or latency aware)
  - Prefers backends with better recent latency.
  - Useful for performance sensitive traffic.
- Weighted round robin
  - Same as round robin but some backends get more traffic.
  - Useful during gradual rollout or uneven capacity.
- Hash based (consistent hashing)
  - Routes based on a key like client IP or header value.
  - Useful for session affinity or caching.
- Random
  - Surprisingly effective at scale, simpler than it sounds.
  - Works well with good health checks and enough replicas.

### Session affinity (sticky sessions)
If an app requires a user to hit the same backend repeatedly:
- Cookie based affinity (usually handled by ingress).
- Client IP affinity (can be done at Service or ingress, depends on implementation).
Downside: can reduce even distribution and complicate failover.

### Why round robin was enough for this challenge
- Stateless nginx based hello app.
- Multiple replicas show distribution clearly.
- HA focus is on multi-region and routing, not complex L7 policies.

## 2) Deployment strategies: blue green, canary, rolling, and more

### Rolling update (default Kubernetes behavior)
- Gradually replaces old pods with new pods.
- Controlled by maxUnavailable and maxSurge.
Pros:
- No extra environment needed.
- Simple, built in.
Cons:
- Harder to instantly rollback if the issue is not detected early.
- Some users may hit mixed versions during the rollout.

### Blue green deployment
- Two environments: blue (current) and green (new).
- Deploy to green, validate, then switch traffic from blue to green.
Pros:
- Very fast rollback by switching back.
- Clear cutover moment.
Cons:
- Requires capacity for two environments.
- Switching mechanism must be reliable (Ingress routing, Service selector change, or external routing).

How to implement in Kubernetes:
- Two Deployments and two Services, switch Ingress backend.
- One Service, switch selector labels from blue to green (careful with readiness).
- Two namespaces, switch Ingress target.

### Canary deployment
- Release new version to a small percentage of users first.
- Increase percentage if metrics look good.
Pros:
- Low risk rollout with real traffic.
- Supports progressive delivery.
Cons:
- Needs traffic splitting mechanism and monitoring.
- More operational complexity.

Common traffic splitting tools:
- Ingress canary annotations (nginx supports canary patterns).
- Service mesh (Istio, Linkerd) for fine-grained routing.
- External gateway or load balancer features.

### A/B testing
- Routes traffic based on user attributes or experiment flags.
- Focus is product experimentation rather than safe rollout.
Often requires:
- Header or cookie based routing.
- Feature flags.

### Shadow traffic (mirroring)
- Copy production traffic to a new version without affecting responses.
Pros:
- Real traffic testing without user impact.
Cons:
- Must handle sensitive data carefully.
- Can create load duplication.

### Why these matter for the challenge
Even if you only used rolling update in practice, you should be able to explain:
- What you would pick for production.
- What tradeoffs exist: risk, cost, rollback speed, monitoring needs.

## 3) Autoscaling theory: HPA, VPA, Cluster Autoscaler

### HPA (Horizontal Pod Autoscaler)
- Scales number of replicas based on metrics.
- Common metric: CPU utilization, memory (less reliable), custom metrics (requests per second).
Key points:
- HPA does not balance traffic, it changes replica count.
- Load balancing across replicas is done by Service and ingress.

### VPA (Vertical Pod Autoscaler)
- Adjusts pod resource requests and limits.
- Better when the app does not scale horizontally well.
Tradeoff:
- Often requires pod restarts to apply changes.

### Cluster Autoscaler
- Adds or removes nodes based on scheduling pressure.
- If HPA creates more pods than nodes can host, Cluster Autoscaler can add nodes (if enabled).
Important constraint:
- In managed clusters, cluster autoscaler settings are separate from HPA.

## 4) Ingress, Service, and load balancers

### Service types
- ClusterIP
  - Internal stable virtual IP inside the cluster.
- NodePort
  - Exposes a port on every node, usually used behind an external load balancer.
- LoadBalancer
  - Provisions a cloud load balancer (Azure Load Balancer) with a public IP.

### Ingress controller vs Ingress resource
- Ingress resource is config (routes, hosts, TLS).
- Ingress controller is the running component that implements routing (ingress-nginx pods).

### TLS termination
TLS termination is where HTTPS is decrypted:
- At ingress-nginx (common in Kubernetes).
- At an external gateway (Azure Front Door) in some architectures.
For the challenge:
- Self-signed is acceptable.
- Production would use a real domain and automated certificates (cert-manager + ACME or managed certs).

## 5) Health checks and probes

### Readiness probe
- Controls whether a pod receives traffic.
- If readiness fails, pod is removed from Service endpoints.
Used to avoid sending traffic to a pod that is not ready.

### Liveness probe
- Detects stuck or dead containers.
- If liveness fails, kubelet restarts the container.

### Startup probe
- For slow starting apps.
- Prevents liveness from killing the app during startup.

Why it matters:
- Safe rollouts depend on readiness.
- Failover and routing depend on reliable health endpoints like /healthz.

## 6) Multi-region HA and global routing

### Active passive
- Active region serves traffic.
- Passive region is standby.
Standby modes:
- Warm: cluster and app already running at low scale.
- Cold: infrastructure not running, recreated via IaC and restored from backups.

Pros:
- Simpler than active active.
- Lower cost than running both at full capacity.
Cons:
- Failover time depends on DNS, routing, and warm vs cold state.

### Active active
- Both regions serve traffic.
Pros:
- Best availability and lowest failover impact.
Cons:
- Harder data consistency if stateful.
- Higher cost and complexity.

### DNS based routing (Traffic Manager)
- Routes by returning different IPs in DNS responses based on endpoint health and policy (priority, weighted, performance).
Key limitations:
- DNS caching affects failover speed.
- Some clients may keep using cached results.

Alternatives:
- Azure Front Door (L7 global entry, faster failover, WAF, TLS at edge).
- Anycast based solutions and global gateways.

## 7) Observability basics for this challenge

### Three pillars
- Metrics: trends, saturation, error rates.
- Logs: detailed events, debugging.
- Traces: request path through services (less relevant for this simple app but important in real systems).

### Useful SLI examples
- Availability of /healthz (success rate).
- Request latency percentiles.
- Error rate (4xx, 5xx).
- Resource saturation: CPU, memory, restarts.

### SLO mindset
- Define a target like 99.9% availability.
- Alerts should be tied to user impact, not just raw metrics.

## 8) Backup and Recovery theory

### RPO and RTO
- RPO (Recovery Point Objective): how much data loss is acceptable.
- RTO (Recovery Time Objective): how long recovery can take.

### Backup vs DR
- Backup is for restoring data after loss or corruption.
- DR is for keeping service available after regional failure.

In this challenge:
- You described two recovery modes:
  - Near zero downtime option (active active concept).
  - MTTR <= 4h option (active passive or cold standby with reproducible infra).

## 9) DNS hiccups in Kubernetes: what can go wrong

Key components:
- Pod resolv.conf points to kube-dns Service IP.
- kube-dns Service routes to CoreDNS pods.
- CoreDNS forwards external names to upstream DNS.

Common root causes:
- CoreDNS overloaded (CPU throttling, too few replicas).
- Node network issues (conntrack full, iptables problems, MTU issues).
- CNI overlay issues.
- Upstream DNS instability.
- Packet loss on UDP/53.

Typical debugging approach:
- Verify from a pod: nslookup internal service and external domain.
- Check CoreDNS pods and logs.
- Debug on the node and capture DNS packets (tcpdump) to see if requests and responses flow.

## 10) Infrastructure as Code and reproducibility

Why IaC matters:
- Recreate environments quickly (cold standby).
- Reduce configuration drift.
- Make changes reviewable (git history, pull requests).

Terraform patterns:
- Separate modules for networking, AKS, monitoring, traffic manager.
- Outputs used to connect tooling (get-credentials, endpoints).

## 11) Security basics relevant here

Even if not fully implemented, be ready to explain:
- RBAC (who can do what in the cluster).
- Least privilege.
- Network policies (restrict pod to pod traffic).
- Secret management (Kubernetes Secret vs external store like Key Vault).
- TLS as a baseline security control.

## 12) Common interview style clarifications

- Load balancing vs scaling
  - Balancing distributes traffic among existing replicas.
  - Scaling changes the number of replicas or nodes.
- Service vs Ingress
  - Service is internal stable endpoint for pods.
  - Ingress is HTTP routing and TLS at the edge of the cluster.
- DNS routing vs application routing
  - Traffic Manager influences which IP clients use.
  - Ingress decides which backend inside a cluster gets the HTTP request.
