#!/bin/bash

# Wrapper script to call gcloud.cmd from bash, avoiding Python alias issues

GCLOUD_PATH="/c/Users/yorda/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin"
GCLOUD_CMD="$GCLOUD_PATH/gcloud.cmd"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Project setup
PROJECTID="texas-poker-$(date +%s)"
REGION="us-central1"
ZONE="us-central1-a"
CLUSTER_NAME="poker-cluster"

print_header "Texas Hold'em Poker - GCP Deployment"
print_info "Project ID: $PROJECTID"
print_info "Region: $REGION"
print_info "Zone: $ZONE"

# Step 1: Create project
print_header "Step 1/8: Creating GCP Project"
"$GCLOUD_CMD" projects create "$PROJECTID" --name="Texas Hold'em Poker" --set-as-default
print_success "Project created: $PROJECTID"

# Step 2: Enable APIs
print_header "Step 2/8: Enabling APIs"
print_info "Enabling container.googleapis.com..."
"$GCLOUD_CMD" services enable container.googleapis.com --project="$PROJECTID"

print_info "Enabling containerregistry.googleapis.com..."
"$GCLOUD_CMD" services enable containerregistry.googleapis.com --project="$PROJECTID"

print_info "Enabling compute.googleapis.com..."
"$GCLOUD_CMD" services enable compute.googleapis.com --project="$PROJECTID"

print_info "Enabling cloudbuild.googleapis.com..."
"$GCLOUD_CMD" services enable cloudbuild.googleapis.com --project="$PROJECTID"

print_success "All APIs enabled"

# Step 3: Configure Docker
print_header "Step 3/8: Configuring Docker"
"$GCLOUD_CMD" auth configure-docker --quiet
print_success "Docker configured"

# Step 4: Build and push images
print_header "Step 4/8: Building and Pushing Docker Images"
REGISTRY="gcr.io/$PROJECTID"
BACKEND_IMAGE="$REGISTRY/texas-backend"
FRONTEND_IMAGE="$REGISTRY/texas-frontend"

print_info "Building backend..."
docker build -t "$BACKEND_IMAGE:latest" ./backend
docker build -t "$BACKEND_IMAGE:v1" ./backend

print_info "Building frontend..."
docker build -t "$FRONTEND_IMAGE:latest" ./frontend
docker build -t "$FRONTEND_IMAGE:v1" ./frontend

print_info "Pushing backend..."
docker push "$BACKEND_IMAGE:latest"
docker push "$BACKEND_IMAGE:v1"

print_info "Pushing frontend..."
docker push "$FRONTEND_IMAGE:latest"
docker push "$FRONTEND_IMAGE:v1"

print_success "Docker images pushed to GCR"

# Step 5: Create GKE cluster
print_header "Step 5/8: Creating GKE Cluster"
print_info "This may take 5-10 minutes..."

"$GCLOUD_CMD" container clusters create "$CLUSTER_NAME" \
    --project="$PROJECTID" \
    --zone="$ZONE" \
    --num-nodes=2 \
    --machine-type=n1-standard-2 \
    --enable-stackdriver-kubernetes \
    --enable-ip-alias \
    --network="default" \
    --enable-autoscaling \
    --min-nodes=2 \
    --max-nodes=5 \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing

print_success "GKE cluster created"

# Step 6: Get credentials
print_header "Step 6/8: Getting Cluster Credentials"
"$GCLOUD_CMD" container clusters get-credentials "$CLUSTER_NAME" \
    --zone="$ZONE" \
    --project="$PROJECTID"
print_success "Cluster credentials configured"

# Step 7: Update manifests
print_header "Step 7/8: Updating Kubernetes Manifests"

# Update backend manifest
if [ -f "k8s/backend-deployment.yaml" ]; then
    sed -i.bak "s|<PROJECT-ID>|$PROJECTID|g" k8s/backend-deployment.yaml
    print_success "Backend manifest updated"
else
    print_error "backend-deployment.yaml not found"
fi

# Update frontend manifest
if [ -f "k8s/frontend-deployment.yaml" ]; then
    sed -i.bak "s|<PROJECT-ID>|$PROJECTID|g" k8s/frontend-deployment.yaml
    print_success "Frontend manifest updated"
else
    print_error "frontend-deployment.yaml not found"
fi

# Step 8: Deploy
print_header "Step 8/8: Deploying to Kubernetes"
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
print_success "Kubernetes manifests deployed"

# Wait for rollout
print_info "Waiting for backend deployment..."
kubectl rollout status deployment/texas-backend --timeout=5m
print_success "Backend ready"

print_info "Waiting for frontend deployment..."
kubectl rollout status deployment/texas-frontend --timeout=5m
print_success "Frontend ready"

# Get info
print_header "Deployment Complete!"
print_info "Project ID: $PROJECTID"
print_info "Region: $REGION"
print_info "Cluster: $CLUSTER_NAME"
echo ""

print_info "Backend Service:"
kubectl get svc texas-backend

echo ""
print_info "Frontend Service:"
kubectl get svc texas-frontend

echo ""
print_info "All Pods:"
kubectl get pods

echo ""
print_header "Access Your Application"
echo "Visit: http://<EXTERNAL-IP>"
echo "(Copy the IP from the EXTERNAL-IP field above)"
echo ""

print_success "Deployment finished successfully! 🎉"
