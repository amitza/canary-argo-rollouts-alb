# Canary Deployments with Argo Rollouts and AWS ALB

A POC for implementing canary deployments on AWS EKS using Argo Rollouts and Application Load Balancers (ALB). This project demonstrates practices for gradual traffic shifting using canary and header based routing.

## Architecture


## Quick Start

### Prerequisites

- **AWS EKS Cluster**
- **AWS Load Balancer Controller** installed and configured with proper IAM permissions
  - Must include `elasticloadbalancing:SetRulePriorities` permission for canary deployments
  - See [AWS Load Balancer Controller Installation Guide](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/)
- **Argo Rollouts** installed

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/amitza/canary-argo-rollouts-alb.git
   cd canary-argo-rollouts-alb
   ```

2. **Deploy the application:**
   ```bash
   ./scripts/deploy.sh
   ```

3. **Verify deployment:**
   ```bash
   kubectl get rollouts
   kubectl get pods -l app=frontend
   kubectl get pods -l app=backend
   ```

### Trigger Canary Deployment

```bash
# Trigger canary deployment
./scripts/trigger-canary.sh

# Monitor progress
kubectl argo rollouts get rollout frontend-rollout --watch

# Run comprehensive tests
./scripts/test-canary.sh
```

### Working with ArgoCD

A workaround when working with ArgoCD is instructing it to ignore specific changes made by Argo Rollout to the Ingress resources:

```yaml
ignoreDifferences:
   - group: networking.k8s.io
      kind: Ingress
      jqPathExpressions:
      - >-
         .spec.rules[]?.http.paths[]?|select (.backend.
         service.name=="frontend-stable-service")
```