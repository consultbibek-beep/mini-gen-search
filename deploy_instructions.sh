#!/bin/bash
# ==============================================================================
# deploy_instructions.sh
# Automates Kubernetes deployment for the mini-gen project.
# Updated to use new service directory names:
# - frontend-service-search
# - textgen-service-rag
# ==============================================================================

# ------------------------------------------------------------------------------
# SETUP LOGGING
# ------------------------------------------------------------------------------
LOG_DIR="log"
LOG_FILE="$LOG_DIR/deploy_instr.log"

# Create the log directory if it doesn't exist
mkdir -p "$LOG_DIR" || { echo "❌ FATAL: Could not create log directory '$LOG_DIR'. Exiting."; exit 1; }

# Start logging: Redirect stdout (1) and stderr (2) to a function that uses tee
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==========================================================="
echo "🪵 Starting Deployment Logging"
echo "Log file: $LOG_FILE"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "==========================================================="

# Exit immediately if any command fails. This ensures the failure message is logged before exit.
set -e 

echo "-----------------------------------------------------------"
echo "🚀 Starting Kubernetes deployment for mini-gen-search"
echo "-----------------------------------------------------------"

# ------------------------------------------------------------------------------
# STEP 1: Archive Application Files (NEW STEP)
# ------------------------------------------------------------------------------
echo "--- STEP 1: Archive Application Files ---"

DUPLICATES_DIR="z_duplicates"
mkdir -p "$DUPLICATES_DIR" \
  || { echo "❌ **FAILURE in STEP 1:** Failed to create archive directory **$DUPLICATES_DIR**."; exit 1; }

# Copy frontend-service-search/app.py to z_duplicates/app_frontend.py
cp frontend-service-search/app.py "$DUPLICATES_DIR/app_frontend.py" \
  || { echo "❌ **FAILURE in STEP 1:** Failed to copy **frontend-service-search/app.py**."; exit 1; }
  
# Copy textgen-service-rag/app.py to z_duplicates/app_textgen.py
cp textgen-service-rag/app.py "$DUPLICATES_DIR/app_textgen.py" \
  || { echo "❌ **FAILURE in STEP 1:** Failed to copy **textgen-service-rag/app.py**."; exit 1; }

echo "✅ Application files archived to **$DUPLICATES_DIR**."

# ------------------------------------------------------------------------------
# STEP 2: Load environment variables from .env file (Original Step 1, now Step 2)
# ------------------------------------------------------------------------------
echo "--- STEP 2: Load Environment Variables ---"
if [ ! -f .env ]; then
  echo "❌ Error: .env file not found! Please create one with GROQ_API_KEY and DOCKER_HUB credentials."
  exit 1
fi

# Export variables from .env
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
# STEP 3: Create or Update Docker Hub Image Pull Secret (Original Step 2, now Step 3)
# ------------------------------------------------------------------------------
echo ""
echo "--- STEP 3: Create or Update Docker Hub Secret ---"
echo "🔑 Creating or updating Kubernetes Docker Hub Secret..."

# Create the secret. If kubectl fails, print the error and exit.
kubectl create secret docker-registry docker-hub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=$DOCKER_USERNAME \
  --docker-password=$DOCKER_PASSWORD \
  --docker-email=$DOCKER_EMAIL \
  --dry-run=client -o yaml | kubectl apply -f - \
  || { echo "❌ **FAILURE in STEP 3:** Failed to create/update Kubernetes Docker Hub Secret. Check your **kubectl context** and **DOCKER_HUB credentials**."; exit 1; }

echo "✅ Docker Hub Secret 'docker-hub-secret' created/updated."

# ------------------------------------------------------------------------------
# STEP 4: Determine UNIQUE Image Tags (Short SHAs) for Submodules (Original Step 3, now Step 4)
# ------------------------------------------------------------------------------
echo ""
echo "--- STEP 4: Determine Image Tags (SHAs) ---"
echo "Determining unique image tags (Short SHAs) for submodules..."

# Get the unique SHA for the frontend-service-search (NEW NAME)
cd frontend-service-search \
  || { echo "❌ **FAILURE in STEP 4 (Frontend):** Cannot change directory into **frontend-service-search**. Is the directory missing?"; exit 1; }
export FRONTEND_TAG=$(git rev-parse --short HEAD) \
  || { echo "❌ **FAILURE in STEP 4 (Frontend):** Failed to get Git SHA. Are you inside a Git repository (or is **frontend-service-search** a valid Git submodule)?"; exit 1; }
cd ..

# Get the unique SHA for the textgen-service-rag (NEW NAME)
cd textgen-service-rag \
  || { echo "❌ **FAILURE in STEP 4 (TextGen):** Cannot change directory into **textgen-service-rag**. Is the directory missing?"; exit 1; }
export TEXTGEN_TAG=$(git rev-parse --short HEAD) \
  || { echo "❌ **FAILURE in STEP 4 (TextGen):** Failed to get Git SHA. Are you inside a Git repository (or is **textgen-service-rag** a valid Git submodule)?"; exit 1; }
cd ..

echo "✅ Frontend image tag determined: $FRONTEND_TAG"
echo "✅ TextGen image tag determined: $TEXTGEN_TAG"

# ------------------------------------------------------------------------------
# STEP 5: Substitute environment variables and apply Kubernetes manifests (Original Step 4, now Step 5)
# ------------------------------------------------------------------------------
echo ""
echo "--- STEP 5: Apply Kubernetes Manifests ---"
echo "⚙️ Substituting variables (API Key and Image Tags) and applying Kubernetes manifests..."

# The k8s-manifests.yaml is assumed to be at the top level, as per the original script.
envsubst < k8s-manifests/k8s-manifests.yaml | kubectl apply -f - \
  || { echo "❌ **FAILURE in STEP 5:** Failed to apply Kubernetes manifests. Check if **k8s-manifests/k8s-manifests.yaml** exists and your **kubectl context** is correct."; exit 1; }

echo "✅ Kubernetes manifests applied successfully!"

# ------------------------------------------------------------------------------
# STEP 6: Verify deployment (Original Step 5, now Step 6)
# ------------------------------------------------------------------------------
echo ""
echo "--- STEP 6: Verify Deployment Status ---"
echo "⏳ Waiting for pods to start (this may take ~1 minute)..."
kubectl get pods -w

# ------------------------------------------------------------------------------
echo "✅ Deployment script finished successfully!"
echo "==========================================================="