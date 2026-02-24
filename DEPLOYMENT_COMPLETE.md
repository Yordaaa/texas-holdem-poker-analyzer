# Complete Deployment Guide - Texas Hold'em Poker App

## Prerequisites Check

Before running the deployment, ensure you have:

1. **Google Cloud Account**
   - Visit: https://cloud.google.com
   - Create a free account if you don't have one
   - Set up billing (required for GKE)

2. **Required Tools Installed**
   ```bash
   # Check gcloud
   gcloud --version
   
   # Check docker
   docker --version
   
   # Check kubectl
   kubectl version --client
   ```

3. **Authentication Complete**
   ```bash
   # Verify you're logged in
   gcloud auth list
   # Should show your account with "ACTIVE" status
   ```

## Quick Deployment (Linux/macOS)

### Option 1: Fully Automated (Recommended)

```bash
# Make script executable
chmod +x deploy-complete.sh

# Run the deployment
./deploy-complete.sh
```

The script will:
- Create a new GCP project
- Enable all required APIs
- Build Docker images
- Push to Google Container Registry
- Create a GKE cluster
- Deploy the application
- Obtain the external IP for your app

**Expected time: 10-15 minutes**

### Option 2: Step-by-Step Manual Deployment

If you want more control, follow these steps:

#### Step 1: Set Configuration Variables
```bash
export GCP_PROJECT_ID="texas-poker-$(date +%s)"
export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"
export CLUSTER_NAME="poker-cluster"

# Verify
echo "Project: $GCP_PROJECT_ID"
echo "Region: $GCP_REGION"
echo "Cluster: $CLUSTER_NAME"
```

#### Step 2: Create GCP Project
```bash
gcloud projects create $GCP_PROJECT_ID \
    --name="Texas Hold'em Poker App" \
    --set-as-default
```

#### Step 3: Enable APIs
```bash
gcloud services enable container.googleapis.com \
    --project=$GCP_PROJECT_ID
gcloud services enable containerregistry.googleapis.com \
    --project=$GCP_PROJECT_ID
gcloud services enable compute.googleapis.com \
    --project=$GCP_PROJECT_ID
gcloud services enable cloudbuild.googleapis.com \
    --project=$GCP_PROJECT_ID
```

#### Step 4: Configure Docker
```bash
gcloud auth configure-docker --quiet
```

#### Step 5: Build and Push Images
```bash
export REGISTRY="gcr.io/${GCP_PROJECT_ID}"
export BACKEND_IMAGE="${REGISTRY}/texas-backend"
export FRONTEND_IMAGE="${REGISTRY}/texas-frontend"

# Build and push backend
docker build -t $BACKEND_IMAGE:latest ./backend
docker push $BACKEND_IMAGE:latest

# Build and push frontend
docker build -t $FRONTEND_IMAGE:latest ./frontend
docker push $FRONTEND_IMAGE:latest
```

#### Step 6: Create GKE Cluster
```bash
gcloud container clusters create $CLUSTER_NAME \
    --project=$GCP_PROJECT_ID \
    --zone=$GCP_ZONE \
    --num-nodes=2 \
    --machine-type=n1-standard-2 \
    --enable-stackdriver-kubernetes \
    --enable-ip-alias \
    --network="default" \
    --enable-autoscaling \
    --min-nodes=2 \
    --max-nodes=5 \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing
```

#### Step 7: Get Cluster Credentials
```bash
gcloud container clusters get-credentials $CLUSTER_NAME \
    --zone=$GCP_ZONE \
    --project=$GCP_PROJECT_ID
```

#### Step 8: Update Kubernetes Manifests
```bash
# Update the image placeholders
sed -i.bak "s|<PROJECT-ID>|${GCP_PROJECT_ID}|g" k8s/backend-deployment.yaml
sed -i.bak "s|<PROJECT-ID>|${GCP_PROJECT_ID}|g" k8s/frontend-deployment.yaml
```

#### Step 9: Deploy to Kubernetes
```bash
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
```

#### Step 10: Verify Deployment
```bash
# Check pod status
kubectl get pods

# Wait for rollout to complete
kubectl rollout status deployment/texas-backend --timeout=5m
kubectl rollout status deployment/texas-frontend --timeout=5m

# Get service information
kubectl get svc texas-frontend
```

## Deployment on Windows

### Step 1: Update Kubernetes Manifests Manually

Before running the batch script or manual commands, you need to update the manifests:

1. Open `k8s/backend-deployment.yaml` in a text editor
2. Replace `<PROJECT-ID>` with your actual project ID
3. Save and close
4. Repeat for `k8s/frontend-deployment.yaml`

### Step 2: Run the Batch Script
```batch
deploy-complete.bat
```

Or follow the manual steps above using PowerShell or Command Prompt.

## Accessing Your Application

### Get the External IP
```bash
kubectl get svc texas-frontend

# Watch until EXTERNAL-IP changes from <pending> to actual IP
kubectl get svc texas-frontend --watch
```

