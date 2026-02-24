# 🚀 DEPLOYMENT CHECKLIST - Texas Hold'em Poker

## ✅ Pre-Flight Checklist

Before starting, verify everything is ready:

### 1. Docker Desktop Running?
```batch
docker ps
```
- ✅ Should show: "CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES" (even if empty)
- ❌ If error about "Docker daemon": Start Docker Desktop first!

### 2. Google Cloud SDK Ready?
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd auth list
```
- ✅ Should show: "yordanostibebu5@gmail.com" with ACTIVE status
- ❌ If not: Run `gcloud auth login`

### 3. kubectl Installed?
```batch
kubectl version --client
```
- ✅ Should show version number
- ❌ If not installed: Install from https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/

### 4. In Correct Directory?
```batch
cd C:\Users\yorda\OneDrive\Desktop\Texas Hold'em poker
dir
```
- ✅ Should show: backend, frontend, k8s, docker-compose.yml, etc.

---

## 🎯 Quick Deployment (Copy-Paste Ready)

### Step 0: Set Variables (RUN ONCE)
```batch
set PROJECTID=texas-poker-001
set REGION=us-central1
set ZONE=us-central1-a
set CLUSTER=poker-cluster
set REGISTRY=gcr.io/%PROJECTID%
set GCLOUD=C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd
```

### Step 1: Create Project
```batch
%GCLOUD% projects create %PROJECTID% --name="Texas Hold'em Poker" --set-as-default
```
✓ Wait for "Create completed"

### Step 2: Enable APIs
```batch
%GCLOUD% services enable container.googleapis.com --project=%PROJECTID%
%GCLOUD% services enable containerregistry.googleapis.com --project=%PROJECTID%
%GCLOUD% services enable compute.googleapis.com --project=%PROJECTID%
%GCLOUD% services enable cloudbuild.googleapis.com --project=%PROJECTID%
```

### Step 3: Configure Docker
```batch
%GCLOUD% auth configure-docker --quiet
```

### Step 4: Build Images (TAKES ~15 MINUTES)

**Build frontend:**
```batch
docker build -t %REGISTRY%/texas-frontend:latest .\frontend
docker build -t %REGISTRY%/texas-frontend:v1 .\frontend
```

**Build backend:**
```batch
docker build -t %REGISTRY%/texas-backend:latest .\backend
docker build -t %REGISTRY%/texas-backend:v1 .\backend
```

### Step 5: Push Images to GCR
```batch
docker push %REGISTRY%/texas-frontend:latest
docker push %REGISTRY%/texas-frontend:v1
docker push %REGISTRY%/texas-backend:latest
docker push %REGISTRY%/texas-backend:v1
```

### Step 6: Create GKE Cluster (TAKES ~10 MINUTES)
```batch
%GCLOUD% container clusters create %CLUSTER% ^
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
```

### Step 7: Get Cluster Credentials
```batch
%GCLOUD% container clusters get-credentials %CLUSTER% --zone=%ZONE% --project=%PROJECTID%
```

### Step 8: Update K8s Manifests
Open Notepad with the files:
```batch
notepad k8s\backend-deployment.yaml
```
- Press Ctrl+H
- Find: `<PROJECT-ID>`
- Replace All with: `texas-poker-001`
- Save and close

```batch
notepad k8s\frontend-deployment.yaml
```
- Press Ctrl+H
- Find: `<PROJECT-ID>`
- Replace All with: `texas-poker-001`
- Save and close

### Step 9: Deploy to Kubernetes
```batch
kubectl apply -f k8s\backend-deployment.yaml
kubectl apply -f k8s\frontend-deployment.yaml
```

### Step 10: Wait for Deployment
```batch
kubectl rollout status deployment/texas-backend --timeout=300s
kubectl rollout status deployment/texas-frontend --timeout=300s
```

### Step 11: Get Your Public URL
```batch
kubectl get svc texas-frontend
```

Look for EXTERNAL-IP column. Copy that IP and visit:
```
http://<EXTERNAL-IP>
```

---

## 🎉 Success!

Your app is live! Test it:
1. Go to **Evaluate** tab → enter 2 hole cards + 5 community cards
2. Go to **Probability** tab → see win chances
3. Go to **Compare** tab → compare two hands

---

## ⚠️ If Something Goes Wrong

**Docker won't start?**
- Restart Docker Desktop
- Ensure Hyper-V is enabled on Windows
- Check Event Viewer for errors

**gcloud command fails?**
- Verify path: `C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd`
- Try: `gcloud auth login`

**kubectl can't connect to cluster?**
- Run Step 7 again (get-credentials)
- Try: `kubectl cluster-info`

**External IP stuck on pending?**
- Wait 5+ minutes
- Check: `kubectl get svc texas-frontend --watch`

---

## 📋 What Happens at Each Step

| Step | Action | Time |
|------|--------|------|
| 1 | Create GCP project | 20 sec |
| 2 | Enable cloud APIs | 1-2 min |
| 3 | Docker auth | 10 sec |
| 4 | Build images | 10-15 min ⏳ |
| 5 | Push to registry | 5-10 min |
| 6 | Create K8s cluster | 5-10 min ⏳ |
| 7 | Get credentials | 10 sec |
| 8 | Update manifests | 1 min |
| 9 | Deploy to K8s | 30 sec |
| 10 | Wait for ready | 3-5 min |
| 11 | Get URL | 10 sec |

**Total: ~30-45 minutes**

---

## 🔍 Verification Commands

Check everything is working:

```batch
REM Check pods
kubectl get pods

REM Check services
kubectl get svc

REM Check deployments
kubectl get deployments

REM Check cluster
kubectl cluster-info

REM View logs
kubectl logs -f deployment/texas-backend
kubectl logs -f deployment/texas-frontend
```

---

## 🧹 Cleanup (Optional)

When done, delete everything:

```batch
REM Delete deployments
kubectl delete deployment texas-backend
kubectl delete deployment texas-frontend

REM Delete cluster (takes ~5 min)
%GCLOUD% container clusters delete %CLUSTER% --zone=%ZONE% --project=%PROJECTID%

REM Delete images
%GCLOUD% container images delete %REGISTRY%/texas-frontend --quiet --delete-tags
%GCLOUD% container images delete %REGISTRY%/texas-backend --quiet --delete-tags

REM Delete project
%GCLOUD% projects delete %PROJECTID%
```

---

## 📝 Important Notes

- **Docker must be running** before building images
- **Commands are in Command Prompt** (not PowerShell or bash)
- **Save your project ID**: `texas-poker-001` (needed for cleanup)
- **GCP billing**: ~$2.50/day when cluster is running
- **Don't close Command Prompt** until deployment is complete

---

Ready? Start at **Step 0** and follow each command! 🚀
