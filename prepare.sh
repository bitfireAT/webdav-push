#!/bin/sh
set -e

# This script installs all build dependencies locally:
# - Python dependencies in .venv/
# - Ruby gems in vendor/bundle/
# - Node.js dependencies in node_modules/
# After running this, you can run build.sh

# Python dependencies via venv
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
deactivate

# Ruby dependencies via bundler (local install)
bundle config set path 'vendor/bundle'
bundle install

# Node.js dependencies (aasvg)
npm install

echo "Dependencies installed successfully."
echo "To use them, prepend to PATH before running build.sh:"
echo "  PATH=\"$(pwd)/.venv/bin:$(pwd)/vendor/bundle/bin:$(pwd)/node_modules/.bin:\"$PATH ./build.sh"
