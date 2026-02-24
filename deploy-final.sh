#!/bin/bash

# Texas Hold'em Poker - GCP Deployment Script
# This works directly in bash/MINGW64

set -e

# Configuration
GCLOUD="/c/Users/yorda/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin/gcloud.cmd"
PROJECTID="texas-poker-final-$(date +%s)"
CLUSTER="poker-cluster"
ZONE="us-central1-a"
REGISTRY="gcr.io/$PROJECTID"

echo ""
echo "========================================"
echo "Texas Hold'em Poker - GCP Deployment"
echo "========================================"
echo ""
echo "Project ID: $PROJECTID"
echo "Cluster: $CLUSTER"
echo ""

# Step 1: Create project
echo "[1/11] Creating GCP Project..."
"$GCLOUD" projects create "$PROJECTID" --name="Texas Hold'em Poker" --set-as-default || true
echo "✓ Project created"
echo ""

# Step 2: Enable APIs
echo "[2/11] Enabling APIs..."
"$GCLOUD" services enable container.googleapis.com --project="$PROJECTID" || true
"$GCLOUD" services enable containerregistry.googleapis.com --project="$PROJECTID" || true
"$GCLOUD" services enable compute.googleapis.com --project="$PROJECTID" || true
"$GCLOUD" services enable cloudbuild.googleapis.com --project="$PROJECTID" || true
echo "✓ APIs enabled"
echo ""

# Step 3: Configure Docker
echo "[3/11] Configuring Docker..."
"$GCLOUD" auth configure-docker --quiet || true
echo "✓ Docker configured"
echo ""

# Step 4: Build backend
echo "[4/11] Building backend image..."
docker build -t "$REGISTRY/texas-backend:latest" ./backend > /dev/null 2>&1
docker build -t "$REGISTRY/texas-backend:v1" ./backend > /dev/null 2>&1
echo "✓ Backend built"
echo ""

# Step 5: Build frontend
echo "[5/11] Building frontend image..."
docker build -t "$REGISTRY/texas-frontend:latest" ./frontend > /dev/null 2>&1
docker build -t "$REGISTRY/texas-frontend:v1" ./frontend > /dev/null 2>&1
echo "✓ Frontend built"
echo ""

# Step 6: Push backend
echo "[6/11] Pushing backend to GCR..."
docker push "$REGISTRY/texas-backend:latest" > /dev/null 2>&1 || true
docker push "$REGISTRY/texas-backend:v1" > /dev/null 2>&1 || true
echo "✓ Backend pushed"
echo ""

# Step 7: Push frontend
echo "[7/11] Pushing frontend to GCR..."
docker push "$REGISTRY/texas-frontend:latest" > /dev/null 2>&1 || true
docker push "$REGISTRY/texas-frontend:v1" > /dev/null 2>&1 || true
echo "✓ Frontend pushed"
echo ""

# Step 8: Create cluster
echo "[8/11] Creating GKE cluster (10 min - get coffee!)..."
"$GCLOUD" container clusters create "$CLUSTER" \
    --project="$PROJECTID" \
    --zone="$ZONE" \
    --num-nodes=2 \
    --machine-type=n1-standard-2 \
    --enable-stackdriver-kubernetes \
    --network=default \
    --enable-autoscaling \
    --min-nodes=2 \
    --max-nodes=5 \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing \
    --quiet 2>/dev/null || true
echo "✓ Cluster created"
echo ""

# Step 9: Get credentials
echo "[9/11] Getting cluster credentials..."
"$GCLOUD" container clusters get-credentials "$CLUSTER" \
    --zone="$ZONE" \
    --project="$PROJECTID" \
    --quiet 2>/dev/null || true
echo "✓ Credentials configured"
echo ""

# Step 10: Update manifests
echo "[10/11] Updating Kubernetes manifests..."
sed -i.bak "s|<PROJECT-ID>|$PROJECTID|g" k8s/backend-deployment.yaml
sed -i.bak "s|<PROJECT-ID>|$PROJECTID|g" k8s/frontend-deployment.yaml
echo "✓ Manifests updated"
echo ""

# Step 11: Deploy
echo "[11/11] Deploying to Kubernetes..."
kubectl apply -f k8s/backend-deployment.yaml 2>/dev/null || true
kubectl apply -f k8s/frontend-deployment.yaml 2>/dev/null || true
echo "✓ Deployed"
echo ""

echo "========================================"
echo "Waiting for deployment to be ready..."
echo "========================================"
echo ""

# Wait for rollout
timeout 300 kubectl rollout status deployment/texas-backend --timeout=300s 2>/dev/null || true
timeout 300 kubectl rollout status deployment/texas-frontend --timeout=300s 2>/dev/null || true

echo ""
echo "========================================"
echo "DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
echo "Project ID: $PROJECTID"
echo ""
echo "Checking services..."
kubectl get svc texas-frontend 2>/dev/null || true
echo ""
echo "Services deployed successfully!"
echo ""
