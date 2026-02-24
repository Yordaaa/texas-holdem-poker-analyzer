# Texas Hold'em Poker App - Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Local Testing with Docker Compose](#local-testing-with-docker-compose)
3. [Google Cloud Platform Deployment](#google-cloud-platform-deployment)
4. [Monitoring and Scaling](#monitoring-and-scaling)

---

## Prerequisites

### Required Tools
- **Docker** (v20.10+) - https://docs.docker.com/get-docker/
- **Docker Compose** (v1.29+) - included with Docker Desktop
- **gcloud CLI** - https://cloud.google.com/sdk/docs/install
- **kubectl** - https://kubernetes.io/docs/tasks/tools/
- **Git** (optional but recommended)

### GCP Setup
1. Create a Google Cloud Project
   ```bash
   gcloud projects create texas-poker --name="Texas Hold'em Poker"
   ```

2. Set your default project
   ```bash
   gcloud config set project <YOUR_PROJECT_ID>
   ```

3. Enable required APIs
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable containerregistry.googleapis.com
   gcloud services enable compute.googleapis.com
   ```

4. Set up authentication
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

---

## Local Testing with Docker Compose

### Build and Run Locally

```bash
# Navigate to project root
cd Texas\ Hold\'em\ poker

# Build images
docker-compose build

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Access the app
# Frontend: http://localhost
# Backend: http://localhost:8080
```

### Test the Services

**Backend Health Check:**
```bash
curl http://localhost:8080/evaluate \
  -H "Content-Type: application/json" \
  -d '{"hole": ["HA", "HK"], "board": ["D2", "D3", "D4", "D5", "D6"]}'
```

**Frontend:**
Open browser to `http://localhost`

### Stop Services

```bash
docker-compose down        # Stop and remove containers
docker-compose down -v     # Also remove volumes
```

---

## Google Cloud Platform Deployment

### Option 1: Using Automated Script (Recommended)

```bash
# Set your GCP project ID
export GCP_PROJECT_ID="your-gcp-project-id"
export GCP_REGION="us-central1"
export TAG="v1.0.0"

# Make script executable
chmod +x deploy-gcp.sh

# Run deployment script
./deploy-gcp.sh
```

### Option 2: Manual Deployment Steps

#### Step 1: Configure gcloud and Docker
```bash
# Set project
gcloud config set project <YOUR_PROJECT_ID>

# Configure Docker authentication
gcloud auth configure-docker
```

#### Step 2: Build Docker Images
```bash
cd backend
docker build -t gcr.io/<PROJECT_ID>/texas-backend:latest .
cd ../frontend
docker build -t gcr.io/<PROJECT_ID>/texas-frontend:latest .
cd ..
```

#### Step 3: Push to Google Container Registry
```bash
# Push backend
docker push gcr.io/<PROJECT_ID>/texas-backend:latest

# Push frontend
docker push gcr.io/<PROJECT_ID>/texas-frontend:latest
```

#### Step 4: Create GKE Cluster
```bash
gcloud container clusters create poker-cluster \
  --zone us-central1-a \
  --num-nodes 2 \
  --machine-type n1-standard-2 \
  --enable-stackdriver-kubernetes
```

#### Step 5: Get Cluster Credentials
```bash
gcloud container clusters get-credentials poker-cluster \
  --zone us-central1-a
```

#### Step 6: Update Kubernetes Manifests
Edit `k8s/backend-deployment.yaml` and `k8s/frontend-deployment.yaml`, replace `<PROJECT-ID>` with your actual GCP project ID.

#### Step 7: Deploy to Kubernetes
```bash
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
```

#### Step 8: Verify Deployment
```bash
# Check pods
kubectl get pods

# Check services
kubectl get svc

# View backend logs
kubectl logs -f deployment/texas-backend

# View frontend logs
kubectl logs -f deployment/texas-frontend
```

---

## Monitoring and Scaling

### View Deployments
```bash
# List all deployments
kubectl get deployments

# Describe a deployment
kubectl describe deployment texas-backend

# Get detailed pod info
kubectl get pods -o wide
```

### Scale Deployments
```bash
# Scale backend to 3 replicas
kubectl scale deployment texas-backend --replicas=3

# Scale frontend to 3 replicas
kubectl scale deployment texas-frontend --replicas=3

# Auto-scale based on CPU usage
kubectl autoscale deployment texas-backend --min=2 --max=5 --cpu-percent=80
```

### View Logs
```bash
# Stream backend logs
kubectl logs -f deployment/texas-backend

# View logs from specific pod
kubectl logs -f <POD_NAME>

# View last 100 lines
kubectl logs --tail=100 deployment/texas-backend
```

### Monitor Services
```bash
# Watch deployment status
kubectl rollout status deployment/texas-backend

# Watch all resources
kubectl get all -w

# View service details
kubectl describe svc texas-frontend
```

### Get Frontend URL
```bash
# For LoadBalancer service
kubectl get svc texas-frontend

# Once ready, access frontend at the EXTERNAL-IP
# Example: http://34.123.45.67
```

---

## Cleanup

### Delete from Google Cloud
```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Delete GKE cluster
gcloud container clusters delete poker-cluster --zone us-central1-a

# Delete images from GCR
gcloud container images delete gcr.io/<PROJECT_ID>/texas-backend --quiet
gcloud container images delete gcr.io/<PROJECT_ID>/texas-frontend --quiet
```

### Local Cleanup
```bash
# Remove local images
docker rmi gcr.io/<PROJECT_ID>/texas-backend
docker rmi gcr.io/<PROJECT_ID>/texas-frontend

# Remove volumes
docker volume prune
```

---

## Troubleshooting

### Backend won't start
```bash
# Check logs
kubectl logs deployment/texas-backend
kubectl describe pod <POD_NAME>

# Verify image exists in GCR
gcloud container images list
```

### Frontend can't connect to backend
1. Ensure backend service is running: `kubectl get svc texas-backend`
2. Check CORS configuration in backend
3. Verify service networking: `kubectl get network-policies`

### ImagePullBackOff Error
```bash
# Verify GCR access
gcloud auth configure-docker

# Check image exists
gcloud container images list --repository=gcr.io/<PROJECT_ID>

# Recreate image pull secret if needed
kubectl create secret docker-registry gcr-secret \
  --docker-server=gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat ~/key.json)"
```

### High Latency
1. Check resource usage: `kubectl top pods`
2. Scale up replicas: `kubectl scale deployment texas-backend --replicas=5`
3. Check network policies: `kubectl get network-policies`
4. Review GCP console for zone/region performance

---

## Cost Optimization Tips

1. **Use Preemptible VMs** (cheaper but can be interrupted)
   ```bash
   gcloud container clusters create poker-cluster \
     --preemptible
   ```

2. **Run on Cloud Run** (serverless, pay per invocation)
   - Good for low-traffic apps
   - Automatic scaling

3. **Set resource limits** in deployments
   ```yaml
   resources:
     limits:
       cpu: "500m"
       memory: "256Mi"
     requests:
       cpu: "100m"
       memory: "128Mi"
   ```

4. **Delete cluster when not in use**
   ```bash
   gcloud container clusters delete poker-cluster
   ```

---

## Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Google Container Registry](https://cloud.google.com/container-registry/docs)

---

## Support

For issues or questions:
1. Check logs: `kubectl logs deployment/texas-backend`
2. Review GCP Cloud Console
3. Check Docker image availability in GCR
4. Verify service connectivity: `kubectl get svc`
