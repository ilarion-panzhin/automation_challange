# Demo: HPA (Autoscaling) – increase pod count by simulating CPU load

Goal:
- Show HPA exists and explain how scaling works.
- Simulate CPU load to trigger autoscaling.
- Observe pod count increase in real-time.

## 1) Check current state

```powershell
kubectl -n hello get deploy hello -o wide
kubectl -n hello get pods -o wide
kubectl -n hello get hpa
kubectl -n hello describe hpa hello
```

Expected:
- Current replica count (e.g., 2 pods)
- HPA target CPU utilization and current metrics
- Min/max replicas configured

## 2) Watch HPA (separate terminal)

Open a new terminal window and run:

```powershell
kubectl -n hello get hpa -w
```

(Optional) Also watch deployment changes:

```powershell
kubectl -n hello get deploy hello -w
```

## 3) Trigger CPU load inside one pod

```powershell
$POD = (kubectl -n hello get pods -o jsonpath='{.items[0].metadata.name}')
kubectl -n hello exec -it $POD -- sh -c "dd if=/dev/zero of=/dev/null"
```

This command:
- Selects the first pod in the namespace
- Runs `dd` to generate CPU load (infinite loop reading/writing)

## 4) Observe scaling

In the watch terminal, monitor:
- CPU utilization rising above target threshold
- REPLICAS count increasing (up to maxReplicas)
- New pods being created and becoming Ready

Typical timeline: 15-60 seconds for metrics to update, then scaling occurs.

## 5) Stop load

Press `Ctrl + C` in the terminal running `dd` command.

## 6) Confirm new pod count

```powershell
kubectl -n hello get pods -o wide
kubectl -n hello get hpa
```

Expected:
- Increased number of pods (e.g., scaled from 2 to 4)
- HPA shows lower CPU utilization after load stops

## Key explanation

- HPA scales replicas (adds/removes pods) based on CPU target
- Load-balancing is done by Service/ingress; HPA only changes replica count
- Scale-down happens gradually