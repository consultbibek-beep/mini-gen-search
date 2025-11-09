#!/bin/bash
# ==============================================================================
# deploy_instructions_stop.sh
# Stops and removes all deployed Kubernetes resources for the mini-gen-search project.
# Uses 'set -x' to print commands before execution and verifies cleanup.
# ==============================================================================

set -e # Exit immediately if any command fails
set -x # Enable command execution tracing (prints commands before they run)

echo "-----------------------------------------------------------"
# MODIFIED: Updated project name in message
echo "🛑 Stopping and cleaning up Kubernetes resources for mini-gen-search"
echo "-----------------------------------------------------------"

# 1. Delete all resources defined in k8s-manifests.yaml
# This removes Deployments, Services, and the ConfigMap.
echo "🗑️ Deleting Deployments, Services, and ConfigMaps..."
kubectl delete -f k8s-manifests/k8s-manifests.yaml

# 2. Delete the Docker Hub Secret
# This secret is created by deploy_instructions.sh and must be explicitly deleted.
echo "🔒 Deleting Docker Hub secret 'docker-hub-secret'..."
kubectl delete secret docker-hub-secret --ignore-not-found=true

# 3. Verify all resources are deleted
echo "🔍 Verifying remaining resources with kubectl get all..."
kubectl get all

# 4. Final Confirmation
echo "-----------------------------------------------------------"
echo "✅ Kubernetes cleanup complete. The cluster is now clean."
echo "-----------------------------------------------------------"

# Disable command tracing
set +x