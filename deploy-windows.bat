@echo off
REM Manual GCP Deployment - Copy each command and run in Command Prompt
REM This avoids the Python alias issue

setlocal enabledelayedexpansion

REM Set your Google Cloud SDK path
set "GCLOUD=C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"

REM Verify gcloud works
echo Checking gcloud installation...
%GCLOUD% --version
if errorlevel 1 (
    echo ERROR: gcloud not accessible. Please install Google Cloud SDK.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Step 1: Creating GCP Project
echo ========================================
REM Generate unique project ID
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do (set mydate=%%d%%b%%a)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set PROJECTID=texas-poker-%mydate%%mytime%
echo Project ID: %PROJECTID%

%GCLOUD% projects create %PROJECTID% --name="Texas Hold'em Poker App" --set-as-default
if errorlevel 1 (
    echo ERROR: Failed to create project
    pause
    exit /b 1
)
echo ✓ Project created

echo.
echo ========================================
echo Step 2: Enabling Required APIs
echo ========================================
%GCLOUD% services enable container.googleapis.com --project=%PROJECTID%
%GCLOUD% services enable containerregistry.googleapis.com --project=%PROJECTID%
%GCLOUD% services enable compute.googleapis.com --project=%PROJECTID%
%GCLOUD% services enable cloudbuild.googleapis.com --project=%PROJECTID%
echo ✓ APIs enabled

echo.
echo ========================================
echo Step 3: Configuring Docker
echo ========================================
%GCLOUD% auth configure-docker --quiet
echo ✓ Docker authenticated

echo.
echo ========================================
echo Step 4: Building Docker Images
echo ========================================
set REGISTRY=gcr.io/%PROJECTID%
set BACKEND_IMAGE=%REGISTRY%/texas-backend
set FRONTEND_IMAGE=%REGISTRY%/texas-frontend

cd /d "C:\Users\yorda\OneDrive\Desktop\Texas Hold'em poker"

echo Building backend image...
docker build -t %BACKEND_IMAGE%:latest .\backend
docker build -t %BACKEND_IMAGE%:v1 .\backend

echo Building frontend image...
docker build -t %FRONTEND_IMAGE%:latest .\frontend
docker build -t %FRONTEND_IMAGE%:v1 .\frontend

echo Pushing backend image...
docker push %BACKEND_IMAGE%:latest
docker push %BACKEND_IMAGE%:v1

echo Pushing frontend image...
docker push %FRONTEND_IMAGE%:latest
docker push %FRONTEND_IMAGE%:v1

echo ✓ Docker images pushed

echo.
echo ========================================
echo Step 5: Creating GKE Cluster
echo ========================================
echo This may take 5-10 minutes...

%GCLOUD% container clusters create poker-cluster ^
    --project=%PROJECTID% ^
    --zone=us-central1-a ^
    --num-nodes=2 ^
    --machine-type=n1-standard-2 ^
    --enable-stackdriver-kubernetes ^
    --network="default" ^
    --enable-autoscaling ^
    --min-nodes=2 ^
    --max-nodes=5 ^
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing

if errorlevel 1 (
    echo ERROR: Failed to create cluster
    pause
    exit /b 1
)
echo ✓ GKE cluster created

echo.
echo ========================================
echo Step 6: Getting Cluster Credentials
echo ========================================
%GCLOUD% container clusters get-credentials poker-cluster ^
    --zone=us-central1-a ^
    --project=%PROJECTID%
echo ✓ Cluster credentials configured

echo.
echo ========================================
echo Step 7: Updating Kubernetes Manifests
echo ========================================
REM Update the K8s manifests with correct project ID
for /f "delims=" %%i in ('type k8s\backend-deployment.yaml') do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    set "line=!line:<PROJECT-ID>=%PROJECTID%!"
    echo !line!
    endlocal
) > k8s\backend-deployment-updated.yaml

for /f "delims=" %%i in ('type k8s\frontend-deployment.yaml') do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    set "line=!line:<PROJECT-ID>=%PROJECTID%!"
    echo !line!
    endlocal
) > k8s\frontend-deployment-updated.yaml

echo ✓ Manifests updated

echo.
echo ========================================
echo Step 8: Deploying to Kubernetes
echo ========================================
kubectl apply -f k8s\backend-deployment-updated.yaml
kubectl apply -f k8s\frontend-deployment-updated.yaml

echo Waiting for deployments (5-10 minutes)...
kubectl rollout status deployment/texas-backend --timeout=600s
kubectl rollout status deployment/texas-frontend --timeout=600s

echo.
echo ========================================
echo DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Project ID: %PROJECTID%
echo Region: us-central1
echo Cluster: poker-cluster
echo.
echo Getting service information...
kubectl get svc texas-frontend

echo.
echo Waiting for external IP (may take a few moments)...
timeout /t 10 /nobreak

echo.
echo Final status:
kubectl get svc texas-frontend
kubectl get pods

echo.
echo Your app URL (check EXTERNAL-IP above):
echo http://^<EXTERNAL-IP^>
echo.
pause
