#!/bin/bash
# Script để chạy crawler với virtual environment

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Activate or create virtual environment
if [ ! -d "venv" ]; then
    print_info "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    print_info "Installing dependencies..."
    pip install --upgrade pip --quiet
    pip install -r requirements.txt --quiet
    print_info "Virtual environment created successfully!"
else
    source venv/bin/activate
fi

# Check if requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    print_warn "requirements.txt not found. Creating default requirements.txt..."
    echo "requests>=2.32.0" > requirements.txt
fi

# Install/upgrade dependencies if needed
if ! python -c "import requests" 2>/dev/null; then
    print_info "Installing missing dependencies..."
    pip install --upgrade pip --quiet
    pip install -r requirements.txt --quiet
fi

# Check if crawl_dav_api.py exists
if [ ! -f "crawl_dav_api.py" ]; then
    print_error "crawl_dav_api.py not found in $(pwd)"
    exit 1
fi

# Default API URL if not provided
DEFAULT_API_URL="http://localhost:8080"

# Check if --api-url is provided
HAS_API_URL=false
HAS_UPLOAD=false

for arg in "$@"; do
    if [[ "$arg" == "--api-url"* ]]; then
        HAS_API_URL=true
    fi
    if [[ "$arg" == "--upload" ]]; then
        HAS_UPLOAD=true
    fi
done

# Build arguments array
ARGS=("$@")

# If upload is requested but no API URL provided, use default
if [ "$HAS_UPLOAD" = true ] && [ "$HAS_API_URL" = false ]; then
    print_info "Using default API URL: $DEFAULT_API_URL"
    print_info "You can override with: --api-url <url>"
    ARGS+=("--api-url" "$DEFAULT_API_URL")
fi

# Run crawler with all arguments
print_info "Running crawler..."
python crawl_dav_api.py "${ARGS[@]}"

