# Docker Installation Guide

This guide provides step-by-step instructions for installing Docker on Mac OSX and Ubuntu 22.04.

---

## Mac OSX Installation

### Option 1: Docker Desktop (Recommended)

1. **Download Docker Desktop**
   - Visit [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Click "Download for Mac"
   - Choose the appropriate version:
     - **Apple Silicon (M1/M2/M3)**: Download Mac with Apple chip
     - **Intel**: Download Mac with Intel chip

2. **Install Docker Desktop**
   ```bash
   # Open the downloaded .dmg file
   # Drag Docker.app to Applications folder
   # Launch Docker from Applications
   ```

3. **Verify Installation**
   ```bash
   docker --version
   docker-compose --version
   docker run hello-world
   ```

### Option 2: Homebrew Installation

```bash
# Install Docker
brew install --cask docker

# Start Docker Desktop
open /Applications/Docker.app

# Verify installation
docker --version
docker-compose --version
```

### Post-Installation (Mac)

1. **Configure Docker Resources**
   - Open Docker Desktop
   - Go to Settings → Resources
   - Adjust CPUs, Memory, and Disk as needed

2. **Enable Docker CLI without Docker Desktop running (optional)**
   ```bash
   # Add to ~/.zshrc or ~/.bash_profile
   export DOCKER_HOST=unix://$HOME/.docker/run/docker.sock
   ```

---

## Ubuntu 22.04 Installation

### Method 1: Official Docker Repository (Recommended)

1. **Update Package Index**
   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl gnupg lsb-release
   ```

2. **Add Docker's Official GPG Key**
   ```bash
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
     sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   ```

3. **Set Up the Repository**
   ```bash
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
     https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

4. **Install Docker Engine**
   ```bash
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
     docker-buildx-plugin docker-compose-plugin
   ```

5. **Verify Installation**
   ```bash
   sudo docker --version
   sudo docker compose version
   sudo docker run hello-world
   ```

### Method 2: Convenience Script

```bash
# Download and run Docker installation script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Verify installation
sudo docker --version
```

### Post-Installation (Ubuntu)

1. **Manage Docker as Non-Root User**
   ```bash
   # Create docker group
   sudo groupadd docker

   # Add your user to docker group
   sudo usermod -aG docker $USER

   # Activate changes
   newgrp docker

   # Verify - should work without sudo
   docker run hello-world
   ```

2. **Configure Docker to Start on Boot**
   ```bash
   sudo systemctl enable docker.service
   sudo systemctl enable containerd.service
   ```

3. **Optional: Configure Docker Daemon**
   ```bash
   # Create or edit daemon.json
   sudo nano /etc/docker/daemon.json
   ```

   Add configuration:
   ```json
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     },
     "storage-driver": "overlay2"
   }
   ```

   Restart Docker:
   ```bash
   sudo systemctl restart docker
   ```

---

## Common Docker Commands

### Basic Commands
```bash
# Check Docker version
docker --version

# Check Docker info
docker info

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# List images
docker images

# Pull an image
docker pull nginx

# Run a container
docker run -d -p 80:80 nginx

# Stop a container
docker stop <container-id>

# Remove a container
docker rm <container-id>

# Remove an image
docker rmi <image-id>
```

### Docker Compose Commands
```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Rebuild and start
docker compose up -d --build

# List running services
docker compose ps
```

---

## Troubleshooting

### Mac OSX

**Issue**: Docker Desktop won't start
```bash
# Reset Docker Desktop
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/Library/Application\ Support/Docker\ Desktop
# Reinstall Docker Desktop
```

**Issue**: Permission denied when running Docker
```bash
# Restart Docker Desktop from Applications
# Or restart your terminal
```

### Ubuntu

**Issue**: Permission denied when running Docker
```bash
# Make sure you're in the docker group
groups
# Should show 'docker' in the list

# If not, add yourself again
sudo usermod -aG docker $USER
newgrp docker
```

**Issue**: Docker daemon not starting
```bash
# Check Docker status
sudo systemctl status docker

# View logs
sudo journalctl -u docker.service

# Restart Docker
sudo systemctl restart docker
```

**Issue**: Cannot connect to Docker daemon
```bash
# Start Docker service
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker
```

---

## Deployment to Remote Server (192.168.1.111)

### On Ubuntu Server (192.168.1.111)

1. **Install Docker** (follow Ubuntu 22.04 instructions above)

2. **Enable Docker Remote Access** (optional, for remote management)
   ```bash
   # Edit Docker service
   sudo systemctl edit docker.service

   # Add:
   [Service]
   ExecStart=
   ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375

   # Reload and restart
   sudo systemctl daemon-reload
   sudo systemctl restart docker
   ```

3. **Configure Firewall**
   ```bash
   # Allow Docker ports
   sudo ufw allow 2375/tcp
   sudo ufw allow 3001/tcp
   ```

### From Development Machine

1. **Set up SSH access**
   ```bash
   # Copy SSH key to server
   ssh-copy-id starwave@192.168.1.111
   ```

2. **Deploy using the deployment script**
   ```bash
   # Make sure deploy.sh is executable
   chmod +x deploy.sh

   # Run deployment
   ./deploy.sh
   ```

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