### Access the Application
Once you have the external IP:
```
http://<EXTERNAL-IP>
```

Example: `http://34.120.45.123`

## Useful Commands After Deployment

### View Application Logs
```bash
# Backend logs
kubectl logs -f deployment/texas-backend

# Frontend logs
kubectl logs -f deployment/texas-frontend

# View specific pod
kubectl logs -f <pod-name>
```

### Check Pod Status
```bash
# All pods
kubectl get pods

# Detailed pod info
kubectl describe pod <pod-name>

# Watch pods in real-time
kubectl get pods --watch
```

### Scale Deployments
```bash
# Scale backend to 3 replicas
kubectl scale deployment texas-backend --replicas=3

# Scale frontend to 3 replicas
kubectl scale deployment texas-frontend --replicas=3
```

### Check Services
```bash
# All services
kubectl get svc

# Detailed service info
kubectl describe svc texas-frontend
```

### Check Horizontal Pod Autoscaler
```bash
# View HPA status
kubectl get hpa

# Watch HPA
kubectl get hpa --watch

# Detailed HPA info
kubectl describe hpa texas-backend
```

### Get Node Information
```bash
# List all nodes
kubectl get nodes

# Detailed node info
kubectl describe node <node-name>
```

## Troubleshooting

### Pods Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### LoadBalancer External IP Stuck on "Pending"
```bash
# This is normal initially and can take 2-5 minutes
# Keep checking:
kubectl get svc texas-frontend --watch

# If stuck for more than 5 minutes:
# 1. Check if cluster has enough resources
kubectl get nodes
kubectl top nodes

# 2. Check for errors
kubectl describe svc texas-frontend
```

### Cannot Connect to Application
```bash
# Verify service is running
kubectl get svc texas-frontend

# Check backend connectivity
kubectl exec -it <frontend-pod-name> -- \
  curl -v http://texas-backend:8080/evaluate

# Check pod logs
kubectl logs <pod-name>
```

### Image Pull Errors
```bash
# Verify images were pushed to GCR
gcloud container images list --project=$GCP_PROJECT_ID

# Check image details
gcloud container images describe gcr.io/$GCP_PROJECT_ID/texas-backend

# Verify credentials
gcloud auth list
```

## Monitoring & Maintenance

### Check Resource Usage
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods

# Detailed metrics
kubectl get metrics pods
```

### Update Application (Rolling Update)
```bash
# Build and push new image
docker build -t gcr.io/$GCP_PROJECT_ID/texas-backend:v2 ./backend
docker push gcr.io/$GCP_PROJECT_ID/texas-backend:v2

# Update deployment
kubectl set image deployment/texas-backend \
  backend=gcr.io/$GCP_PROJECT_ID/texas-backend:v2 \
  --record
```

### Rollback Deployment
```bash
# Check rollout history
kubectl rollout history deployment/texas-backend

# Rollback to previous version
kubectl rollout undo deployment/texas-backend
```

## Cost Optimization

### Key Cost Drivers
1. **GKE Cluster**: ~$74/month (2 n1-standard-2 nodes)
2. **Compute**: ~$60/month per node
3. **Networking**: Minimal (LoadBalancer)
4. **Storage**: Minimal (no persistent volumes)

### Cost Reduction Tips
```bash
# Scale down nodes when not in use
gcloud container clusters update $CLUSTER_NAME \
  --zone=$GCP_ZONE \
  --num-nodes=1

# Or scale replicas to 0 (destroys service)
kubectl scale deployment texas-backend --replicas=0
kubectl scale deployment texas-frontend --replicas=0
```

## Cleanup (When Done)

### Delete Everything
```bash
# Delete deployments and services
kubectl delete deployment texas-backend texas-frontend

# Delete cluster
gcloud container clusters delete $CLUSTER_NAME \
  --zone=$GCP_ZONE

# Delete project
gcloud projects delete $GCP_PROJECT_ID

# Remove local credentials
gcloud config unset core/project
```

### Delete Images from GCR
```bash
# List images
gcloud container images list --project=$GCP_PROJECT_ID

# Delete backend image
gcloud container images delete gcr.io/$GCP_PROJECT_ID/texas-backend \
  --quiet --delete-tags

# Delete frontend image
gcloud container images delete gcr.io/$GCP_PROJECT_ID/texas-frontend \
  --quiet --delete-tags
```

## Important Notes

1. **Project Creation**: Each run creates a new project. Remember the project ID for cleanup.
2. **Billing**: GKE clusters incur charges once created. Delete when not in use.
3. **API Enablement**: This happens automatically in the script.
4. **Credentials**: Make sure `gcloud auth login` has been run.
5. **Docker**: Ensure Docker daemon is running before building images.
6. **kubectl**: Automatically configured after GKE cluster creation.

## Support

For issues, check:
- GCP Console: https://console.cloud.google.com
- GKE Cluster dashboards with logs and metrics
- `kubectl describe` for detailed error messages
- View GCP project billing and API usage

---

**Deployment Complete! Your Texas Hold'em Poker App is now live on GKE.** 🎉
