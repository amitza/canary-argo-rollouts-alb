#!/bin/bash

set -e

echo "Testing Canary Deployment"
echo "============================"
echo

echo "Current Rollout Status:"
kubectl get rollouts -o custom-columns="NAME:.metadata.name,DESIRED:.spec.replicas,CURRENT:.status.replicas,READY:.status.readyReplicas,STATUS:.status.phase"
echo

FRONTEND_ENDPOINT=$(kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
BACKEND_ENDPOINT=$(kubectl get ingress backend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Frontend endpoint: $FRONTEND_ENDPOINT"
echo "Backend endpoint: $BACKEND_ENDPOINT"

echo "Testing Frontend Service..."
kubectl run test-frontend --image=curlimages/curl --rm -i --quiet --restart=Never -- curl -s --max-time 5 http://$FRONTEND_ENDPOINT/health
echo "✅ Frontend health check passed"

echo "Testing Backend Service..."
kubectl run test-backend --image=curlimages/curl --rm -i --quiet --restart=Never -- curl -s --max-time 5 http://$BACKEND_ENDPOINT/health
echo "✅ Backend health check passed"

echo
echo "Testing Frontend traffic (http://$FRONTEND_ENDPOINT):"
for i in {1..10}; do
    RESPONSE=$(kubectl run test-frontend-$i --image=curlimages/curl --rm -i --quiet --restart=Never -- curl -s --max-time 5 http://$FRONTEND_ENDPOINT 2>/dev/null || echo "ERROR")
    if [[ "$RESPONSE" != "ERROR" ]]; then
        POD_NAME=$(echo "$RESPONSE" | grep -oE "Backend: [a-zA-Z0-9-]+" | cut -d' ' -f2 || echo "unknown")
        echo "  Request $i: $POD_NAME"
    else
        echo "  Request $i: FAILED"
    fi
    sleep 1
done

echo
echo "Testing header-based routing (http://$FRONTEND_ENDPOINT) with X-Canary: True:"
for i in {1..10}; do
    RESPONSE=$(kubectl run test-header-$i --image=curlimages/curl --rm -i --quiet --restart=Never -- curl -s --max-time 5 -H "X-Canary: True" http://$FRONTEND_ENDPOINT 2>/dev/null || echo "ERROR")
    if [[ "$RESPONSE" != "ERROR" ]]; then
        POD_NAME=$(echo "$RESPONSE" | grep -oE "Backend: [a-zA-Z0-9-]+" | cut -d' ' -f2 || echo "unknown")
        echo "  Request $i: $POD_NAME"
    else
        echo "  Request $i: FAILED"
    fi
    sleep 1
done

echo
echo "✅ Canary tests completed!"
