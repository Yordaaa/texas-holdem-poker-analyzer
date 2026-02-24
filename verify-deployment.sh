#!/bin/bash

################################################################################
# Verification Script - Check Poker App Deployment Status
# Run this after deployment to verify everything is working
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    print_success "kubectl installed"
}

check_cluster_connection() {
    if kubectl cluster-info &> /dev/null; then
        print_success "Connected to Kubernetes cluster"
    else
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
}

check_pods() {
    print_info "Checking pods..."
    BACKEND_PODS=$(kubectl get pods -l app=texas-backend -o jsonpath='{.items[*].status.phase}' 2>/dev/null | wc -w)
    FRONTEND_PODS=$(kubectl get pods -l app=texas-frontend -o jsonpath='{.items[*].status.phase}' 2>/dev/null | wc -w)
    
    if [ "$BACKEND_PODS" -gt 0 ]; then
        print_success "Backend pods running: $BACKEND_PODS"
    else
        print_error "No backend pods found"
    fi
    
    if [ "$FRONTEND_PODS" -gt 0 ]; then
        print_success "Frontend pods running: $FRONTEND_PODS"
    else
        print_error "No frontend pods found"
    fi
}

check_services() {
    print_info "Checking services..."
    
    BACKEND_SVC=$(kubectl get svc texas-backend -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "Not found")
    if [ "$BACKEND_SVC" != "Not found" ]; then
        print_success "Backend service: $BACKEND_SVC:8080"
    else
        print_error "Backend service not found"
    fi
    
    FRONTEND_IP=$(kubectl get svc texas-frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
    if [ "$FRONTEND_IP" != "Pending" ] && [ -n "$FRONTEND_IP" ]; then
        print_success "Frontend LoadBalancer IP: $FRONTEND_IP"
    else
        print_info "Frontend external IP still pending (wait 2-5 minutes)"
    fi
}

check_deployments() {
    print_info "Checking deployments..."
    
    BACKEND_READY=$(kubectl get deployment texas-backend -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    BACKEND_DESIRED=$(kubectl get deployment texas-backend -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    
    if [ "$BACKEND_READY" = "$BACKEND_DESIRED" ] && [ "$BACKEND_DESIRED" != "0" ]; then
        print_success "Backend deployment ready: $BACKEND_READY/$BACKEND_DESIRED replicas"
    else
        print_error "Backend deployment not ready: $BACKEND_READY/$BACKEND_DESIRED replicas"
    fi
    
    FRONTEND_READY=$(kubectl get deployment texas-frontend -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    FRONTEND_DESIRED=$(kubectl get deployment texas-frontend -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    
    if [ "$FRONTEND_READY" = "$FRONTEND_DESIRED" ] && [ "$FRONTEND_DESIRED" != "0" ]; then
        print_success "Frontend deployment ready: $FRONTEND_READY/$FRONTEND_DESIRED replicas"
    else
        print_error "Frontend deployment not ready: $FRONTEND_READY/$FRONTEND_DESIRED replicas"
    fi
}

check_hpa() {
    print_info "Checking horizontal pod autoscalers..."
    
    BACKEND_HPA=$(kubectl get hpa texas-backend -o jsonpath='{.status.currentReplicas}' 2>/dev/null || echo "Not found")
    FRONTEND_HPA=$(kubectl get hpa texas-frontend -o jsonpath='{.status.currentReplicas}' 2>/dev/null || echo "Not found")
    
    if [ "$BACKEND_HPA" != "Not found" ]; then
        print_success "Backend HPA: $BACKEND_HPA current replicas"
    else
        print_info "Backend HPA not configured"
    fi
    
    if [ "$FRONTEND_HPA" != "Not found" ]; then
        print_success "Frontend HPA: $FRONTEND_HPA current replicas"
    else
        print_info "Frontend HPA not configured"
    fi
}

test_backend_health() {
    print_info "Testing backend health..."
    
    # Get a backend pod
    BACKEND_POD=$(kubectl get pod -l app=texas-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$BACKEND_POD" ]; then
        if kubectl exec $BACKEND_POD -- curl -s http://localhost:8080/evaluate -X POST -H "Content-Type: application/json" -d '{}' > /dev/null 2>&1; then
            print_success "Backend endpoint responds"
        else
            print_error "Backend endpoint not responding"
        fi
    else
        print_error "No backend pod found for testing"
    fi
}

show_logs() {
    print_info "Recent pod logs (last 5 lines):"
    echo ""
    
    BACKEND_POD=$(kubectl get pod -l app=texas-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$BACKEND_POD" ]; then
        echo "Backend ($BACKEND_POD):"
        kubectl logs $BACKEND_POD --tail=5 2>/dev/null || echo "  [No logs available]"
        echo ""
    fi
    
    FRONTEND_POD=$(kubectl get pod -l app=texas-frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$FRONTEND_POD" ]; then
        echo "Frontend ($FRONTEND_POD):"
        kubectl logs $FRONTEND_POD --tail=5 2>/dev/null || echo "  [No logs available]"
        echo ""
    fi
}

main() {
    print_header "Texas Hold'em Poker - Deployment Verification"
    
    check_kubectl
    check_cluster_connection
    echo ""
    
    check_deployments
    echo ""
    
    check_pods
    echo ""
    
    check_services
    echo ""
    
    check_hpa
    echo ""
    
    test_backend_health
    echo ""
    
    show_logs
    
    print_header "Verification Complete"
    echo ""
    print_info "Next steps:"
    echo "  1. Wait for external IP if still pending"
    echo "  2. Visit: http://<EXTERNAL-IP>"
    echo "  3. Test the poker evaluator, probability calculator, and hand comparison"
    echo "  4. Monitor logs: kubectl logs -f deployment/texas-backend"
    echo ""
}

main
