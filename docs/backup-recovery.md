# Backup & Recovery Concepts

## Option 1 – Near Zero Downtime (Active-Active)

**Goal:** continue serving traffic during regional outage.

**Approach:**
- Two active regions (AKS-A and AKS-B)
- Global routing with health checks (Traffic Manager or Front Door)
- Stateless workloads replicated in both regions (CI/CD or GitOps)
- Data layer: geo-replication / multi-master (depends on datastore)
- Deploy strategy: canary / blue-green

**Expected:**
- RPO: near zero (depends on datastore replication)
- RTO: minutes (health check + DNS/traffic switch)

## Option 2 – MTTR ≤ 4h (Active-Passive)

**Goal:** restore service within 4 hours after outage.

**Approach:**
- Active region serves traffic; passive region is warm/standby (or cold with reproducible infra)
- Infrastructure reproducible via Terraform
- Regular backups for stateful components (databases, object storage)
- Runbook with tested steps and timings
- Regular restore test as part of maintenance

**Expected:**
- RPO: depends on backup frequency
- RTO: ≤ 4h with practiced runbook