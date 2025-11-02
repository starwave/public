#!/bin/bash

# Setup script for remote server (192.168.1.111)
# Run this ONCE to prepare the server for deployment

TARGET_HOST="192.168.1.111"
TARGET_USER="starwave"
TARGET_PATH="/opt/tromso-wallpaper-app"

echo "=========================================="
echo "Remote Server Setup for Tromso Wallpaper App"
echo "=========================================="
echo ""
echo "Target: ${TARGET_USER}@${TARGET_HOST}"
echo "Path: ${TARGET_PATH}"
echo ""

# Check SSH connection
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 ${TARGET_USER}@${TARGET_HOST} "echo 'SSH connection successful'"; then
    echo "❌ ERROR: Cannot connect to ${TARGET_HOST}"
    echo "Please check:"
    echo "  1. Server is running and accessible"
    echo "  2. SSH key is set up: ssh-copy-id ${TARGET_USER}@${TARGET_HOST}"
    echo "  3. Username and hostname are correct"
    exit 1
fi
echo "✅ SSH connection working"
echo ""

# Check if Docker is installed
echo "Checking Docker installation on remote server..."
if ! ssh ${TARGET_USER}@${TARGET_HOST} "command -v docker &> /dev/null"; then
    echo "❌ Docker is not installed on ${TARGET_HOST}"
    echo ""
    echo "Please install Docker first. You can:"
    echo "  1. Copy install_docker.md to the server"
    echo "  2. Follow Ubuntu 22.04 installation instructions"
    echo "  OR run this command:"
    echo ""
    echo "  ssh ${TARGET_USER}@${TARGET_HOST} 'curl -fsSL https://get.docker.com | sudo sh && sudo usermod -aG docker ${TARGET_USER}'"
    echo ""
    exit 1
fi
echo "✅ Docker is installed"
echo ""

# Check Docker permissions
echo "Checking Docker permissions..."
if ! ssh ${TARGET_USER}@${TARGET_HOST} "docker ps &> /dev/null"; then
    echo "⚠️  User cannot run Docker commands without sudo"
    echo "Adding ${TARGET_USER} to docker group..."
    ssh ${TARGET_USER}@${TARGET_HOST} "sudo usermod -aG docker ${TARGET_USER}"
    echo "✅ User added to docker group"
    echo ""
    echo "⚠️  IMPORTANT: User needs to log out and back in for group changes to take effect"
    echo "Run: ssh ${TARGET_USER}@${TARGET_HOST} 'newgrp docker'"
    echo ""
else
    echo "✅ Docker permissions OK"
    echo ""
fi

# Create application directory
echo "Creating application directory..."
ssh ${TARGET_USER}@${TARGET_HOST} "sudo mkdir -p ${TARGET_PATH} && sudo chown ${TARGET_USER}:${TARGET_USER} ${TARGET_PATH}"
echo "✅ Directory created: ${TARGET_PATH}"
echo ""

# Check if docker compose is available
echo "Checking Docker Compose..."
if ssh ${TARGET_USER}@${TARGET_HOST} "docker compose version &> /dev/null"; then
    echo "✅ Docker Compose is available"
    echo ""
elif ssh ${TARGET_USER}@${TARGET_HOST} "docker-compose --version &> /dev/null"; then
    echo "✅ docker-compose (legacy) is available"
    echo ""
else
    echo "❌ Docker Compose is not installed"
    echo "Installing Docker Compose plugin..."
    ssh ${TARGET_USER}@${TARGET_HOST} "sudo apt-get update && sudo apt-get install -y docker-compose-plugin"
    echo "✅ Docker Compose installed"
    echo ""
fi

# Optional: Configure firewall
echo "Checking firewall status..."
if ssh ${TARGET_USER}@${TARGET_HOST} "command -v ufw &> /dev/null && sudo ufw status | grep -q 'Status: active'"; then
    echo "Firewall is active. Configuring ports..."
    ssh ${TARGET_USER}@${TARGET_HOST} "sudo ufw allow 3001/tcp comment 'Tromso Wallpaper App'"
    echo "✅ Port 3001 opened in firewall"
    echo ""
else
    echo "ℹ️  Firewall not active or not using ufw"
    echo ""
fi

# Test directory write permissions
echo "Testing write permissions..."
if ssh ${TARGET_USER}@${TARGET_HOST} "touch ${TARGET_PATH}/test.tmp && rm ${TARGET_PATH}/test.tmp"; then
    echo "✅ Write permissions OK"
    echo ""
else
    echo "❌ Cannot write to ${TARGET_PATH}"
    exit 1
fi

echo "=========================================="
echo "✅ Remote server setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Run ./deploy.sh to deploy the application"
echo "  2. Access the app at: http://${TARGET_HOST}:3001"
echo ""
echo "To check deployment status:"
echo "  ssh ${TARGET_USER}@${TARGET_HOST} 'cd ${TARGET_PATH} && docker compose ps'"
echo ""
echo "To view logs:"
echo "  ssh ${TARGET_USER}@${TARGET_HOST} 'cd ${TARGET_PATH} && docker compose logs -f'"
echo ""
