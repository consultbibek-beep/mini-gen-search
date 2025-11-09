#!/bin/bash
# ==============================================================================
# deploy_instructions.sh
# Automates Kubernetes deployment for the mini-gen project.
# Uses unique Git SHAs for image tags and Docker Hub PAT for authentication.
# ==============================================================================

set -e # Exit immediately if any command fails

echo "-----------------------------------------------------------"
echo "🚀 Starting Kubernetes deployment for mini-gen"
echo "-----------------------------------------------------------"

# ------------------------------------------------------------------------------
# STEP 1: Load environment variables from .env file
# ------------------------------------------------------------------------------
if [ ! -f .env ]; then
  echo "❌ Error: .env file not found! Please create one with GROQ_API_KEY and DOCKER_HUB credentials."
  exit 1
fi

# Export variables from .env (including DOCKER_USERNAME/PASSWORD/EMAIL)
export $(grep -v '^#' .env | xargs)
echo "✅ Environment variables loaded from .env"

# Ensure required variables are set
if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ] || [ -z "$DOCKER_EMAIL" ]; then
  echo "❌ Error: DOCKER_USERNAME, DOCKER_PASSWORD (PAT), or DOCKER_EMAIL not set in .env."
  exit 1
fi
if [ -z "$GROQ_API_KEY" ]; then
  echo "❌ Error: GROQ_API_KEY not set in .env."
  exit 1
fi

# ------------------------------------------------------------------------------
# STEP 2: Create or Update Docker Hub Image Pull Secret
# ------------------------------------------------------------------------------
echo "🔑 Creating or updating Kubernetes Docker Hub Secret..."

# Create the secret using the PAT in DOCKER_PASSWORD. 
# We use --dry-run and pipe to kubectl apply to ensure it's created or updated safely.
kubectl create secret docker-registry docker-hub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=$DOCKER_USERNAME \
  --docker-password=$DOCKER_PASSWORD \
  --docker-email=$DOCKER_EMAIL \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Docker Hub Secret 'docker-hub-secret' created/updated."

# ------------------------------------------------------------------------------
# STEP 3: Determine UNIQUE Image Tags (Short SHAs) for Submodules
# ------------------------------------------------------------------------------
echo "Determining unique image tags (Short SHAs) for submodules..."

# Get the unique SHA for the frontend-service
cd frontend-service
export FRONTEND_TAG=$(git rev-parse --short HEAD)
cd ..

# Get the unique SHA for the textgen-service
cd textgen-service
export TEXTGEN_TAG=$(git rev-parse --short HEAD)
cd ..

echo "✅ Frontend image tag determined: $FRONTEND_TAG"
echo "✅ TextGen image tag determined: $TEXTGEN_TAG"

# ------------------------------------------------------------------------------
# STEP 4: Substitute environment variables and apply Kubernetes manifests
# ------------------------------------------------------------------------------
echo "⚙️ Substituting variables (API Key and Image Tags) and applying Kubernetes manifests..."

# envsubst replaces $GROQ_API_KEY, $FRONTEND_TAG, and $TEXTGEN_TAG in the manifest
envsubst < k8s-manifests/k8s-manifests.yaml | kubectl apply -f -

echo "✅ Kubernetes manifests applied successfully!"

# ------------------------------------------------------------------------------
# STEP 5: Verify deployment
# ------------------------------------------------------------------------------
echo "⏳ Waiting for pods to start (this may take ~1 minute)..."
kubectl get pods -w