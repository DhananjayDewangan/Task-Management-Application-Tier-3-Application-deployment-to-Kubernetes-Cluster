#!/usr/bin/env bash

set -e

EXPECTED_CONTEXT="kind-task-management"

echo "Starting deployment..."

echo "Checking Kubernetes context..."
CURRENT_CONTEXT=$(kubectl config current-context)

if [ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]; then
    echo "ERROR: Expected Kubernetes context '$EXPECTED_CONTEXT'"
    echo "Current context: '$CURRENT_CONTEXT'"
    exit 1
fi

echo "Kubernetes context: $CURRENT_CONTEXT"

echo "Checking Kubernetes node..."
kubectl get nodes

echo "Applying Terraform configuration..."
terraform -chdir=terraform apply -auto-approve

echo "Restarting backend deployment..."
kubectl rollout restart deployment/backend -n task-management

echo "Restarting frontend deployment..."
kubectl rollout restart deployment/frontend -n task-management

echo "Waiting for backend rollout..."
kubectl rollout status deployment/backend -n task-management

echo "Waiting for frontend rollout..."
kubectl rollout status deployment/frontend -n task-management

echo "Deployment completed successfully."