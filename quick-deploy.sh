#!/bin/bash

################################################################################
# Quick Deploy Script - Simplest Way to Deploy
# Copy-paste these commands or use this script as a reference
################################################################################

# 1. Make scripts executable
chmod +x deploy-complete.sh
chmod +x verify-deployment.sh

# 2. Verify authentication (you should have completed gcloud auth login already)
echo "Checking authentication..."
gcloud auth list

# 3. Run the complete deployment
echo "Starting deployment..."
./deploy-complete.sh

# 4. The script will output your external IP at the end
# If you miss it, retrieve it with:
# kubectl get svc texas-frontend

# 5. Verify everything is working
echo "Verifying deployment..."
./verify-deployment.sh

# 6. Once all checks pass, visit your app at:
# http://<EXTERNAL-IP>

echo ""
echo "========================================="
echo "✓ Deployment Complete!"
echo "========================================="
echo ""
echo "Quick Commands:"
echo "  View logs:     kubectl logs -f deployment/texas-backend"
echo "  Scale up:      kubectl scale deployment texas-backend --replicas=5"
echo "  Get external IP: kubectl get svc texas-frontend"
echo "  Cleanup:       gcloud container clusters delete poker-cluster --zone us-central1-a"
echo ""
