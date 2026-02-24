# Quick Start Guide - Docker & GCP Deployment

## 🚀 Quick Commands

### Local Testing (Docker Compose)
```bash
# Start all services locally
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Google Cloud Deployment (Automated)
```bash
# Set your GCP project ID
export GCP_PROJECT_ID="your-project-id"

# Run the deployment script
bash deploy-gcp.sh
```

### Manual GCP Steps
```bash
# Build Docker images
docker build -t gcr.io/<PROJECT_ID>/texas-backend:latest ./backend
docker build -t gcr.io/<PROJECT_ID>/texas-frontend:latest ./frontend

# Push to Google Container Registry
docker push gcr.io/<PROJECT_ID>/texas-backend:latest
docker push gcr.io/<PROJECT_ID>/texas-frontend:latest

# Create GKE cluster
gcloud container clusters create poker-cluster \
  --zone us-central1-a \
  --num-nodes 2

# Get credentials
gcloud container clusters get-credentials poker-cluster --zone us-central1-a

# Deploy
kubectl apply -f k8s/
```

---

## 📁 Files Guide

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Local multi-container setup |
| `deploy-gcp.sh` | Automated GCP deployment script |
| `deploy.bat` | Windows deployment helper |
| `DEPLOYMENT.md` | Comprehensive deployment guide |
| `.env.example` | Configuration template |
| `backend/Dockerfile` | Go backend container |
| `frontend/Dockerfile` | Flutter frontend container |
| `frontend/nginx.conf` | Nginx web server config |
| `k8s/backend-deployment.yaml` | Kubernetes backend manifest |
| `k8s/frontend-deployment.yaml` | Kubernetes frontend manifest |

---

## 🔍 Verification Commands

```bash
# Check pods running
kubectl get pods

# View services and IPs
kubectl get svc

# Check deployment status
kubectl rollout status deployment/texas-backend

# View backend logs
kubectl logs -f deployment/texas-backend

# View frontend logs
kubectl logs -f deployment/texas-frontend

# Get frontend external IP
kubectl get svc texas-frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

## 🐛 Troubleshooting

### Pods in CrashLoopBackOff
```bash
# Check logs
kubectl logs <POD_NAME>
kubectl describe pod <POD_NAME>
```

### Can't connect to backend from frontend
1. Verify backend service is running: `kubectl get svc texas-backend`
2. Check pods: `kubectl get pods`
3. View backend logs: `kubectl logs deployment/texas-backend`

### Image pull errors
```bash
# Ensure images are in GCR
gcloud container images list

# Reconfigure Docker auth
gcloud auth configure-docker
```

---

## 💰 Cost Management

- **Preemptible VMs**: Save 70% on compute (add `--preemptible` flag)
- **Scale down**: Reduce replicas when not in use
- **Delete cluster**: `gcloud container clusters delete poker-cluster`
- **Cloud Run alternative**: Better for low-traffic apps

---

## 📊 Monitoring

```bash
# Real-time resource monitoring
kubectl top pods
kubectl top nodes

# Watch all resources
kubectl get all -w

# View events
kubectl get events
```

---

## 🔄 Scaling

```bash
# Manual scaling
kubectl scale deployment texas-backend --replicas=5

# Auto-scaling (already configured in manifests)
# - Min 2 replicas
# - Max 5 replicas  
# - Triggers at 70% CPU or 80% memory
```

---

## 🛑 Cleanup

```bash
# Remove all resources
kubectl delete -f k8s/

# Delete GKE cluster
gcloud container clusters delete poker-cluster --zone us-central1-a

# Stop local containers
docker-compose down
```

For detailed information, see `DEPLOYMENT.md`
