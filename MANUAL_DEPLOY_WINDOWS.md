# Texas Hold'em Poker - Manual GCP Deployment (Windows)

## 🚀 Quick Start

Due to Windows Python path issues, follow these manual steps in **Command Prompt** (not bash).

### Step 0: Open Command Prompt and Navigate
```batch
cd C:\Users\yorda\OneDrive\Desktop\Texas Hold'em poker
```

---

## Commands to Run (Copy & Paste into Command Prompt)

### Step 1: Verify Authentication
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd auth list
```
Should show: `yordanostibebu5@gmail.com` as ACTIVE

### Step 2: Create GCP Project
Replace `YOUR-PROJECT-ID` with something unique (e.g., `texas-poker-test-001`)

```batch
set PROJECTID=texas-poker-001
set REGION=us-central1
set ZONE=us-central1-a

C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd projects create %PROJECTID% --name="Texas Hold'em Poker App" --set-as-default
```

### Step 3: Enable Required APIs
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd services enable container.googleapis.com --project=%PROJECTID%
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd services enable containerregistry.googleapis.com --project=%PROJECTID%
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd services enable compute.googleapis.com --project=%PROJECTID%
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd services enable cloudbuild.googleapis.com --project=%PROJECTID%
```

### Step 4: Configure Docker
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd auth configure-docker --quiet
```

### Step 5: Build and Push Docker Images
```batch
set REGISTRY=gcr.io/%PROJECTID%
set BACKEND_IMAGE=%REGISTRY%/texas-backend
set FRONTEND_IMAGE=%REGISTRY%/texas-frontend

echo Building backend...
docker build -t %BACKEND_IMAGE%:latest .\backend
docker build -t %BACKEND_IMAGE%:v1 .\backend

echo Building frontend...
docker build -t %FRONTEND_IMAGE%:latest .\frontend
docker build -t %FRONTEND_IMAGE%:v1 .\frontend

echo Pushing images...
docker push %BACKEND_IMAGE%:latest
docker push %BACKEND_IMAGE%:v1
docker push %FRONTEND_IMAGE%:latest
docker push %FRONTEND_IMAGE%:v1
```

**Tip:** First build may take 5-10 minutes. Subsequent builds will be faster.

### Step 6: Create GKE Cluster
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd container clusters create poker-cluster ^
    --project=%PROJECTID% ^
    --zone=%ZONE% ^
    --num-nodes=2 ^
    --machine-type=n1-standard-2 ^
    --enable-stackdriver-kubernetes ^
    --network="default" ^
    --enable-autoscaling ^
    --min-nodes=2 ^
    --max-nodes=5 ^
    --addons=HorizontalPodAutoscaling,HttpLoadBalancing
```

**⏳ Wait:** This takes 5-10 minutes. ☕

### Step 7: Get Cluster Credentials
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd container clusters get-credentials poker-cluster ^
    --zone=%ZONE% ^
    --project=%PROJECTID%
```

### Step 8: Update Kubernetes Manifests

**Important:** You need to replace `<PROJECT-ID>` with your actual project ID in two files.

#### Option A: Using Notepad (Easy)
1. Open `k8s\backend-deployment.yaml` in Notepad
2. Press Ctrl+H (Find & Replace)
3. Find: `<PROJECT-ID>`
4. Replace with: `texas-poker-001` (or whatever your PROJECT ID is)
5. Click Replace All
6. Save and close
7. Repeat for `k8s\frontend-deployment.yaml`

#### Option B: Using Command Line
```batch
powershell -Command "(Get-Content k8s\backend-deployment.yaml) -replace '<PROJECT-ID>', '%PROJECTID%' | Set-Content k8s\backend-deployment.yaml"
powershell -Command "(Get-Content k8s\frontend-deployment.yaml) -replace '<PROJECT-ID>', '%PROJECTID%' | Set-Content k8s\frontend-deployment.yaml"
```

### Step 9: Deploy to Kubernetes
```batch
kubectl apply -f k8s\backend-deployment.yaml
kubectl apply -f k8s\frontend-deployment.yaml
```

### Step 10: Wait for Deployment
```batch
echo Waiting for backend...
kubectl rollout status deployment/texas-backend --timeout=600s

