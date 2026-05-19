#!/bin/bash
#
# CLI wrapper for Brother PT-P710BT label printer using Docker
# Usage: brother-label-print.sh [ptouch-print arguments]
#
# Examples:
#   brother-label-print.sh --info
#   brother-label-print.sh --text "Hello World"
#   brother-label-print.sh --text "Line 1" "Line 2" --writepng output.png
#

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="${SCRIPT_DIR}/docker"

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    echo "Error: docker-compose or docker not found" >&2
    exit 1
fi

# Use docker compose (newer) or docker-compose (older)
if command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    DOCKER_COMPOSE_CMD="docker-compose"
fi

# Change to docker directory
cd "${DOCKER_DIR}"

# Create workspace directory if it doesn't exist
mkdir -p workspace

# Build image if it doesn't exist (only if --build flag is passed)
if [[ "$1" == "--build" ]]; then
    echo "Building Docker image..."
    ${DOCKER_COMPOSE_CMD} build
    shift  # Remove --build from arguments
fi

# Run ptouch-print in container, passing all arguments
${DOCKER_COMPOSE_CMD} run --rm ptouch-print "$@"


