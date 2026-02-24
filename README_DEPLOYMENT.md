# Texas Hold'em Poker App - Production Deployment Guide

## 🚀 Quick Start

You've successfully authenticated with GCP! Now follow these simple steps to deploy your Texas Hold'em Poker app to Google Kubernetes Engine (GKE):

### Linux/macOS (Recommended)
```bash
chmod +x deploy-complete.sh
./deploy-complete.sh
```

### Windows
```bash
deploy-complete.bat
```

**That's it!** The script handles everything:
- ✅ Creates a new GCP project
- ✅ Enables required APIs
- ✅ Builds Docker images
- ✅ Pushes to Google Container Registry
- ✅ Creates a GKE cluster
- ✅ Deploys your application
- ✅ Outputs the public URL

**Expected time:** 10-15 minutes

---

## 📋 What You Get

After deployment, you'll have:

- **GKE Cluster**: Production-ready Kubernetes environment
- **Auto-scaling**: 2-5 replicas based on CPU/memory usage
- **LoadBalancer**: Public IP for accessing your app
- **Health Checks**: Automatic pod restart on failure
- **Container Registry**: Images stored securely on GCR

---

## 🎯 Deployment Paths

### Option 1: Fully Automated (Recommended ⭐)
```bash
./deploy-complete.sh
```
- Most foolproof
- Handles all steps automatically
- No manual configuration needed

### Option 2: Step-by-Step Manual
See [DEPLOYMENT_COMPLETE.md](DEPLOYMENT_COMPLETE.md) for detailed commands

### Option 3: Local Testing First
```bash
# Test with Docker Compose before deploying to GKE
docker-compose up -d
# App will be at http://localhost
# API at http://localhost:8080
```

---

## ✅ Verification

After deployment completes, verify everything is working:

```bash
# Check if everything started correctly
./verify-deployment.sh

# Or manually:
kubectl get pods
kubectl get svc texas-frontend
```

---

## 🌐 Access Your App

Once the script completes, you'll get your public IP address. Visit:
```
http://<EXTERNAL-IP>
```

Example: `http://34.120.45.123`

### What to Test
1. **Evaluate Tab**: Input 2 hole cards and 5 community cards → see the best hand
2. **Probability Tab**: Calculate win probability with Monte Carlo simulation
3. **Compare Tab**: Compare two players' hands → see who wins

---

## 📊 Architecture

```
┌─────────────────────────────────────┐
│     Your Browser (Public Internet)  │
└─────────────────┬───────────────────┘
                  │ http://34.120.x.x
                  ▼
┌─────────────────────────────────────┐
│    LoadBalancer Service (Port 80)   │
│         (public-facing)             │
└─────────────────┬───────────────────┘
                  │
        ┌─────────┴──────────┐
        ▼                    ▼
   ┌─────────────┐     ┌──────────────┐
   │ Frontend    │     │   Frontend   │
   │ Pod 1 (ng) │     │   Pod 2 (ng) │
   │ (Replicas) │     │  (Replicas)  │
   └──────┬──────┘     └──────┬───────┘
          │                   │
          └────────┬──────────┘
                   │
          ┌────────▼────────┐
          │  ClusterIP Svc  │ (Internal)
          │  :8080/backend  │
          └────────┬────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
   ┌─────────────┐      ┌──────────────┐
   │  Backend    │      │   Backend    │
   │  Poker API  │      │  Poker API   │
   │  Pod 1      │      │  Pod 2       │
   │ (Go/Port80) │      │ (Go/Port80)  │
   └─────────────┘      └──────────────┘

GKE Cluster with:
• Auto-scaling (2-5 replicas each)
• Health checks
• Resource limits
• Horizontal Pod Autoscaler (HPA)
```

---

## 🛠️ Common Tasks

### View Application Logs
```bash
# Backend logs
kubectl logs -f deployment/texas-backend

# Frontend logs
kubectl logs -f deployment/texas-frontend

# Specific pod
kubectl logs -f <pod-name>
```

### Scale Up/Down
```bash
# Scale backend to 5 replicas
kubectl scale deployment texas-backend --replicas=5

# Auto-scaler will manage between 2-5 based on load
```

### Check Status
```bash
# All pods
kubectl get pods

# All services
kubectl get svc

# Detailed pod info
kubectl describe pod <pod-name>

# Watch real-time changes
kubectl get pods --watch
```

