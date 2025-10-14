#!/bin/bash

# Docker installation script for Ubuntu 22.04
# Run this on the server: ssh starwave@192.168.1.111 'bash -s' < install-docker.sh

echo "🐳 Installing Docker on Ubuntu 22.04..."

# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

echo "✅ Docker installation complete!"
echo "⚠️  Please log out and log back in for group membership to take effect"
echo "    Or run: newgrp docker"
echo ""
echo "🐳 Docker version:"
docker --version

echo ""
echo "🎯 Docker Compose version:"
docker compose version
