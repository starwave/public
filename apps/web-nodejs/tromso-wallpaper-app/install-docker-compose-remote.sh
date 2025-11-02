#!/bin/bash

# Install Docker Compose plugin on remote server (192.168.1.111)
# Run this if you get "docker-compose: command not found" error

TARGET_HOST="192.168.1.111"
TARGET_USER="starwave"

echo "=========================================="
echo "Installing Docker Compose on ${TARGET_HOST}"
echo "=========================================="
echo ""

# Check SSH connection
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 ${TARGET_USER}@${TARGET_HOST} "echo 'Connected'"; then
    echo "❌ ERROR: Cannot connect to ${TARGET_HOST}"
    exit 1
fi
echo "✅ SSH connection working"
echo ""

# Check if Docker is installed
echo "Checking Docker installation..."
if ! ssh ${TARGET_USER}@${TARGET_HOST} "command -v docker &> /dev/null"; then
    echo "❌ ERROR: Docker is not installed on ${TARGET_HOST}"
    echo "Please install Docker first. See install_docker.md"
    exit 1
fi
echo "✅ Docker is installed"
echo ""

# Check which Docker Compose version is available
echo "Checking Docker Compose availability..."

if ssh ${TARGET_USER}@${TARGET_HOST} "docker compose version &> /dev/null"; then
    echo "✅ Docker Compose plugin is already installed"
    VERSION=$(ssh ${TARGET_USER}@${TARGET_HOST} "docker compose version")
    echo "   Version: ${VERSION}"
    exit 0
fi

if ssh ${TARGET_USER}@${TARGET_HOST} "docker-compose --version &> /dev/null"; then
    echo "ℹ️  Legacy docker-compose is installed"
    VERSION=$(ssh ${TARGET_USER}@${TARGET_HOST} "docker-compose --version")
    echo "   Version: ${VERSION}"
    echo ""
    echo "Consider upgrading to Docker Compose plugin (v2)"
fi

echo ""
echo "Installing Docker Compose plugin..."
echo ""

# For Ubuntu/Debian
ssh ${TARGET_USER}@${TARGET_HOST} "sudo apt-get update && sudo apt-get install -y docker-compose-plugin"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Docker Compose plugin installed successfully!"
    echo ""
    VERSION=$(ssh ${TARGET_USER}@${TARGET_HOST} "docker compose version")
    echo "Version: ${VERSION}"
    echo ""
    echo "You can now use: docker compose"
else
    echo ""
    echo "❌ Installation failed"
    echo ""
    echo "Try manual installation:"
    echo "  ssh ${TARGET_USER}@${TARGET_HOST}"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y docker-compose-plugin"
    echo ""
    echo "Or install standalone docker-compose:"
    echo "  sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
    echo "  sudo chmod +x /usr/local/bin/docker-compose"
    exit 1
fi
