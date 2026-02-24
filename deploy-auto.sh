#!/bin/bash

# Automated GCP Deployment for Texas Hold'em Poker
# This script handles all deployment steps

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECTID="texas-poker-$(date +%s)"
REGION="us-central1"
ZONE="us-central1-a"
CLUSTER="poker-cluster"
GCLOUD="/c/Users/yorda/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin/gcloud.cmd"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}TX Hold'em Poker - GCP Deploy${NC}"
echo -e "${BLUE}================================${NC}\n"

echo -e "${YELLOW}Project ID: $PROJECTID${NC}"
echo -e "${YELLOW}Region: $REGION${NC}"
echo -e "${YELLOW}Cluster: $CLUSTER${NC}\n"

# Step 1: Create project
echo -e "${BLUE}[1/10] Creating GCP Project...${NC}"
"$GCLOUD" projects create "$PROJECTID" --name="Texas Hold'em Poker" --set-as-default 2>/dev/null || true
echo -e "${GREEN}✓ Project created${NC}\n"

# Step 2: Enable APIs
echo -e "${BLUE}[2/10] Enabling APIs...${NC}"
"$GCLOUD" services enable container.googleapis.com --project="$PROJECTID" 2>/dev/null || true
"$GCLOUD" services enable containerregistry.googleapis.com --project="$PROJECTID" 2>/dev/null || true
"$GCLOUD" services enable compute.googleapis.com --project="$PROJECTID" 2>/dev/null || true
"$GCLOUD" services enable cloudbuild.googleapis.com --project="$PROJECTID" 2>/dev/null || true
echo -e "${GREEN}✓ APIs enabled${NC}\n"

# Step 3: Configure Docker
echo -e "${BLUE}[3/10] Configuring Docker...${NC}"
"$GCLOUD" auth configure-docker --quiet 2>/dev/null || true
echo -e "${GREEN}✓ Docker configured${NC}\n"

# Step 4-5: Build images
REGISTRY="gcr.io/$PROJECTID"
BACKEND="$REGISTRY/texas-backend"
FRONTEND="$REGISTRY/texas-frontend"

echo -e "${BLUE}[4/10] Building backend image...${NC}"
docker build -t "$BACKEND:latest" ./backend > /dev/null 2>&1
docker build -t "$BACKEND:v1" ./backend > /dev/null 2>&1
echo -e "${GREEN}✓ Backend built${NC}\n"

echo -e "${BLUE}[5/10] Building frontend image...${NC}"
docker build -t "$FRONTEND:latest" ./frontend > /dev/null 2>&1
docker build -t "$FRONTEND:v1" ./frontend > /dev/null 2>&1
echo -e "${GREEN}✓ Frontend built${NC}\n"

# Step 6: Push images
echo -e "${BLUE}[6/10] Pushing images to GCR...${NC}"
docker push "$BACKEND:latest" > /dev/null 2>&1 &
docker push "$BACKEND:v1" > /dev/null 2>&1 &
docker push "$FRONTEND:latest" > /dev/null 2>&1 &
docker push "$FRONTEND:v1" > /dev/null 2>&1
wait
echo -e "${GREEN}✓ Images pushed${NC}\n"

# Step 7: Create cluster
echo -e "${BLUE}[7/10] Creating GKE cluster (takes ~10 min)...${NC}"
"$GCLOUD" container clusters create "$CLUSTER" \
    --project="$PROJECTID" \
    --zone="$ZONE" \
    --num-nodes=2 \
    --machine-type=n1-standard-2 \
    --enable-stackdriver-kubernetes \
    --network="default" \
    --enable-autoscaling \
    --min-nodes=2 \
    --max-nodes=5 \
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing \
    --quiet 2>/dev/null || true
echo -e "${GREEN}✓ Cluster created${NC}\n"

# Step 8: Get credentials
echo -e "${BLUE}[8/10] Getting cluster credentials...${NC}"
"$GCLOUD" container clusters get-credentials "$CLUSTER" \
    --zone="$ZONE" \
    --project="$PROJECTID" \
    --quiet 2>/dev/null || true
echo -e "${GREEN}✓ Credentials configured${NC}\n"

# Step 9: Update manifests
echo -e "${BLUE}[9/10] Updating K8s manifests...${NC}"
if [ -f "k8s/backend-deployment.yaml" ]; then
    sed -i.bak "s|<PROJECT-ID>|$PROJECTID|g" k8s/backend-deployment.yaml
fi
if [ -f "k8s/frontend-deployment.yaml" ]; then
    sed -i.bak "s|<PROJECT-ID>|$PROJECTID|g" k8s/frontend-deployment.yaml
fi
echo -e "${GREEN}✓ Manifests updated${NC}\n"

# Step 10: Deploy
echo -e "${BLUE}[10/10] Deploying to Kubernetes...${NC}"
kubectl apply -f k8s/backend-deployment.yaml > /dev/null 2>&1 || true
kubectl apply -f k8s/frontend-deployment.yaml > /dev/null 2>&1 || true
echo -e "${GREEN}✓ Deployed${NC}\n"

# Wait for rollout
echo -e "${YELLOW}Waiting for deployment to be ready...${NC}"
timeout 300 kubectl rollout status deployment/texas-backend --timeout=300s 2>/dev/null || true
timeout 300 kubectl rollout status deployment/texas-frontend --timeout=300s 2>/dev/null || true

echo -e "\n${BLUE}================================${NC}"
echo -e "${BLUE}DEPLOYMENT COMPLETE!${NC}"
echo -e "${BLUE}================================${NC}\n"

echo -e "${YELLOW}Project Details:${NC}"
echo "  Project ID: $PROJECTID"
echo "  Region: $REGION"
echo "  Cluster: $CLUSTER"
echo "  Backend: $BACKEND:latest"
echo "  Frontend: $FRONTEND:latest"
echo ""

echo -e "${YELLOW}Check cluster status:${NC}"
kubectl get svc texas-frontend
echo ""

echo -e "${YELLOW}Get your app URL from EXTERNAL-IP above (http://<EXTERNAL-IP>)${NC}"
echo ""

echo -e "${GREEN}✓ Your Texas Hold'em Poker app is deploying!${NC}"