### Monitor Resources
```bash
# CPU and memory usage
kubectl top nodes
kubectl top pods
```

---

## 🧹 Cleanup

When you're done and want to delete everything:

```bash
# Remove from GKE (this deletes the cluster)
gcloud container clusters delete poker-cluster --zone us-central1-a

# Delete the images from Google Container Registry
gcloud container images delete gcr.io/<PROJECT-ID>/texas-backend --quiet --delete-tags
gcloud container images delete gcr.io/<PROJECT-ID>/texas-frontend --quiet --delete-tags

# Delete the GCP project itself (optional, last step)
gcloud projects delete <PROJECT-ID>
```

---

## 💰 Cost Estimation

After running `deploy-complete.sh`, your GKE cluster will incur charges:

| Component | Cost | Duration |
|-----------|------|----------|
| GKE Cluster fee | $0.146/hour | Per cluster |
| Compute Engine (2 nodes) | ~$0.10/hour | Always running |
| **Total** | **~$2.50/day** | When cluster exists |
| **Monthly** | **~$75/month** | When cluster exists |

### Cost Tips
- ⏸️ Delete cluster when not in use: `gcloud container clusters delete poker-cluster --zone us-central1-a`
- 📦 Use cheaper machine types: Edit `deploy-complete.sh` to use `n1-standard-1` instead of `n1-standard-2`
- 🔧 Scale down nodes: `gcloud container clusters update poker-cluster --num-nodes=1 --zone us-central1-a`

---

## 🐛 Troubleshooting

### External IP stuck on "Pending"
```bash
# Normal - wait 2-5 minutes
kubectl get svc texas-frontend --watch

# If over 5 minutes:
# Check cluster has enough resources
kubectl get nodes
kubectl describe svc texas-frontend
```

### Pods won't start
```bash
# Check pod status
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Cannot reach app at external IP
```bash
# Verify service is exposed
kubectl get svc texas-frontend

# Check if pods are running
kubectl get pods

# Test backend from frontend pod
kubectl exec -it <frontend-pod> -- curl http://texas-backend:8080/evaluate
```

### Docker build fails
```bash
# Ensure Docker is running
docker --version

# Check if images exist locally
docker images

# Clean up old images
docker image prune -a
```

---

## 📚 Additional Resources

- **Full Deployment Guide**: See [DEPLOYMENT_COMPLETE.md](DEPLOYMENT_COMPLETE.md)
- **Verification Script**: Run `./verify-deployment.sh` to check status
- **Manual Steps**: If script fails, check DEPLOYMENT_COMPLETE.md for step-by-step instructions

---

## ❓ FAQ

**Q: Why is deployment taking so long?**
A: GKE cluster creation typically takes 5-10 minutes. Check progress with:
```bash
gcloud container clusters list --project <PROJECT-ID>
```

**Q: Can I use a different region?**
A: Yes! Edit `deploy-complete.sh` and change:
```bash
REGION="us-west1"  # Change to your preferred region
ZONE="us-west1-a"
```

**Q: How do I update my app after deployment?**
A: Build new images, push to GCR, then update the deployment:
```bash
docker build -t gcr.io/<PROJECT-ID>/texas-backend:v2 ./backend
docker push gcr.io/<PROJECT-ID>/texas-backend:v2
kubectl set image deployment/texas-backend backend=gcr.io/<PROJECT-ID>/texas-backend:v2
```

**Q: Can I use Windows?**
A: Yes! Use `deploy-complete.bat`, but you'll need to manually edit K8s manifests to replace `<PROJECT-ID>` with your actual project ID before running kubectl apply.

**Q: What if the script fails halfway?**
A: Check the error message, fix the issue, and run the script again. It's safe to re-run - most steps are idempotent.

---

## 🎉 Success!

You now have a production-grade Kubernetes deployment of your Texas Hold'em Poker app!

**Next Steps:**
1. ✅ Share your public IP with friends
2. ✅ Monitor with `kubectl get pods --watch`
3. ✅ Scale as needed with `kubectl scale deployment <name> --replicas=N`
4. ✅ Clean up when done to avoid charges

**Questions?** Check the logs:
```bash
kubectl logs -f deployment/texas-backend
kubectl logs -f deployment/texas-frontend
```

Happy deploying! 🚀
