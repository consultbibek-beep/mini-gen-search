#!/bin/bash
# ==============================================================================
# deploy_instructions_local.sh
# Automates local Docker build and testing using docker-compose.local.yaml
# Uses the 'local-test' tag convention.
# ==============================================================================

# ------------------------------------------------------------------------------
# SETUP LOGGING
# ------------------------------------------------------------------------------
LOG_DIR="log"
LOG_FILE="$LOG_DIR/deploy_instr_local.log"
COMPOSE_FILE="docker-compose.local.yaml"
LOCAL_TAG="local-test"
DOCKER_USER="consultbibek" # Use your known Docker Hub prefix

# Create the log directory if it doesn't exist
mkdir -p "$LOG_DIR" || { echo "❌ FATAL: Could not create log directory '$LOG_DIR'. Exiting."; exit 1; }

# Start logging: Redirect stdout (1) and stderr (2) to a function that uses tee
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==========================================================="
echo "🪵 Starting LOCAL Deployment Logging"
echo "Log file: $LOG_FILE"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "==========================================================="

# Exit immediately if any command fails.
set -e 

echo "-----------------------------------------------------------"
echo "🛠️ Starting Local Docker Build and Compose Deployment"
echo "-----------------------------------------------------------"

# ------------------------------------------------------------------------------
# STEP 1: Archive Application Files (RETAINED FOR CONSISTENCY)
# ------------------------------------------------------------------------------
echo "--- STEP 1: Archive Application Files ---"

DUPLICATES_DIR="z_duplicates"
# Note: This step is kept as is from the original script for safety/consistency,
# even though local deployment doesn't strictly depend on it.
mkdir -p "$DUPLICATES_DIR" || { echo "❌ **FAILURE in STEP 1:** Failed to create archive directory **$DUPLICATES_DIR**."; exit 1; }

cp frontend-service-search/app.py "$DUPLICATES_DIR/app_frontend.py" || { echo "❌ **FAILURE in STEP 1:** Failed to copy **frontend-service-search/app.py**."; exit 1; }
cp textgen-service-rag/app.py "$DUPLICATES_DIR/app_textgen.py" || { echo "❌ **FAILURE in STEP 1:** Failed to copy **textgen-service-rag/app.py**."; exit 1; }
cp frontend-service-search/Dockerfile "$DUPLICATES_DIR/Dockerfile_frontend" || { echo "❌ **FAILURE in STEP 1:** Failed to copy **frontend-service-search/Dockerfile**."; exit 1; }
cp textgen-service-rag/Dockerfile "$DUPLICATES_DIR/Dockerfile_textgen" || { echo "❌ **FAILURE in STEP 1:** Failed to copy **textgen-service-rag/Dockerfile**."; exit 1; }

echo "✅ Application files and Dockerfiles archived to **$DUPLICATES_DIR**."

# ------------------------------------------------------------------------------
# STEP 2: Load environment variables from .env file (Only GROQ_API_KEY required)
# ------------------------------------------------------------------------------
echo "--- STEP 2: Load Environment Variables ---"
if [ ! -f .env ]; then
  echo "❌ Error: .env file not found! Please create one with GROQ_API_KEY."
  exit 1
fi

# Export variables from .env
# Note: Only GROQ_API_KEY is needed for local compose run
export $(grep -v '^#' .env | grep 'GROQ_API_KEY' | xargs)
echo "✅ Environment variables loaded from .env"

# Ensure required variable is set
if [ -z "$GROQ_API_KEY" ]; then
  echo "❌ Error: GROQ_API_KEY not set in .env."
  exit 1
fi

# ------------------------------------------------------------------------------
# STEP 3: Build Local Docker Images (Replaces Docker Hub Secret)
# ------------------------------------------------------------------------------
echo ""
echo "--- STEP 3: Build Local Docker Images ---"
echo "🏗️ Building new images with tag **:$LOCAL_TAG**..."

# 3a. Build TextGen Service Image
TEXTGEN_IMAGE="$DOCKER_USER/mini-gen-textgen-rag:$LOCAL_TAG"
echo "Building $TEXTGEN_IMAGE..."
docker build -t "$TEXTGEN_IMAGE" ./textgen-service-rag \
  || { echo "❌ **FAILURE in STEP 3 (TextGen):** Failed to build Docker image."; exit 1; }
echo "✅ Built $TEXTGEN_IMAGE"

# 3b. Build Frontend Service Image
FRONTEND_IMAGE="$DOCKER_USER/mini-gen-frontend-search:$LOCAL_TAG"
echo "Building $FRONTEND_IMAGE..."
docker build -t "$FRONTEND_IMAGE" ./frontend-service-search \
  || { echo "❌ **FAILURE in STEP 3 (Frontend):** Failed to build Docker image."; exit 1; }
echo "✅ Built $FRONTEND_IMAGE"

# ------------------------------------------------------------------------------
# STEP 4: Deploy with Docker Compose (Replaces K8s Manifests)
# ------------------------------------------------------------------------------
echo ""
echo "--- STEP 4: Deploy with Docker Compose ---"
echo "🚀 Applying local deployment using **$COMPOSE_FILE**..."

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "❌ Error: Docker Compose file **$COMPOSE_FILE** not found! Please create it."
  exit 1
fi

# Run the local stack (Qdrant, TextGen, Frontend)
docker compose -f "$COMPOSE_FILE" up -d \
  || { echo "❌ **FAILURE in STEP 4:** Failed to start containers via Docker Compose. Check logs for details."; exit 1; }

echo "✅ Local services started successfully! Access the frontend at http://localhost"

# ------------------------------------------------------------------------------
# STEP 5: Verify Local Deployment (Replaces K8s Pod Watch)
# ------------------------------------------------------------------------------
echo ""
echo "--- STEP 5: Verify Local Deployment Status ---"
echo "⏳ Waiting for containers to be ready..."

# Wait for all services to be running
sleep 5 # Give services a few seconds to start

docker compose -f "$COMPOSE_FILE" ps 

# Note: Manual testing at http://localhost is the best verification,
# but 'docker compose ps' shows their status.

# ------------------------------------------------------------------------------
echo "✅ Local testing environment is ready. Remember to run 'docker compose -f $COMPOSE_FILE down' when finished."
echo "==========================================================="