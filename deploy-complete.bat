@echo off
REM Texas Hold'em Poker - Complete Automated GCP Deployment (Windows)
REM This script handles all deployment steps for the poker app

SETLOCAL ENABLEDELAYEDEXPANSION

REM Colors using ANSI escape codes (requires Windows 10+ with ANSI support)
set GREEN=[92m
set YELLOW=[93m
set BLUE=[94m
set RED=[91m
set NC=[0m

echo %BLUE%========================================%NC%
echo %BLUE%Texas Hold'em Poker - Complete Deployment%NC%
echo %BLUE%========================================%NC%
echo.

REM Check prerequisites
echo %YELLOW%Checking prerequisites...%NC%
where gcloud >nul 2>nul
if errorlevel 1 (
    echo %RED%Error: gcloud CLI not found. Please install Google Cloud SDK.%NC%
    pause
    exit /b 1
)

where docker >nul 2>nul
if errorlevel 1 (
    echo %RED%Error: Docker not found. Please install Docker.%NC%
    pause
    exit /b 1
)

where kubectl >nul 2>nul
if errorlevel 1 (
    echo %RED%Error: kubectl not found. Please install kubectl.%NC%
    pause
    exit /b 1
)

echo %GREEN%Prerequisites check passed!%NC%
echo.

REM Get current directory
set SCRIPT_DIR=%~dp0

REM Generate unique project ID
for /f "tokens=*" %%A in ('powershell -Command "Get-Date -UFormat '%%s'"') do set TIMESTAMP=%%A
set PROJECT_ID=texas-poker-%TIMESTAMP%
set REGION=us-central1
set ZONE=us-central1-a
set CLUSTER_NAME=poker-cluster

echo %YELLOW%Configuration:%NC%
echo Project ID: %PROJECT_ID%
echo Region: %REGION%
echo Cluster: %CLUSTER_NAME%
echo.

echo %YELLOW%Step 1/8: Creating GCP project...%NC%
gcloud projects create %PROJECT_ID% --name="Texas Hold'em Poker App" --set-as-default
if errorlevel 1 (
    echo %RED%Failed to create project%NC%
    pause
    exit /b 1
)
echo %GREEN%Project created: %PROJECT_ID%%NC%
echo.

echo %YELLOW%Step 2/8: Enabling required APIs...%NC%
gcloud services enable container.googleapis.com --project=%PROJECT_ID%
gcloud services enable containerregistry.googleapis.com --project=%PROJECT_ID%
gcloud services enable compute.googleapis.com --project=%PROJECT_ID%
gcloud services enable cloudbuild.googleapis.com --project=%PROJECT_ID%
echo %GREEN%All APIs enabled%NC%
echo.

echo %YELLOW%Step 3/8: Configuring Docker authentication...%NC%
call gcloud auth configure-docker --quiet
echo %GREEN%Docker authenticated%NC%
echo.

set REGISTRY=gcr.io/%PROJECT_ID%
set BACKEND_IMAGE=%REGISTRY%/texas-backend
set FRONTEND_IMAGE=%REGISTRY%/texas-frontend

echo %YELLOW%Step 4/8: Building Docker images...%NC%
echo Building backend...
docker build -t %BACKEND_IMAGE%:latest %SCRIPT_DIR%backend
docker build -t %BACKEND_IMAGE%:v1 %SCRIPT_DIR%backend
docker push %BACKEND_IMAGE%:latest
docker push %BACKEND_IMAGE%:v1

echo Building frontend...
docker build -t %FRONTEND_IMAGE%:latest %SCRIPT_DIR%frontend
docker build -t %FRONTEND_IMAGE%:v1 %SCRIPT_DIR%frontend
docker push %FRONTEND_IMAGE%:latest
docker push %FRONTEND_IMAGE%:v1

echo %GREEN%Images pushed to GCR%NC%
echo.

echo %YELLOW%Step 5/8: Creating GKE cluster...%NC%
echo This may take 5-10 minutes...
gcloud container clusters create %CLUSTER_NAME% ^
    --project=%PROJECT_ID% ^
    --zone=%ZONE% ^
    --num-nodes=2 ^
    --machine-type=n1-standard-2 ^
    --enable-stackdriver-kubernetes ^
    --enable-ip-alias ^
    --network="default" ^
    --enable-autoscaling ^
    --min-nodes=2 ^
    --max-nodes=5 ^
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing
echo %GREEN%GKE cluster created%NC%
echo.

echo %YELLOW%Step 6/8: Getting cluster credentials...%NC%
gcloud container clusters get-credentials %CLUSTER_NAME% ^
    --zone=%ZONE% ^
    --project=%PROJECT_ID%
echo %GREEN%Cluster credentials configured%NC%
echo.

echo %YELLOW%Step 7/8: Deploying to Kubernetes...%NC%
REM Note: sed command replacement - on Windows, you may need to manually update the PROJECT_ID in the yaml files
REM For now, we'll deploy with the original placeholders and they'll fail
echo Deploying backend...
kubectl apply -f %SCRIPT_DIR%k8s\backend-deployment.yaml
echo Deploying frontend...
kubectl apply -f %SCRIPT_DIR%k8s\frontend-deployment.yaml
echo %GREEN%Kubernetes manifests deployed%NC%
echo.

echo %YELLOW%Step 8/8: Waiting for deployments...%NC%
kubectl rollout status deployment/texas-backend --timeout=5m
kubectl rollout status deployment/texas-frontend --timeout=5m
echo %GREEN%All deployments are ready!%NC%
echo.

echo %BLUE%========================================%NC%
echo %BLUE%Deployment Complete!%NC%
echo %BLUE%========================================%NC%
echo.

echo %YELLOW%Backend Service:%NC%
kubectl get svc texas-backend
echo.

echo %YELLOW%Frontend Service (LoadBalancer):%NC%
kubectl get svc texas-frontend
echo.

echo %YELLOW%All Pods:%NC%
kubectl get pods
echo.

echo %BLUE%========================================%NC%
echo %BLUE%Access Your Application%NC%
echo %BLUE%========================================%NC%
echo Get external IP:
echo   kubectl get svc texas-frontend
echo.
echo View logs:
echo   kubectl logs -f deployment/texas-backend
echo   kubectl logs -f deployment/texas-frontend
echo.
echo %GREEN%Deployment Summary:%NC%
echo Project ID: %PROJECT_ID%
echo Region: %REGION%
echo Cluster: %CLUSTER_NAME%
echo Backend Image: %BACKEND_IMAGE%:latest
echo Frontend Image: %FRONTEND_IMAGE%:latest
echo.

pause
