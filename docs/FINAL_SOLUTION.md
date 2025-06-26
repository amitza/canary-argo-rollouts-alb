# DEFINITIVE SOLUTION: Rollout Configuration Issues

## 🚨 **ROOT CAUSE IDENTIFIED**

The recurring issue where pods are missing health checks and volume mounts is caused by **improper rollout updates using `kubectl patch`**.

### **The Problem:**
```bash
# THIS IS WRONG - Overwrites entire container spec
kubectl patch rollout frontend-rollout --type='merge' -p='{"spec":{"template":{"spec":{"containers":[{"name":"frontend","image":"nginx:1.22"}]}}}}'
```

**Result**: Strips out health checks, volume mounts, resource limits, and environment variables.

## ✅ **DEFINITIVE SOLUTIONS**

### **Solution 1: Fixed Trigger Script (RECOMMENDED)**

Use `trigger-canary-fixed.sh` which:
1. Updates rollout YAML files with new images
2. Reapplies complete rollout configurations
3. Preserves all health checks, volume mounts, and configurations

```bash
# Use the fixed script
./trigger-canary-fixed.sh --frontend-image nginx:1.23
```

### **Solution 2: Proper kubectl Commands**

Instead of patching, use complete rollout updates:

```bash
# WRONG - Strips configuration
kubectl patch rollout frontend-rollout --type='merge' -p='{"spec":{"template":{"spec":{"containers":[{"name":"frontend","image":"nginx:1.22"}]}}}}'

# CORRECT - Preserves configuration
# Method A: Update YAML file and reapply
sed -i 's|image: nginx:.*|image: nginx:1.23|g' manifests/frontend/rollout.yaml
kubectl apply -f manifests/frontend/rollout.yaml

# Method B: Use argo rollouts CLI
kubectl argo rollouts set image frontend-rollout frontend=nginx:1.23
```

### **Solution 3: Force Complete Redeployment**

When rollouts get corrupted:

```bash
# Delete corrupted rollouts
kubectl delete rollout frontend-rollout backend-rollout

# Reapply complete configurations
kubectl apply -f manifests/frontend/rollout.yaml
kubectl apply -f manifests/backend/rollout.yaml
```

## 🔍 **Verification Commands**

### **Check Rollout Template Integrity:**
```bash
# Should show complete container spec with health checks
kubectl get rollout frontend-rollout -o jsonpath='{.spec.template.spec.containers[0]}' | jq .
```

### **Verify Pod Configuration:**
```bash
# Check health checks
kubectl describe pod <pod-name> | grep -A 5 "Liveness\|Readiness"

# Check volume mounts
kubectl describe pod <pod-name> | grep -A 10 "nginx-config"

# Test functionality
kubectl exec <pod-name> -- curl -s http://localhost/health
```

## 📋 **Complete Rollout Template Requirements**

A proper rollout must include:

```yaml
spec:
  template:
    spec:
      containers:
      - name: frontend
        image: nginx:1.21
        ports:
        - containerPort: 80
          name: http
        
        # CRITICAL: Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # CRITICAL: Resource limits
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        
        # CRITICAL: Volume mounts
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: default.conf
        
        # HELPFUL: Environment variables
        env:
        - name: SERVICE_NAME
          value: "frontend"
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
      
      # CRITICAL: Volumes
      volumes:
      - name: nginx-config
        configMap:
          name: frontend-nginx-config
          defaultMode: 0644
```

## 🎯 **Best Practices**

### **DO:**
- ✅ Use `trigger-canary-fixed.sh` for canary deployments
- ✅ Always verify rollout templates after updates
- ✅ Test pod functionality after deployments
- ✅ Use complete YAML file updates instead of patches
- ✅ Include all required configurations in rollout templates

### **DON'T:**
- ❌ Use `kubectl patch` with container specifications
- ❌ Update only the image without preserving other configs
- ❌ Skip verification of rollout templates
- ❌ Assume configurations persist through updates

## 🧪 **Testing Validation**

After any rollout update, verify:

1. **Health Checks Present:**
   ```bash
   kubectl describe pod <pod-name> | grep "Liveness\|Readiness"
   ```

2. **Volume Mounts Working:**
   ```bash
   kubectl exec <pod-name> -- cat /etc/nginx/conf.d/default.conf
   ```

3. **Functionality Working:**
   ```bash
   kubectl exec <pod-name> -- curl -s http://localhost/health
   ```

4. **End-to-End Working:**
   ```bash
   curl http://<alb-endpoint>/
   ```

## 🎉 **SOLUTION STATUS: RESOLVED**

- ✅ **Root cause identified**: Improper kubectl patch usage
- ✅ **Fixed trigger script created**: `trigger-canary-fixed.sh`
- ✅ **Proper procedures documented**: Complete rollout updates
- ✅ **Verification commands provided**: Health checks, volume mounts, functionality
- ✅ **Best practices established**: DO/DON'T guidelines
- ✅ **Testing validated**: All configurations working correctly

**The rollout configuration issues are now DEFINITIVELY RESOLVED with proper tooling and procedures in place.**
