# Canary Deployment Testing Guide

This guide explains how to test canary deployments using the provided testing scripts.

## 🧪 Available Testing Scripts

### 1. `trigger-canary.sh` - Quick Canary Trigger
Quickly trigger canary deployments with custom images.

```bash
# Basic usage (uses nginx:1.22 for both services)
./trigger-canary.sh

# Custom images
./trigger-canary.sh --frontend-image nginx:1.23 --backend-image nginx:1.23

# Help
./trigger-canary.sh --help
```

### 2. `monitor-canary.sh` - Real-time Monitoring
Continuously monitor canary deployment progress.

```bash
./monitor-canary.sh
```

**Features:**
- Real-time rollout status
- Pod distribution and health
- ALB endpoint status
- Live traffic testing
- Auto-refresh every 10 seconds

### 3. `test-canary.sh` - Comprehensive Testing
Full automated canary deployment test with validation.

```bash
./test-canary.sh
```

**Test Flow:**
1. Pre-flight checks
2. Initial connectivity tests
3. Trigger canary deployments
4. Test traffic distribution at each step (25%, 50%, 75%)
5. Automatic promotion through all steps
6. Final validation

## 🚀 Testing Scenarios

### Scenario 1: Quick Manual Test
```bash
# 1. Trigger canary
./trigger-canary.sh

# 2. Monitor in another terminal
./monitor-canary.sh

# 3. Manual promotion
kubectl argo rollouts promote frontend-rollout
kubectl argo rollouts promote backend-rollout
```

### Scenario 2: Automated Full Test
```bash
# Run complete automated test
./test-canary.sh
```

### Scenario 3: Custom Image Testing
```bash
# Test with specific images
./trigger-canary.sh --frontend-image nginx:1.23 --backend-image nginx:alpine

# Monitor the deployment
./monitor-canary.sh
```

### Scenario 4: Rollback Testing
```bash
# 1. Trigger canary
./trigger-canary.sh

# 2. Wait for first step (25%)
sleep 60

# 3. Abort rollout (simulates rollback)
kubectl argo rollouts abort frontend-rollout
kubectl argo rollouts abort backend-rollout
```

## 🔍 Manual Testing Commands

### Check Rollout Status
```bash
# List all rollouts
kubectl get rollouts

# Detailed rollout info
kubectl argo rollouts get rollout frontend-rollout
kubectl argo rollouts get rollout backend-rollout

# Watch rollout progress
kubectl argo rollouts get rollout frontend-rollout --watch
```

### Test Traffic Distribution
```bash
# Get ALB endpoint
FRONTEND_ALB=$(kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test multiple requests to see distribution
for i in {1..10}; do
  kubectl run test-$i --image=curlimages/curl --rm -i --quiet --restart=Never -- curl -s http://$FRONTEND_ALB/
  sleep 1
done
```

### Check Pod Distribution
```bash
# See pod template hashes (indicates canary vs stable)
kubectl get pods -l app=frontend --show-labels
kubectl get pods -l app=backend --show-labels

# Count pods by hash
kubectl get pods -l app=frontend -o jsonpath='{.items[*].metadata.labels.rollouts-pod-template-hash}' | tr ' ' '\n' | sort | uniq -c
```

### Manual Rollout Control
```bash
# Promote to next step
kubectl argo rollouts promote frontend-rollout

# Abort rollout
kubectl argo rollouts abort frontend-rollout

# Retry failed rollout
kubectl argo rollouts retry frontend-rollout

# Set image directly
kubectl argo rollouts set image frontend-rollout frontend=nginx:1.23
```

## 📊 Expected Test Results

### Traffic Distribution
During canary deployment, you should see:
- **Step 1**: ~25% canary, 75% stable
- **Step 2**: ~50% canary, 50% stable  
- **Step 3**: ~75% canary, 25% stable
- **Complete**: 100% new version

### Pod Behavior
- New pods created with different `rollouts-pod-template-hash`
- Old pods gradually terminated
- Health checks pass for new pods
- Services route to both old and new pods during transition

### ALB Behavior
- Weighted routing updates automatically
- Health checks continue to pass
- No service interruption during deployment

## 🐛 Troubleshooting

### Common Issues

#### 1. ALB Not Ready
```bash
# Check ingress status
kubectl describe ingress frontend-ingress

# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

#### 2. Rollout Stuck
```bash
# Check rollout events
kubectl describe rollout frontend-rollout

# Check pod status
kubectl get pods -l app=frontend
kubectl describe pod <pod-name>
```

#### 3. Traffic Not Distributing
```bash
# Check service endpoints
kubectl get endpoints frontend-stable-service
kubectl get endpoints frontend-canary-service

# Verify ALB target groups in AWS Console
```

#### 4. Health Check Failures
```bash
# Test health endpoint directly
kubectl port-forward svc/frontend-stable-service 8080:80
curl http://localhost:8080/health

# Check pod logs
kubectl logs -l app=frontend
```

### Recovery Commands
```bash
# Reset to stable state
kubectl argo rollouts abort frontend-rollout
kubectl argo rollouts abort backend-rollout

# Force restart
kubectl rollout restart deployment/frontend-rollout
kubectl rollout restart deployment/backend-rollout

# Clean slate (redeploy)
./cleanup.sh
./deploy.sh
```

## 📈 Monitoring and Observability

### Key Metrics to Watch
- Pod readiness and health
- Traffic distribution percentages
- Response times during transition
- Error rates
- Resource utilization

### Useful Commands
```bash
# Watch pod status
watch kubectl get pods -l app=frontend

# Monitor rollout progress
kubectl argo rollouts get rollout frontend-rollout --watch

# Check service endpoints
watch kubectl get endpoints

# Monitor ALB health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## 🎯 Success Criteria

A successful canary deployment should:
1. ✅ Create new pods with updated image
2. ✅ Gradually shift traffic (25% → 50% → 75% → 100%)
3. ✅ Maintain service availability throughout
4. ✅ Pass all health checks
5. ✅ Complete without manual intervention
6. ✅ Terminate old pods after completion

Use the provided scripts to validate these criteria automatically!
