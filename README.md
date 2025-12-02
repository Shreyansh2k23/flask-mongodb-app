# Flask + MongoDB + Kubernetes (Minikube)

A simple Flask application using MongoDB, deployed to a Kubernetes cluster (tested with Minikube).

This repository demonstrates a StatefulSet-backed MongoDB, a Flask Deployment, Services, HPA, PV/PVC, DNS-based service discovery, and resource requests/limits.

## Project structure

```
flask-mongodb-k8s/
├── app.py
├── requirements.txt
├── Dockerfile
├── README.md
├── screenshots/
│   ├── hpa-before.png
│   ├── hpa-after.png
└── k8s/
    ├── namespace.yaml
    ├── mongo-secret.yaml
    ├── mongo-pv-pvc.yaml
    ├── mongo-statefulset.yaml
    ├── mongo-service.yaml
    ├── flask-mongo-secret.yaml
    ├── flask-deployment.yaml
    ├── flask-service.yaml
    ├── flask-hpa.yaml

```

## Build & push Docker image

Replace `<dockerhub-username>` with your Docker Hub username.

```powershell
docker build -t <dockerhub-username>/flask-mongodb-app:v1 .
docker login
docker push <dockerhub-username>/flask-mongodb-app:v1
```

## Kubernetes deployment (Minikube)

Start Minikube and apply the manifests:

```bash
minikube start
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/mongo-secret.yaml
kubectl apply -f k8s/mongo-pv-pvc.yaml
kubectl apply -f k8s/mongo-statefulset.yaml
kubectl apply -f k8s/mongo-service.yaml
kubectl apply -f k8s/flask-mongo-secret.yaml
kubectl apply -f k8s/flask-deployment.yaml
kubectl apply -f k8s/flask-service.yaml
kubectl apply -f k8s/flask-hpa.yaml

# Verify
kubectl get pods -n flask-mongo-ns
kubectl get svc -n flask-mongo-ns
kubectl get hpa -n flask-mongo-ns
```

## Access the Flask application

Use port-forwarding to access the service locally (Windows example using PowerShell):

```powershell
kubectl port-forward service/flask-service 5000:5000 -n flask-mongo-ns

# Then open in your browser:
http://127.0.0.1:5000/
```

## Test API endpoints

Check the homepage:

```bash
curl http://127.0.0.1:5000/
```

Insert data (Windows `curl.exe` multiline example):

```powershell
curl.exe -X POST -H "Content-Type: application/json" ^
    -d '{"name":"test"}' ^
    http://127.0.0.1:5000/data
```

Get data:

```bash
curl http://127.0.0.1:5000/data
```

## MongoDB authentication

Credentials are provided via Kubernetes secrets (see `flask-mongo-secret.yaml`). The MongoDB environment variables used are:

- `MONGO_INITDB_ROOT_USERNAME`
- `MONGO_INITDB_ROOT_PASSWORD`

Connection string example used by Flask:

```text
mongodb://mongo:mongo123@mongo-service:27017/flask_db?authSource=admin
```

## Persistent storage (PV + PVC)

MongoDB stores data under `/data/db` inside the container. A PersistentVolume and PersistentVolumeClaim are used so data persists when pods restart.

## DNS resolution

Kubernetes DNS exposes services by name. The MongoDB service is reachable as `mongo-service` inside the cluster, e.g. `mongo-service:27017`.

## Resource requests & limits

Example values applied to containers:

- Requests: CPU `0.2`, Memory `250Mi`
- Limits:   CPU `0.5`, Memory `500Mi`

Requests reserve a minimum amount of resources; limits cap usage to prevent a pod from consuming all cluster resources.

## Horizontal Pod Autoscaler (HPA)

Typical HPA config used for Flask in this project:

- `minReplicas: 2`
- `maxReplicas: 5`
- target CPU utilization: `70%`

HPA scales Flask pods based on CPU load.

## Testing scenarios

High-traffic simulation examples:

```bash
# hey (example)
hey -n 10000 -c 50 http://127.0.0.1:5000/

# ApacheBench
ab -n 5000 -c 100 http://127.0.0.1:5000/
```

Other tests performed:

- Insert multiple JSON documents and verify with `GET /data` and inside Mongo using `mongosh`.
- Delete MongoDB pod (e.g. `kubectl delete pod mongo-0`) and confirm data persists using the same PV.

## Design choices

- StatefulSet for MongoDB — stable identity and persistent storage.
- Deployment for Flask — rolling updates and scaling.
- ClusterIP for MongoDB — internal-only access.
- Port-forwarding for Flask — simple external access for testing.
- Secrets for credentials — secure DB authentication.
- PV + PVC for persistent data.
- HPA to autoscale under load.

---

If you want, I can also:

- run a quick spell/grammar check
- update `README.md` filename case to `README.md` (if needed on Windows)
- open a PR with this change

Let me know which of those you'd like next.

## Autoscaling testing & results

### Before load testing

Check the initial state of the HPA and pods:

```bash
kubectl get hpa -n flask-mongo-ns
kubectl get pods -n flask-mongo-ns
```

Expected output shows 2 replicas running initially (as per `minReplicas: 2`).
To simulate high traffic, I used a PowerShell loop to send ~30,000 requests to the root endpoint:

```powershell
for ($i=0; $i -lt 30000; $i++) { curl.exe http://127.0.0.1:5000/ > $null }



While the load was running, I repeatedly checked HPA and pods:

kubectl get hpa -n flask-mongo-ns
kubectl get pods -n flask-mongo-ns

```
![HPA Before Load](screenshots/hpa-before.PNG)
![HPA After Load](screenshots/hpa-after.PNG)


(Describe what happened)

If replicas increased:

“The HPA observed CPU usage above the 70% threshold and scaled the deployment from 2 to N replicas.”

If replicas stayed 2 and TARGETS stayed <unknown>:

“Due to metrics-server limitations on my local Minikube setup (Windows + Docker driver), CPU values stayed <unknown>/70%, so HPA did not scale out, but the configuration is correctly defined and applied.”


Both cases are okay as long as you:

- Show the HPA is configured
- Show you **attempted load**
- Explain what happened

---

## 🔁 Quick recap of steps you need now
```
1. `minikube start`
2. (Optional) re-enable metrics-server  
3. **PS #2** – `kubectl port-forward service/flask-service 5000:5000 -n flask-mongo-ns`
4. **PS #3** – `kubectl get hpa` + `kubectl get pods` → Screenshot BEFORE
5. **PS #4** – run `for ($i=0; $i -lt 30000; $i++) { curl.exe http://127.0.0.1:5000/ > $null }`
6. While load runs, in PS #3: `kubectl get hpa` + `kubectl get pods` → Screenshot AFTER
7. Stop load, stop minikube (when done)
```
---

If you want, you can paste **one final `kubectl get hpa` + `kubectl get pods` output after doing this**, and I’ll tell you exactly what to write in the README under “Autoscaling behaviour”.
