#!/bin/bash

# Google Cloud Deployment Script for Texas Hold'em Poker App
# Prerequisites: gcloud CLI installed and authenticated

set -e

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project-id}"
REGION="${GCP_REGION:-us-central1}"
REGISTRY_URL="gcr.io/${PROJECT_ID}"
BACKEND_IMAGE="${REGISTRY_URL}/texas-backend"
FRONTEND_IMAGE="${REGISTRY_URL}/texas-frontend"
TAG="${TAG:-latest}"
CLUSTER_NAME="${CLUSTER_NAME:-poker-cluster}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Texas Hold'em Poker - GCP Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if PROJECT_ID is set
if [ "$PROJECT_ID" = "your-gcp-project-id" ]; then
    echo -e "${RED}Error: GCP_PROJECT_ID not set. Please export GCP_PROJECT_ID=<your-project-id>${NC}"
    exit 1
fi

echo -e "${YELLOW}Project ID: ${PROJECT_ID}${NC}"
echo -e "${YELLOW}Region: ${REGION}${NC}"
echo -e "${YELLOW}Tag: ${TAG}${NC}"

# Step 1: Configure gcloud
echo -e "${YELLOW}\n[1/6] Configuring gcloud...${NC}"
gcloud config set project ${PROJECT_ID}
gcloud auth configure-docker

# Step 2: Build backend image
echo -e "${YELLOW}\n[2/6] Building backend Docker image...${NC}"
docker build -t ${BACKEND_IMAGE}:${TAG} ./backend
docker build -t ${BACKEND_IMAGE}:latest ./backend

# Step 3: Build frontend image
echo -e "${YELLOW}\n[3/6] Building frontend Docker image...${NC}"
docker build -t ${FRONTEND_IMAGE}:${TAG} ./frontend
docker build -t ${FRONTEND_IMAGE}:latest ./frontend

# Step 4: Push images to GCR
echo -e "${YELLOW}\n[4/6] Pushing images to Google Container Registry...${NC}"
docker push ${BACKEND_IMAGE}:${TAG}
docker push ${BACKEND_IMAGE}:latest
docker push ${FRONTEND_IMAGE}:${TAG}
docker push ${FRONTEND_IMAGE}:latest

# Step 5: Create GKE cluster (if it doesn't exist)
echo -e "${YELLOW}\n[5/6] Checking GKE cluster...${NC}"
if ! gcloud container clusters describe ${CLUSTER_NAME} --zone ${REGION}-a &>/dev/null; then
    echo -e "${YELLOW}Creating GKE cluster: ${CLUSTER_NAME}${NC}"
    gcloud container clusters create ${CLUSTER_NAME} \
        --zone ${REGION}-a \
        --num-nodes 2 \
        --machine-type n1-standard-2 \
        --enable-stackdriver-kubernetes
else
    echo -e "${GREEN}GKE cluster ${CLUSTER_NAME} already exists${NC}"
fi

# Step 6: Get cluster credentials
echo -e "${YELLOW}\n[6/6] Getting cluster credentials...${NC}"
gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${REGION}-a

# Update K8s manifests with correct PROJECT_ID
echo -e "${YELLOW}Updating Kubernetes manifests...${NC}"
sed -i.bak "s/<PROJECT-ID>/${PROJECT_ID}/g" ./k8s/*.yaml

# Deploy to GKE
echo -e "${YELLOW}Deploying to GKE...${NC}"
kubectl apply -f ./k8s/

# Wait for rollout
echo -e "${YELLOW}Waiting for deployments to be ready...${NC}"
kubectl rollout status deployment/texas-backend -n default --timeout=5m
kubectl rollout status deployment/texas-frontend -n default --timeout=5m

# Get service information
echo -e "${GREEN}\n========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "${YELLOW}Backend Service:${NC}"
kubectl get svc texas-backend

echo -e "${YELLOW}Frontend Service (LoadBalancer):${NC}"
kubectl get svc texas-frontend

echo -e "${YELLOW}\nPods Status:${NC}"
kubectl get pods

echo -e "${GREEN}\nTo view logs:${NC}"
echo "kubectl logs -f deployment/texas-backend"
echo "kubectl logs -f deployment/texas-frontend"

echo -e "${GREEN}\nTo scale deployments:${NC}"
echo "kubectl scale deployment texas-backend --replicas=3"
echo "kubectl scale deployment texas-frontend --replicas=3"
