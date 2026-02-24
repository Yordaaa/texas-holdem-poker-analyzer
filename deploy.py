#!/usr/bin/env python3
import subprocess
import os
import sys
from datetime import datetime

# Colors
GREEN = '\033[92m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RED = '\033[91m'
NC = '\033[0m'

def print_header(text):
    print(f"\n{BLUE}{'='*50}{NC}")
    print(f"{BLUE}{text}{NC}")
    print(f"{BLUE}{'='*50}{NC}\n")

def print_success(text):
    print(f"{GREEN}✓ {text}{NC}")

def print_error(text):
    print(f"{RED}✗ {text}{NC}")

def print_info(text):
    print(f"{YELLOW}ℹ {text}{NC}")

def run_command(cmd, description=""):
    """Run a shell command and handle errors"""
    if description:
        print_info(description)
    try:
        result = subprocess.run(cmd, shell=True, check=True, capture_output=False, text=True)
        return True
    except subprocess.CalledProcessError as e:
        if description:
            print_error(f"Failed: {description}")
        print_error(f"Command failed with exit code {e.returncode}")
        return False
    except Exception as e:
        print_error(f"Error: {e}")
        return False

def main():
    print_header("Texas Hold'em Poker - GCP Deployment")
    
    # Change to project directory
    os.chdir(r'C:\Users\yorda\OneDrive\Desktop\Texas Hold\'em poker')
    
    # Generate unique project ID
    timestamp = str(int(datetime.now().timestamp()))
    project_id = f"texas-poker-{timestamp}"
    region = "us-central1"
    zone = "us-central1-a"
    cluster_name = "poker-cluster"
    
    print_info(f"Project ID: {project_id}")
    print_info(f"Region: {region}")
    print_info(f"Cluster: {cluster_name}\n")
    
    # Step 1: Create project
    print_header("Step 1/8: Creating GCP Project")
    gcloud_path = r"C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
    cmd = f'"{gcloud_path}" projects create {project_id} --name="Texas Hold\'em Poker" --set-as-default'
    if not run_command(cmd, "Creating project..."):
        print_error("Failed to create project")
        return
    print_success(f"Project created: {project_id}")
    
    # Step 2: Enable APIs
    print_header("Step 2/8: Enabling Required APIs")
    apis = [
        "container.googleapis.com",
        "containerregistry.googleapis.com",
        "compute.googleapis.com",
        "cloudbuild.googleapis.com"
    ]
    for api in apis:
        cmd = f'"{gcloud_path}" services enable {api} --project={project_id}'
        run_command(cmd, f"Enabling {api}...")
    print_success("All APIs enabled")
    
    # Step 3: Configure Docker
    print_header("Step 3/8: Configuring Docker")
    cmd = f'"{gcloud_path}" auth configure-docker --quiet'
    run_command(cmd, "Configuring Docker...")
    print_success("Docker configured")
    
    # Step 4: Build images
    print_header("Step 4/8: Building Docker Images")
    registry = f"gcr.io/{project_id}"
    backend_image = f"{registry}/texas-backend"
    frontend_image = f"{registry}/texas-frontend"
    
    print_info("Building backend image...")
    run_command(f"docker build -t {backend_image}:latest ./backend")
    run_command(f"docker build -t {backend_image}:v1 ./backend")
    
    print_info("Building frontend image...")
    run_command(f"docker build -t {frontend_image}:latest ./frontend")
    run_command(f"docker build -t {frontend_image}:v1 ./frontend")
    
    print_info("Pushing backend image...")
    run_command(f"docker push {backend_image}:latest")
    run_command(f"docker push {backend_image}:v1")
    
    print_info("Pushing frontend image...")
    run_command(f"docker push {frontend_image}:latest")
    run_command(f"docker push {frontend_image}:v1")
    
    print_success("Docker images pushed to GCR")
    
    # Step 5: Create GKE cluster
    print_header("Step 5/8: Creating GKE Cluster")
    print_info("This may take 5-10 minutes...")
    
    cmd = f'"{gcloud_path}" container clusters create {cluster_name} \
        --project={project_id} \
        --zone={zone} \
        --num-nodes=2 \
        --machine-type=n1-standard-2 \
        --enable-stackdriver-kubernetes \
        --enable-ip-alias \
        --network="default" \
        --enable-autoscaling \
        --min-nodes=2 \
        --max-nodes=5 \
        --addons=HorizontalPodAutoscaling,HttpLoadBalancing \
        --workload-pool={project_id}.svc.id.goog'
    
    if not run_command(cmd, "Creating cluster..."):
        print_error("Failed to create cluster")
        return
    print_success("GKE cluster created")
    
    # Step 6: Get credentials
    print_header("Step 6/8: Getting Cluster Credentials")
    cmd = f'"{gcloud_path}" container clusters get-credentials {cluster_name} \
        --zone={zone} \
        --project={project_id}'
    run_command(cmd, "Getting credentials...")
    print_success("Cluster credentials configured")
    
    # Step 7: Update manifests
    print_header("Step 7/8: Updating Kubernetes Manifests")
    
    # Read and update backend manifest
    with open('k8s\\backend-deployment.yaml', 'r') as f:
        backend_yaml = f.read().replace('<PROJECT-ID>', project_id)
    with open('k8s\\backend-deployment.yaml', 'w') as f:
        f.write(backend_yaml)
    
    # Read and update frontend manifest
    with open('k8s\\frontend-deployment.yaml', 'r') as f:
        frontend_yaml = f.read().replace('<PROJECT-ID>', project_id)
    with open('k8s\\frontend-deployment.yaml', 'w') as f:
        f.write(frontend_yaml)
    
    print_success("Manifests updated with project ID")
    
    # Step 8: Deploy to Kubernetes
    print_header("Step 8/8: Deploying to Kubernetes")
    
    run_command("kubectl apply -f k8s\\backend-deployment.yaml", "Deploying backend...")
    run_command("kubectl apply -f k8s\\frontend-deployment.yaml", "Deploying frontend...")
    print_success("Kubernetes manifests deployed")
    
    # Wait for rollout
    print_info("Waiting for backend deployment (this may take 2-3 minutes)...")
    run_command("kubectl rollout status deployment/texas-backend --timeout=5m")
    
    print_info("Waiting for frontend deployment...")
    run_command("kubectl rollout status deployment/texas-frontend --timeout=5m")
    
    print_success("All deployments are ready!")
    
    # Get service info
    print_header("Deployment Summary")
    print(f"Project ID: {project_id}")
    print(f"Region: {region}")
    print(f"Cluster: {cluster_name}")
    print(f"Backend Image: {backend_image}:latest")
    print(f"Frontend Image: {frontend_image}:latest")
    print()
    
    print_info("Frontend Service:")
    run_command("kubectl get svc texas-frontend")
    
    print_info("\nAll Pods:")
    run_command("kubectl get pods")
    
    print_header("Access Your Application")
    print(f"{YELLOW}Visit: http://<EXTERNAL-IP>{NC}")
    print(f"{YELLOW}(Replace <EXTERNAL-IP> with the IP from 'kubectl get svc texas-frontend' above){NC}")
    print()
    print(GREEN + "Deployment Complete! 🎉" + NC)

if __name__ == "__main__":
    main()
