# Commands Used During the Challenge

## 0) Tooling install and PATH troubleshooting (Windows)

```powershell
winget install -e --id Kubernetes.kubectl
winget install -e --id Helm.Helm

kubectl version --client
helm version
```

### Azure CLI path troubleshooting (when az not found):

```powershell
Get-ChildItem "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" -ErrorAction SilentlyContinue
Get-ChildItem "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" -ErrorAction SilentlyContinue

& "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd" version

$env:Path += ";C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
where.exe az
az version
```

## 1) Azure CLI login and subscription

```bash
az version
az login

az account list -o table
az account show -o table
az account set --subscription "GTO-TSPC-DevOps-Recruiting"
az account show -o table
```

## 2) Terraform workflow (infra)

```bash
cd infra/terraform

terraform fmt -recursive
terraform validate
terraform init
terraform plan
terraform apply
```

### (If you want the "plan artifact" style)

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## 3) Verify Azure resources after Terraform

```bash
az aks list -o table
az group list -o table
az resource list -g rg-devops-challenge-ilar -o table
```

## 4) Connect kubectl to AKS (switch contexts)

### Region A:

```bash
az aks get-credentials -g rg-devops-challenge-ilar -n devops-challenge-aks --overwrite-existing
kubectl config current-context
kubectl get nodes -o wide
```

### Region B:

```bash
az aks get-credentials -g rg-devops-challenge-ilar -n devops-challenge-aks-b --overwrite-existing
kubectl config current-context
kubectl get nodes -o wide
```

### Quick "am I in the right cluster":

```bash
kubectl config current-context
kubectl get nodes
```

## 5) Install ingress-nginx (per cluster) via Helm

### Add repo (once per machine):

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

### Install controller:

```powershell
kubectl create ns ingress-nginx

helm install ingress-nginx ingress-nginx/ingress-nginx `
  -n ingress-nginx `
  --set controller.service.type=LoadBalancer
```

### Wait for public IP and inspect:

```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller -w
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
kubectl -n ingress-nginx get deploy,po,svc -o wide
```

### Ingress controller logs:

```bash
kubectl -n ingress-nginx get pods -o wide
kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=200
```

### Describe service (shows provisioning events):

```bash
kubectl -n ingress-nginx describe svc ingress-nginx-controller
```

## 6) Deploy the hello app (per cluster)

### Apply all manifests:

```bash
kubectl apply -f k8s/hello/
```

### Validate workload:

```bash
kubectl -n hello get pods -o wide
kubectl -n hello describe deploy hello
kubectl -n hello get events --sort-by=.lastTimestamp
```

### Service and endpoints:

```bash
kubectl -n hello get svc
kubectl -n hello get endpoints hello -o wide
```

### Ingress:

```bash
kubectl -n hello get ingress -o wide
kubectl -n hello describe ingress hello
```

### Test from browser/curl using ingress public IP:

```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
curl -i http://<EXTERNAL-IP>/
curl -i http://<EXTERNAL-IP>/healthz
```

## 7) Health checks and in-cluster testing

### Exec into the deployment and hit local NGINX health endpoint:

```bash
kubectl -n hello exec -it deploy/hello -- sh -lc "wget -qO- http://127.0.0.1/healthz; echo"
```

**task complete**

## 8) Logs and troubleshooting

### App logs:

```bash
kubectl -n hello logs deploy/hello --tail=200
kubectl -n hello logs deploy/hello -c nginx --tail=200
```

### Ingress logs:

```bash
kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=200
```

### Describe objects fast:

```bash
kubectl -n hello describe pod <pod-name>
kubectl -n hello describe ingress hello
kubectl -n ingress-nginx describe svc ingress-nginx-controller
```

### Restart / rollout status:

```bash
kubectl -n hello rollout restart deploy/hello
kubectl -n hello rollout status deploy/hello

kubectl -n ingress-nginx rollout restart deploy/ingress-nginx-controller
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller
```

### Search logs for a specific string on Windows:

```powershell
kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=200 | findstr /i "add-headers ingress-response-headers"
```

### View a ConfigMap as YAML:

```bash
kubectl -n hello get cm ingress-response-headers -o yaml
```

## 9) HTTPS quick check (curl on Windows)

```powershell
curl.exe -k -i https://20.126.210.29/ | findstr /i "HTTP/ X-Cluster-Name"
```

**task complete**

## 10) Monitoring MVP: Azure Monitor / Log Analytics agent check

### Check AMA pods:

```powershell
kubectl -n kube-system get pods | findstr ama
```

**task complete**

## 11) Azure Traffic Manager (active-passive failover)

### Variables used:

```powershell
$RG="rg-devops-challenge-ilar"
$TM="tm-devops-ilar"
$IP_A="20.126.210.29"
$IP_B="20.54.97.214"
```

### Set probe:

```powershell
az network traffic-manager profile update -g $RG -n $TM --protocol HTTP --port 80 --path "/healthz"
```

### Create endpoints (external endpoints pointing to ingress public IPs):

```powershell
az network traffic-manager endpoint create -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --target $IP_A --priority 1

az network traffic-manager endpoint create -g $RG --profile-name $TM `
  -n ep-aks-b --type externalEndpoints --target $IP_B --priority 2

az network traffic-manager endpoint list -g $RG --profile-name $TM -o table
```

### Validate probe and routing:

```powershell
irm http://tm-devops-ilar.trafficmanager.net/healthz -UseBasicParsing
nslookup tm-devops-ilar.trafficmanager.net
```

### Failover demo (disable primary, then re-test):

```powershell
az network traffic-manager endpoint update -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --endpoint-status Disabled

# (optional local DNS cache flush)
ipconfig /flushdns
nslookup tm-devops-ilar.trafficmanager.net
```

### Rollback (enable primary again):

```powershell
az network traffic-manager endpoint update -g $RG --profile-name $TM `
  -n ep-aks-a --type externalEndpoints --endpoint-status Enabled
```

## 12) Azure-side checks for the ingress public IP and load balancer

```bash
az network public-ip list -g <node-resource-group>
az network lb list -g <node-resource-group>
```

*(Node RG often looks like MC_rg_aksname_region)*