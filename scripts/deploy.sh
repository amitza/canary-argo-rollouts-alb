#!/bin/bash

set -e

echo ""
echo "Deploying ConfigMaps..."
kubectl apply -f manifests/frontend/configmap.yaml
kubectl apply -f manifests/backend/configmap.yaml

echo ""
echo "Deploying Services..."
kubectl apply -f manifests/frontend/services.yaml
kubectl apply -f manifests/backend/services.yaml

echo ""
echo "Deploying Rollouts..."
kubectl apply -f manifests/frontend/rollout.yaml
kubectl apply -f manifests/backend/rollout.yaml

echo ""
echo "Deploying Ingresses..."
kubectl apply -f manifests/frontend/ingress.yaml
kubectl apply -f manifests/backend/ingress.yaml

echo ""
echo "Waiting for rollouts to be ready..."
kubectl argo rollouts get rollout frontend-rollout
kubectl argo rollouts get rollout backend-rollout

echo ""
echo "Deployment complete!"
echo ""
echo "Status:"
kubectl get rollouts
echo ""
kubectl get services | grep -E "(frontend|backend)"
echo ""
kubectl get ingresses