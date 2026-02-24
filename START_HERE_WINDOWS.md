# ⚠️ IMPORTANT: Start Docker First!

## Step 0: Start Docker Desktop

Before running any deployment commands, you **MUST** start Docker Desktop:

1. Click the **Windows Start** button
2. Search for "Docker Desktop"
3. Click to launch it
4. Wait until the Docker icon in the system tray shows it's running (no orange/yellow indicator)
5. In a terminal, verify: `docker ps`

**Wait until Docker is fully started before proceeding!**

---

## Step 1: Open Command Prompt

**DO NOT USE BASH/Git Bash/WSL for these commands.**

1. Press **Windows Key + R**
2. Type: `cmd`
3. Press Enter

---

## Step 2: Copy-Paste These Commands (One at a Time)

Navigate to your project:
```batch
cd C:\Users\yorda\OneDrive\Desktop\Texas Hold'em poker
```

Verify Docker is running:
```batch
docker ps
```
(Should show containers or empty table, not an error)

Verify gcloud is set up:
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd auth list
```
(Should show: yordanostibebu5@gmail.com as ACTIVE)

---

## Step 3: Set Your Project ID

In the same Command Prompt, set these variables:
```batch
set PROJECTID=texas-poker-001
set REGION=us-central1
set ZONE=us-central1-a
set CLUSTER=poker-cluster
set REGISTRY=gcr.io/%PROJECTID%
```

---

## Step 4: Run Deployment Commands

### 4A. Create GCP Project
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd ^
  projects create %PROJECTID% ^
  --name="Texas Hold'em Poker" ^
  --set-as-default
```

Wait for it to finish (should say "Create completed").

### 4B. Enable APIs
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd services enable container.googleapis.com --project=%PROJECTID%
```

```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd services enable containerregistry.googleapis.com --project=%PROJECTID%
```

```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd services enable compute.googleapis.com --project=%PROJECTID%
```

```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd services enable cloudbuild.googleapis.com --project=%PROJECTID%
```

### 4C. Configure Docker
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd auth configure-docker --quiet
```

### 4D. Build Frontend Docker Image
```batch
docker build -t %REGISTRY%/texas-frontend:latest .\frontend
```
(This will take 3-5 minutes)

```batch
docker build -t %REGISTRY%/texas-frontend:v1 .\frontend
```

### 4E. Build Backend Docker Image
```batch
docker build -t %REGISTRY%/texas-backend:latest .\backend
```
(This will take 2-3 minutes)

```batch
docker build -t %REGISTRY%/texas-backend:v1 .\backend
```

### 4F. Push Images to Google Container Registry

```batch
docker push %REGISTRY%/texas-frontend:latest
```

```batch
docker push %REGISTRY%/texas-frontend:v1
```

```batch
docker push %REGISTRY%/texas-backend:latest
```

```batch
docker push %REGISTRY%/texas-backend:v1
```

### 4G. Create GKE Cluster
⏳ **This step takes 5-10 minutes. Get some coffee!**

```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd container clusters create %CLUSTER% ^
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

### 4H. Get Cluster Credentials
```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd container clusters get-credentials %CLUSTER% ^
  --zone=%ZONE% ^
  --project=%PROJECTID%
```

### 4I. Update Kubernetes Manifests

**Open `k8s\backend-deployment.yaml` with Notepad:**
1. Press Ctrl+H (Find & Replace)
2. Find: `<PROJECT-ID>`
3. Replace with: `texas-poker-001`
4. Click "Replace All"
5. Save and close

**Open `k8s\frontend-deployment.yaml` with Notepad:**
1. Press Ctrl+H (Find & Replace)
2. Find: `<PROJECT-ID>`
3. Replace with: `texas-poker-001`
4. Click "Replace All"
5. Save and close

### 4J. Deploy to Kubernetes

```batch
kubectl apply -f k8s\backend-deployment.yaml
```

```batch
kubectl apply -f k8s\frontend-deployment.yaml
```

### 4K. Wait for Deployment
```batch
kubectl rollout status deployment/texas-backend --timeout=300s
```

```batch
kubectl rollout status deployment/texas-frontend --timeout=300s
```

---

## Step 5: Get Your Public URL

```batch
kubectl get svc texas-frontend
```

Look for the **EXTERNAL-IP** column. This is your public URL:
```
http://<EXTERNAL-IP>
```

If EXTERNAL-IP shows `<pending>`, wait 2-5 minutes and run the command again.

---

## ✅ Verification

All pods running:
```batch
kubectl get pods
```
(All should show "Running")

All services up:
```batch
kubectl get svc
```

---

## 🎉 Success!

Your Texas Hold'em Poker app is now live at:
```
http://<EXTERNAL-IP>
```

Test all three tabs:
- **Evaluate**: Enter hole cards and community cards
- **Probability**: Calculate win chances
- **Compare**: Compare two players' hands

---

## ⚠️ Troubleshooting

### Docker won't start
- Make sure Docker Desktop is installed
- Try restarting Docker Desktop
- Check Windows Event Viewer for errors

### gcloud commands fail
- Verify the full path: `C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd`
- Run: `gcloud auth login` to re-authenticate

### kubectl commands don't work
- Verify you ran Step 4H (get-credentials)
- Try: `kubectl cluster-info`

### External IP stuck on pending
- Wait 5 minutes and try again
- Check logs: `kubectl logs -f deployment/texas-frontend`
- Check resources: `kubectl describe svc texas-frontend`

### Image build fails
- Ensure Docker is running: `docker ps`
- Check disk space: `docker system df`
- Clean up: `docker image prune -a`

---

## 🧹 Cleanup (When Done)

Delete everything to stop charges:

```batch
kubectl delete deployment texas-backend texas-frontend
```

```batch
C:\Users\yorda\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd container clusters delete %CLUSTER% --zone=%ZONE% --project=%PROJECTID%
```

---

## 📝 Save Your Project ID

Remember: `texas-poker-001`

You'll need this for cleanup and accessing the GCP Console later.

---

## 💡 Pro Tips

- **Monitor logs**: `kubectl logs -f deployment/texas-backend`
- **Scale up**: `kubectl scale deployment texas-frontend --replicas=5`
- **Cluster info**: `kubectl cluster-info`
- **Node status**: `kubectl get nodes`

---

**Good luck! Your app will be live in 20-30 minutes!** 🚀
