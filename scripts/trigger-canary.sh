#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly MANIFESTS_DIR="$PROJECT_ROOT/manifests"

DEPLOY_FRONTEND=true
DEPLOY_BACKEND=true

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_success() {
    echo "[SUCCESS] $*"
}

validate_prerequisites() {
    local missing_tools=()
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! kubectl get rollouts &> /dev/null; then
        missing_tools+=("argo-rollouts")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
}

validate_rollout_exists() {
    local rollout_name="$1"
    if ! kubectl get rollout "$rollout_name" &> /dev/null; then
        log_error "Rollout '$rollout_name' does not exist"
        return 1
    fi
}

deploy_canary() {
    local service="$1"
    local manifest_file="$MANIFESTS_DIR/${service}/rollout-v2.yaml"
    
    log_info "Deploying $service canary using v2 manifest"
    
    if [[ ! -f "$manifest_file" ]]; then
        log_error "V2 manifest not found: $manifest_file"
        return 1
    fi
    
    # Apply the v2 manifest directly
    kubectl apply -f "$manifest_file"
    
    log_success "$service canary deployment triggered"
}

wait_for_rollout_update() {
    local rollout_name="$1"
    local timeout=60
    
    log_info "Waiting for rollout '$rollout_name' to update..."
    
    if kubectl rollout status rollout/"$rollout_name" --timeout="${timeout}s" &> /dev/null; then
        log_success "Rollout '$rollout_name' updated successfully"
    else
        log_error "Rollout '$rollout_name' failed to update within ${timeout}s"
        return 1
    fi
}

show_rollout_status() {
    log_info "Current rollout status:"
    kubectl get rollouts -o custom-columns="NAME:.metadata.name,DESIRED:.spec.replicas,CURRENT:.status.replicas,READY:.status.readyReplicas,STATUS:.status.phase"
}

main() {
    log_info "Starting canary deployment process"
    
    validate_prerequisites
    
    show_rollout_status
    echo
    
    local deployment_failed=false
    
    if [[ "$DEPLOY_FRONTEND" == true ]]; then
        if validate_rollout_exists "frontend-rollout"; then
            deploy_canary "frontend" || deployment_failed=true
        else
            deployment_failed=true
        fi
    fi
    
    if [[ "$DEPLOY_BACKEND" == true ]]; then
        if validate_rollout_exists "backend-rollout"; then
            deploy_canary "backend" || deployment_failed=true
        else
            deployment_failed=true
        fi
    fi
    
    if [[ "$deployment_failed" == true ]]; then
        log_error "One or more deployments failed"
        exit 1
    fi
    
    sleep 10
    
    echo
    show_rollout_status
    
    echo
    log_success "Canary deployment initiated successfully"
}

main "$@"
