@echo off
REM Texas Hold'em Poker - Automated GCP Deployment
REM Full deployment in one script

setlocal enabledelayedexpansion

REM Configuration - Use quotes for path with spaces
set "GCLOUD=C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
set PROJECTID=texas-poker-%RANDOM%-%RANDOM%
set CLUSTER=poker-cluster
set ZONE=us-central1-a
set REGISTRY=gcr.io/%PROJECTID%

cls
echo.
echo ========================================
echo   Texas Hold'em Poker - GCP Deploy
echo ========================================
echo.
echo Project ID: %PROJECTID%
echo Cluster: %CLUSTER%
echo.
echo Press any key to start deployment...
pause >nul

REM Step 1
echo.
echo [1/11] Creating GCP Project...
"%GCLOUD%" projects create %PROJECTID% --name="Texas Hold'em Poker" --set-as-default
echo.

REM Step 2
echo [2/11] Enabling APIs...
"%GCLOUD%" services enable container.googleapis.com --project=%PROJECTID%
"%GCLOUD%" services enable containerregistry.googleapis.com --project=%PROJECTID%
"%GCLOUD%" services enable compute.googleapis.com --project=%PROJECTID%
"%GCLOUD%" services enable cloudbuild.googleapis.com --project=%PROJECTID%
echo.

REM Step 3
echo [3/11] Configuring Docker...
"%GCLOUD%" auth configure-docker --quiet
echo.

REM Step 4
echo [4/11] Building backend image (takes 5 minutes)...
docker build -t %REGISTRY%/texas-backend:latest .\backend
docker build -t %REGISTRY%/texas-backend:v1 .\backend
echo.

REM Step 5
echo [5/11] Building frontend image (takes 5 minutes)...
docker build -t %REGISTRY%/texas-frontend:latest .\frontend
docker build -t %REGISTRY%/texas-frontend:v1 .\frontend
echo.

REM Step 6
echo [6/11] Pushing backend to GCR...
docker push %REGISTRY%/texas-backend:latest
docker push %REGISTRY%/texas-backend:v1
echo.

REM Step 7
echo [7/11] Pushing frontend to GCR...
docker push %REGISTRY%/texas-frontend:latest
docker push %REGISTRY%/texas-frontend:v1
echo.

REM Step 8
echo [8/11] Creating GKE cluster (takes 10 minutes - get coffee!)...
"%GCLOUD%" container clusters create %CLUSTER% ^
    --project=%PROJECTID% ^
    --zone=%ZONE% ^
    --num-nodes=2 ^
    --machine-type=n1-standard-2 ^
    --enable-stackdriver-kubernetes ^
    --network=default ^
    --enable-autoscaling ^
    --min-nodes=2 ^
    --max-nodes=5 ^
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing
echo.

REM Step 9
echo [9/11] Getting cluster credentials...
"%GCLOUD%" container clusters get-credentials %CLUSTER% ^
    --zone=%ZONE% ^
    --project=%PROJECTID%
echo.

REM Step 10
echo [10/11] Updating Kubernetes manifests...
powershell -Command "(Get-Content k8s\backend-deployment.yaml) -replace '<PROJECT-ID>', '%PROJECTID%' | Set-Content k8s\backend-deployment.yaml"
powershell -Command "(Get-Content k8s\frontend-deployment.yaml) -replace '<PROJECT-ID>', '%PROJECTID%' | Set-Content k8s\frontend-deployment.yaml"
echo.

REM Step 11
echo [11/11] Deploying to Kubernetes...
kubectl apply -f k8s\backend-deployment.yaml
kubectl apply -f k8s\frontend-deployment.yaml
echo.

echo ========================================
echo Waiting for deployment to be ready...
echo ========================================
echo.
kubectl rollout status deployment/texas-backend --timeout=300s
kubectl rollout status deployment/texas-frontend --timeout=300s

echo.
echo ========================================
echo DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Project ID: %PROJECTID%
echo.
echo Services status:
kubectl get svc texas-frontend
echo.
echo Your app URL: http://^<EXTERNAL-IP^>
echo (Get EXTERNAL-IP from output above)
echo.
pause
