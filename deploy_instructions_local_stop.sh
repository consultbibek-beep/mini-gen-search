#!/bin/bash
# ==============================================================================
# deploy_instructions_local_stop.sh
# Stops and removes all containers, networks, and volumes for the local mini-gen-search project.
# ==============================================================================

set -e # Exit immediately if any command fails

COMPOSE_FILE="docker-compose.local.yaml"

echo "-----------------------------------------------------------"
echo "🛑 Stopping and cleaning up local Docker Compose resources"
echo "-----------------------------------------------------------"

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "❌ Error: Docker Compose file **$COMPOSE_FILE** not found! Cannot stop services."
  exit 1
fi

# Use 'down --volumes' to remove containers, networks, and the Qdrant data volume (qdrant_storage)
echo "⬇️ Stopping and removing containers, networks, and volumes defined in $COMPOSE_FILE..."
docker compose -f "$COMPOSE_FILE" down --volumes \
  || { echo "❌ **FAILURE:** Failed to stop containers. Check Docker status."; exit 1; }

# Verify cleanup
echo "🔍 Verifying remaining containers..."
docker compose -f "$COMPOSE_FILE" ps || true # Ignore failure if no services exist

echo "-----------------------------------------------------------"
echo "✅ Local Docker Compose cleanup complete. The environment is clean."
echo "-----------------------------------------------------------"