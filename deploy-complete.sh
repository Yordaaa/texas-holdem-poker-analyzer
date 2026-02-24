#!/bin/bash

################################################################################
# Texas Hold'em Poker - Complete Automated GCP Deployment
# This script will:
# 1. Create a new GCP project
# 2. Enable all required APIs
# 3. Build Docker images
# 4. Push to Google Container Registry
# 5. Create GKE cluster
# 6. Deploy to Kubernetes
# 7. Expose frontend via LoadBalancer
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
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

# Main deployment
main() {
    print_header "Texas Hold'em Poker - Complete Deployment"

    # Step 1: Get user input
    print_info "Step 1/8: Gathering configuration..."
    
    # Generate project ID
    TIMESTAMP=$(date +%s)
    PROJECT_NAME="texas-poker-${TIMESTAMP}"
    PROJECT_ID="${PROJECT_NAME}"
    REGION="us-central1"
    ZONE="${REGION}-a"
    CLUSTER_NAME="poker-cluster"
    
    print_info "Project ID: ${PROJECT_ID}"
    print_info "Region: ${REGION}"
    print_info "Cluster: ${CLUSTER_NAME}"
    
    # Step 2: Create GCP project
    print_info "Step 2/8: Creating GCP project..."
    gcloud projects create ${PROJECT_ID} \
        --name="Texas Hold'em Poker App" \
        --set-as-default
    print_success "Project created: ${PROJECT_ID}"
    
    # Step 3: Enable required APIs
    print_info "Step 3/8: Enabling required APIs..."
    gcloud services enable container.googleapis.com \
        --project=${PROJECT_ID}
    gcloud services enable containerregistry.googleapis.com \
        --project=${PROJECT_ID}
    gcloud services enable compute.googleapis.com \
        --project=${PROJECT_ID}
    gcloud services enable cloudbuild.googleapis.com \
        --project=${PROJECT_ID}
    print_success "All APIs enabled"
    
    # Step 4: Configure Docker authentication
    print_info "Step 4/8: Configuring Docker authentication..."
    gcloud auth configure-docker --quiet
    print_success "Docker authenticated"
    
    # Step 5: Build and push Docker images
    print_info "Step 5/8: Building and pushing Docker images..."
    
    REGISTRY="gcr.io/${PROJECT_ID}"
    BACKEND_IMAGE="${REGISTRY}/texas-backend"
    FRONTEND_IMAGE="${REGISTRY}/texas-frontend"
    
    print_info "Building backend image..."
    docker build -t ${BACKEND_IMAGE}:latest ./backend
    docker build -t ${BACKEND_IMAGE}:v1 ./backend
    
    print_info "Building frontend image..."
    docker build -t ${FRONTEND_IMAGE}:latest ./frontend
    docker build -t ${FRONTEND_IMAGE}:v1 ./frontend
    
    print_info "Pushing backend image to GCR..."
    docker push ${BACKEND_IMAGE}:latest
    docker push ${BACKEND_IMAGE}:v1
    
    print_info "Pushing frontend image to GCR..."
    docker push ${FRONTEND_IMAGE}:latest
    docker push ${FRONTEND_IMAGE}:v1
    
    print_success "Docker images pushed to GCR"
    
    # Step 6: Create GKE cluster
    print_info "Step 6/8: Creating GKE cluster..."
    gcloud container clusters create ${CLUSTER_NAME} \
        --project=${PROJECT_ID} \
        --zone=${ZONE} \
        --num-nodes=2 \
        --machine-type=n1-standard-2 \
        --enable-stackdriver-kubernetes \
        --enable-ip-alias \
        --network="default" \
        --enable-autoscaling \
        --min-nodes=2 \
        --max-nodes=5 \
        --addons=HorizontalPodAutoscaling,HttpLoadBalancing \
        --workload-pool=${PROJECT_ID}.svc.id.goog
    
    print_success "GKE cluster created"
    
    # Step 7: Get cluster credentials
    print_info "Step 7/8: Getting cluster credentials..."
    gcloud container clusters get-credentials ${CLUSTER_NAME} \
        --zone=${ZONE} \
        --project=${PROJECT_ID}
    print_success "Cluster credentials configured"
    
    # Step 8: Deploy to Kubernetes
    print_info "Step 8/8: Deploying to Kubernetes..."
    
    # Update K8s manifests with correct PROJECT_ID
    sed -i.bak "s|<PROJECT-ID>|${PROJECT_ID}|g" ./k8s/backend-deployment.yaml
    sed -i.bak "s|<PROJECT-ID>|${PROJECT_ID}|g" ./k8s/frontend-deployment.yaml
    
    # Apply deployments
    kubectl apply -f ./k8s/backend-deployment.yaml
    kubectl apply -f ./k8s/frontend-deployment.yaml
    
    print_success "Kubernetes manifests deployed"
    
    # Wait for deployments
    print_info "Waiting for deployments to be ready (this may take 2-3 minutes)..."
    kubectl rollout status deployment/texas-backend --timeout=5m
    kubectl rollout status deployment/texas-frontend --timeout=5m
    
    print_success "All deployments are ready!"
    
    # Get service information
    print_header "Deployment Complete!"
    
    print_info "Backend Service:"
    kubectl get svc texas-backend
    
    print_info "Frontend Service (LoadBalancer):"
    kubectl get svc texas-frontend
    
    print_info "All Pods:"
    kubectl get pods
    
    # Get frontend URL
    print_info "Waiting for LoadBalancer external IP..."
    sleep 10
    
    EXTERNAL_IP=$(kubectl get svc texas-frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
    
    print_header "Access Your Application"
    print_success "Frontend URL: http://${EXTERNAL_IP}"
    print_success "Backend API: http://kubernetes.default.svc.cluster.local:8080"
    
    print_header "Quick Commands"
    echo "View logs:"
    echo "  kubectl logs -f deployment/texas-backend"
    echo "  kubectl logs -f deployment/texas-frontend"
    echo ""
    echo "Scale deployments:"
    echo "  kubectl scale deployment texas-backend --replicas=5"
    echo "  kubectl scale deployment texas-frontend --replicas=5"
    echo ""
    echo "Get updated external IP:"
    echo "  kubectl get svc texas-frontend"
    echo ""
    echo "Delete entire cluster:"
    echo "  gcloud container clusters delete ${CLUSTER_NAME} --zone ${ZONE}"
    echo "  gcloud projects delete ${PROJECT_ID}"
    echo ""
    
    print_header "Project Summary"
    echo "Project ID: ${PROJECT_ID}"
    echo "Region: ${REGION}"
    echo "Cluster: ${CLUSTER_NAME}"
    echo "Backend Image: ${BACKEND_IMAGE}:latest"
    echo "Frontend Image: ${FRONTEND_IMAGE}:latest"
    echo ""
    
    print_success "Deployment finished successfully!"
}

# Error handler
trap 'print_error "Deployment failed!"; exit 1' ERR

# Run main
main
