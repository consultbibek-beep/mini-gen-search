#!/bin/bash
# ==============================================================================
# deploy_instructions.sh
# Automates Kubernetes deployment for the mini-gen project using envsubst.
# ------------------------------------------------------------------------------
# Features:
#  - Loads environment variables from .env file
#  - Verifies Docker images exist (or builds if missing)
#  - Substitutes $GROQ_API_KEY into Kubernetes manifests using envsubst
#  - Applies manifests to Kubernetes cluster
#  - Displays deployment status
# ==============================================================================

set -e  # Exit immediately if any command fails

echo "-----------------------------------------------------------"
echo "🚀 Starting Kubernetes deployment for mini-gen"
echo "-----------------------------------------------------------"

# ------------------------------------------------------------------------------
# STEP 1: Load environment variables from .env file
# ------------------------------------------------------------------------------
if [ ! -f .env ]; then
  echo "❌ Error: .env file not found! Please create one with GROQ_API_KEY."
  exit 1
fi

# Export variables from .env (ignores commented lines starting with #)
export $(grep -v '^#' .env | xargs)
echo "✅ Environment variables loaded from .env"

# ------------------------------------------------------------------------------
# STEP 2: Check if required Docker images exist (build if missing)
# ------------------------------------------------------------------------------
check_image() {
  local image=$1
  local path=$2

  if docker images | grep -q "$image"; then
    echo "✅ Found local image: $image"
  else
    echo "⚙️ Image $image not found. Building now..."
    docker build -t "$image" "$path"
  fi
}

# Ensure both images are present or built
check_image "mini-gen/textgen:latest" "./textgen-service"
check_image "mini-gen/frontend:latest" "./frontend-service"

# ------------------------------------------------------------------------------
# STEP 3: Substitute environment variables and apply Kubernetes manifests
# ------------------------------------------------------------------------------
echo "⚙️ Substituting variables and applying Kubernetes manifests..."
envsubst < k8s-manifests/k8s-manifests.yaml | kubectl apply -f -

echo "✅ Kubernetes manifests applied successfully!"

# ------------------------------------------------------------------------------
# STEP 4: Verify deployment
# ------------------------------------------------------------------------------
echo "⏳ Waiting for pods to start (this may take ~1 minute)..."
kubectl get pods -w
