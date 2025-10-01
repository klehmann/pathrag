#!/usr/bin/env bash

# Strict mode: exit on error, unset vars, and failed pipelines
set -Eeuo pipefail
trap 'echo -e "\033[1;33mError on line $LINENO. Aborting.\033[0m"; exit 1' ERR

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Always run relative to this script's directory (project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration (override via env vars if desired)
CONDA_ENV_NAME="${CONDA_ENV_NAME:-pathrag39}"
PYTHON_VERSION="${PYTHON_VERSION:-3.9}"

echo -e "${GREEN}Starting PathRAG API with conda...${NC}"

# Ensure conda is available
if ! command -v conda >/dev/null 2>&1; then
  echo -e "${YELLOW}Conda is not installed or not on PATH. Please install Miniconda/Anaconda and try again.${NC}"
  exit 1
fi

# Initialize conda for this shell
# shellcheck disable=SC1090
eval "$(conda shell.bash hook)"

# Create env if it doesn't exist
if ! conda env list | awk '{print $1}' | grep -qx "$CONDA_ENV_NAME"; then
  echo -e "${YELLOW}Conda env '$CONDA_ENV_NAME' not found. Creating with Python ${PYTHON_VERSION}...${NC}"
  conda create -y -n "$CONDA_ENV_NAME" python="${PYTHON_VERSION}"
  echo -e "${GREEN}Conda env '$CONDA_ENV_NAME' created.${NC}"
fi

# Activate env
echo -e "${BLUE}Activating conda env '$CONDA_ENV_NAME'...${NC}"
conda activate "$CONDA_ENV_NAME"
python -V

# Install backend dependencies (fail fast if anything fails)
echo -e "${BLUE}Installing backend dependencies into '$CONDA_ENV_NAME'...${NC}"
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

echo -e "${GREEN}Backend dependencies installed in '$CONDA_ENV_NAME'.${NC}"

# Start backend API using the env's Python (safer than relying on PATH for uvicorn)
echo -e "${BLUE}Starting backend API on port 8000...${NC}"
exec python -m uvicorn main:app --host 0.0.0.0 --port 8000