echo Waiting for frontend...
kubectl rollout status deployment/texas-frontend --timeout=600s
```

### Step 11: Get Your Public URL
```batch
kubectl get svc texas-frontend
```

Look for the `EXTERNAL-IP` column. Copy that IP address and visit it in your browser:
```
http://34.120.XXX.XXX
```

---

## ✅ Verify Deployment

### Check All Pods Running
```batch
kubectl get pods
```
Should show all pods with status `Running`

### Check Services
```batch
kubectl get svc
```
Should show texas-frontend with an EXTERNAL-IP

### View Logs
```batch
REM Backend logs
kubectl logs -f deployment/texas-backend

REM Frontend logs
kubectl logs -f deployment/texas-frontend
```

---

## 🌐 Access Your App

Once you have the EXTERNAL-IP from Step 11:

1. Open browser to: `http://<EXTERNAL-IP>`
2. Test all three tabs (Evaluate, Probability, Compare Hands)
3. Share the URL with friends!

---

## 🧹 Cleanup (When Done)

Delete everything to stop charges:

```batch
REM Delete deployments
kubectl delete deployment texas-backend texas-frontend

REM Delete cluster (THIS TAKES A FEW MINUTES)
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd container clusters delete poker-cluster --zone=%ZONE% --project=%PROJECTID%

REM Delete images (optional)
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd container images delete gcr.io/%PROJECTID%/texas-backend --quiet --delete-tags
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd container images delete gcr.io/%PROJECTID%/texas-frontend --quiet --delete-tags

REM Delete project (optional, last step)
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd projects delete %PROJECTID%
```

---

## 💡 Useful Commands

### Scale Deployments
```batch
REM Scale backend to 5 replicas
kubectl scale deployment texas-backend --replicas=5

REM Scale frontend to 3 replicas
kubectl scale deployment texas-frontend --replicas=3
```

### Monitor Resources
```batch
REM CPU and memory usage
kubectl top nodes
kubectl top pods
```

### Get Detailed Pod Info
```batch
kubectl describe pod <pod-name>
```

### Watch Real-time Updates
```batch
kubectl get pods --watch
```

---

## 🐛 Troubleshooting

### "gcloud command not found"
Use full path: `C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd`

### External IP stuck on "Pending"
```batch
REM Wait 2-5 minutes and check again
kubectl get svc texas-frontend --watch
```

### Pods won't start
```batch
REM Check pod status
kubectl describe pod <pod-name>

REM View logs
kubectl logs <pod-name>

REM Check events
kubectl get events --sort-by=.lastTimestamp
```

### Docker build fails
```batch
REM Ensure Docker is running
docker --version

REM Clean up old images
docker image prune -a
```

### Cannot authenticate to GCP
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd auth login
```

---

## ⏱️ Expected Timeline

| Step | Duration |
|------|----------|
| API enabling | 1-2 min |
| Docker build | 5-10 min (first time) |
| Docker push | 2-5 min |
| GKE cluster creation | 5-10 min (**longest**) |
| Kubernetes deployment | 2-5 min |
| External IP assignment | 2-5 min |
| **TOTAL** | **20-35 minutes** |

---

## 💰 Cost Information

After running all these commands:
- ✅ **Free tier**: First 1 month, $300 credit (if new account)
- 💰 **After free tier**: ~$2.50/day for 2-node cluster
- 💰 **Monthly**: ~$75

**Delete cluster when done to stop charges!**

---

## 🎉 Success Indicators

✅ All steps complete without errors
✅ `kubectl get pods` shows all pods as `Running`
✅ `kubectl get svc texas-frontend` shows EXTERNAL-IP is no longer `<pending>`
✅ Visiting the EXTERNAL-IP URL loads the poker app
✅ All three tabs (Evaluate, Probability, Compare) work correctly

---

## 📝 Saving Your Project ID

Save your project ID for cleanup later:
```
Project ID: texas-poker-001
Region: us-central1
Zone: us-central1-a
Created: [date]
```

---

## ❓ Still Having Issues?

1. Check logs: `kubectl logs <pod-name>`
2. Check pod status: `kubectl describe pod <pod-name>`
3. Verify images pushed: `gcloud container images list --project=%PROJECTID%`
4. Check cluster exists: `gcloud container clusters list --project=%PROJECTID%`

Good luck! 🚀
