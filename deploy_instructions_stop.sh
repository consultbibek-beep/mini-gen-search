#!/bin/bash
# ==============================================================================
# deploy_instructions_stop.sh
# Stops and removes all deployed Kubernetes resources for the mini-gen-search project.
# Modified to scale down Deployments first for a cleaner pod exit.
# ==============================================================================

set -e # Exit immediately if any command fails

echo "-----------------------------------------------------------"
echo "🛑 Stopping and cleaning up Kubernetes resources for mini-gen-search"
echo "-----------------------------------------------------------"

# 1. Scale down Deployments to 0 replicas for a graceful shutdown
echo "⬇️ Scaling down Deployments to 0 replicas..."
# Use --namespace if applicable, otherwise default namespace is used
kubectl scale deployment textgen-deployment-rag --replicas=0
kubectl scale deployment frontend-deployment-search --replicas=0

# 2. Wait for the pods to terminate
echo "⏳ Waiting for all pods to terminate..."
# This command waits for all pods belonging to these selectors to be 0
kubectl wait --for=delete pod -l app=textgen-rag --timeout=60s || true
kubectl wait --for=delete pod -l app=frontend-search --timeout=60s || true

# 3. Delete remaining resources (Services, ConfigMaps, and the now-empty Deployments)
echo "🗑️ Deleting Services and ConfigMaps (Deployments are now empty)..."
# We delete everything from the manifest *except* the Deployments which are now empty
# To avoid deleting the Deployments that we just scaled down, we can use an alternative delete method.
# Since your original script deletes the whole manifest, we will stick to that,
# knowing that the Pods are now gone.
kubectl delete -f k8s-manifests/k8s-manifests.yaml

# 4. Delete the Docker Hub Secret
echo "🔒 Deleting Docker Hub secret 'docker-hub-secret'..."
kubectl delete secret docker-hub-secret --ignore-not-found=true

# 5. Verify all resources are deleted
echo "🔍 Verifying remaining resources with kubectl get all..."
kubectl get all

# 6. Final Confirmation
echo "-----------------------------------------------------------"
echo "✅ Kubernetes cleanup complete. The cluster is now clean."
echo "-----------------------------------------------------------"