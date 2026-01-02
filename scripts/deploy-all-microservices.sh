#!/bin/bash

#####################################################
# StackFood Microservices Deployment Script
# Aplica todas as ArgoCD Applications automaticamente
#####################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ArgoCD Applications URLs
APPS=(
  "https://raw.githubusercontent.com/Stack-Food/stackfood-api-customers/main/k8s/argocd-application.yaml|customers"
  "https://raw.githubusercontent.com/Stack-Food/stackfood-api-product/main/k8s/argocd-application.yaml|products"
  "https://raw.githubusercontent.com/Stack-Food/stackfood-api-orders/main/k8s/argocd-application.yaml|orders"
  "https://raw.githubusercontent.com/Stack-Food/stackfood-api-payments/main/k8s/argocd-application.yaml|payments"
  "https://raw.githubusercontent.com/Stack-Food/stackfood-api-production/main/k8s/argocd-application.yaml|production"
)

echo -e "${GREEN}🚀 StackFood Microservices Deployment${NC}"
echo -e "${GREEN}=======================================${NC}\n"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster.${NC}"
    echo -e "${YELLOW}💡 Run: aws eks update-kubeconfig --region us-east-1 --name stackfood-eks${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Connected to Kubernetes cluster${NC}\n"

# Check if ArgoCD is installed
if ! kubectl get namespace argocd &> /dev/null; then
    echo -e "${RED}❌ ArgoCD namespace not found.${NC}"
    echo -e "${YELLOW}💡 Please install ArgoCD first (Terraform should have done this).${NC}"
    exit 1
fi

echo -e "${GREEN}✅ ArgoCD namespace found${NC}\n"

# Deploy each application
echo -e "${YELLOW}📦 Deploying microservices...${NC}\n"

SUCCESS_COUNT=0
FAIL_COUNT=0

for app_entry in "${APPS[@]}"; do
  IFS='|' read -r url name <<< "$app_entry"

  echo -e "${YELLOW}→ Deploying: ${name}${NC}"

  if kubectl apply -f "$url" &> /dev/null; then
    echo -e "${GREEN}  ✅ ${name} application created/updated${NC}"
    ((SUCCESS_COUNT++))
  else
    echo -e "${RED}  ❌ Failed to deploy ${name}${NC}"
    ((FAIL_COUNT++))
  fi

  echo ""
done

# Summary
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}📊 Deployment Summary${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}✅ Successful: ${SUCCESS_COUNT}${NC}"
if [ $FAIL_COUNT -gt 0 ]; then
  echo -e "${RED}❌ Failed: ${FAIL_COUNT}${NC}"
fi
echo ""

# Wait for applications to be created
echo -e "${YELLOW}⏳ Waiting for ArgoCD to process applications...${NC}"
sleep 5

# Check application status
echo -e "\n${YELLOW}📋 ArgoCD Applications Status:${NC}\n"
kubectl get applications -n argocd -o wide

echo -e "\n${GREEN}=======================================${NC}"
echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo -e "${GREEN}=======================================${NC}\n"

echo -e "${YELLOW}📌 Next steps:${NC}"
echo -e "1. Check application sync status:"
echo -e "   ${GREEN}kubectl get applications -n argocd${NC}\n"
echo -e "2. Access ArgoCD UI:"
echo -e "   ${GREEN}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
echo -e "   ${GREEN}Open: https://localhost:8080${NC}\n"
echo -e "3. Monitor pods:"
echo -e "   ${GREEN}watch kubectl get pods -A | grep stackfood${NC}\n"
echo -e "4. Check logs:"
echo -e "   ${GREEN}kubectl logs -f deployment/stackfood-<service> -n <namespace>${NC}\n"

echo -e "${YELLOW}💡 Tip: Applications will auto-sync. Check ArgoCD UI for progress.${NC}\n"
