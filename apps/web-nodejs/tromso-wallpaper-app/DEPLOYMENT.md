# Deployment Guide for Tromso Wallpaper App

## Quick Start

### Step 0: Configure Docker Buildx (Mac Only - One-time setup)

If you're on a Mac with Apple Silicon (M1/M2/M3), you need to configure Docker for cross-platform builds:

```bash
# Setup Docker buildx for building x86_64 images
./setup-buildx.sh
```

**Why?** Your Mac uses ARM64 architecture, but the server uses AMD64 (x86_64). Docker buildx allows building for different platforms.

### Step 1: Prepare Remote Server (One-time setup)

```bash
# Run the automated setup script
./setup-remote-server.sh
```

This will:
- ✅ Test SSH connection
- ✅ Check Docker installation
- ✅ Verify Docker permissions
- ✅ Create application directory
- ✅ Configure firewall (if needed)

### Step 2: Deploy Application

```bash
# Deploy to 192.168.1.111
./deploy.sh
```

This will:
1. Build Docker image
2. Create target directory on remote server
3. Transfer image to server
4. Load image and start container

---

## Manual Setup (If Automated Script Fails)

### On Remote Server (192.168.1.111)

1. **SSH into the server:**
   ```bash
   ssh starwave@192.168.1.111
   ```

2. **Create application directory:**
   ```bash
   sudo mkdir -p /opt/tromso-wallpaper-app
   sudo chown starwave:starwave /opt/tromso-wallpaper-app
   ```

3. **Verify Docker is installed:**
   ```bash
   docker --version
   docker compose version
   ```

   If not installed, follow instructions in `install_docker.md`

4. **Make sure your user can run Docker without sudo:**
   ```bash
   sudo usermod -aG docker starwave
   newgrp docker
   # Or log out and back in
   ```

5. **Open firewall port (if using UFW):**
   ```bash
   sudo ufw allow 3001/tcp
   sudo ufw status
   ```

### On Development Machine

1. **Set up SSH key (if not already done):**
   ```bash
   ssh-copy-id starwave@192.168.1.111
   ```

2. **Test SSH connection:**
   ```bash
   ssh starwave@192.168.1.111 'echo "Connection successful"'
   ```

3. **Deploy:**
   ```bash
   ./deploy.sh
   ```

---

## Troubleshooting Common Errors

### Error: "scp: dest open ... Failure"

**Cause**: Directory doesn't exist or no write permissions

**Solution**:
```bash
# Create directory on remote server
ssh starwave@192.168.1.111 "sudo mkdir -p /opt/tromso-wallpaper-app && sudo chown starwave:starwave /opt/tromso-wallpaper-app"
```

### Error: "permission denied while trying to connect to Docker daemon"

**Cause**: User not in docker group

**Solution**:
```bash
# On remote server
ssh starwave@192.168.1.111 "sudo usermod -aG docker starwave"
# Then log out and back in, or run:
ssh starwave@192.168.1.111 "newgrp docker"
```

### Error: "Cannot connect to Docker daemon"

**Cause**: Docker service not running

**Solution**:
```bash
# On remote server
ssh starwave@192.168.1.111 "sudo systemctl start docker && sudo systemctl enable docker"
```

### Error: "Docker build failed"

**Cause**: Various (see build output)

**Solution**:
- Check Node.js version compatibility (requires Node 20+)
- Ensure all dependencies are installed
- Review Dockerfile for syntax errors
- Check available disk space

### Error: "platform mismatch" or "exec format error"

**Cause**: Docker image built for wrong architecture (ARM64 vs AMD64)

**Solution**:
```bash
# On Mac (Apple Silicon), setup buildx
./setup-buildx.sh

# Then rebuild and deploy
./deploy.sh
```

**Manual fix**:
```bash
# Build for linux/amd64 specifically
docker buildx build --platform linux/amd64 -t tromso-wallpaper-app:latest --load .
```

---

## Verification

### Check if Container is Running

**Note**: Modern Docker uses `docker compose` (with space), older versions use `docker-compose` (with hyphen).

```bash
# From development machine (modern Docker)
ssh starwave@192.168.1.111 "cd /opt/tromso-wallpaper-app && docker compose ps"

# Or if using older Docker
ssh starwave@192.168.1.111 "cd /opt/tromso-wallpaper-app && docker-compose ps"

# Or SSH into server
ssh starwave@192.168.1.111
cd /opt/tromso-wallpaper-app
docker compose ps  # or docker-compose ps
```

### View Application Logs

```bash
# From development machine
ssh starwave@192.168.1.111 "cd /opt/tromso-wallpaper-app && docker compose logs -f"

# Or SSH into server
ssh starwave@192.168.1.111
cd /opt/tromso-wallpaper-app
docker compose logs -f
```

### Test Application

```bash
# Health check
curl http://192.168.1.111:3001/health

# Expected output:
# {"status":"ok","timestamp":"2025-10-30T..."}
```

### Access in Browser

Open: http://192.168.1.111:3001

---

## Management Commands

### On Remote Server

```bash
# SSH into server
ssh starwave@192.168.1.111
cd /opt/tromso-wallpaper-app

# Note: Use 'docker compose' (modern) or 'docker-compose' (legacy)
# The deploy script auto-detects which version you have

# Start application
docker compose up -d

# Stop application
docker compose down

# Restart application
docker compose restart

# View logs
docker compose logs -f

# View running containers
docker compose ps

# Remove old images
docker image prune -a
```

### Docker Compose Command Reference

| Modern (Docker CLI Plugin) | Legacy (Standalone) |
|---------------------------|---------------------|
| `docker compose up -d`    | `docker-compose up -d` |
| `docker compose down`     | `docker-compose down` |
| `docker compose ps`       | `docker-compose ps` |
| `docker compose logs`     | `docker-compose logs` |

**The deploy.sh script automatically detects and uses the correct command.**

---

## Update/Redeploy

When you make changes to the code:

```bash
# From development machine
./deploy.sh
```

This will:
1. Rebuild the Docker image with latest changes
2. Transfer to server
3. Restart the application

---

## Rollback

If a deployment fails:

```bash
# SSH into server
ssh starwave@192.168.1.111
cd /opt/tromso-wallpaper-app

# Stop current container
docker compose down

# List available images
docker images | grep tromso

# Load previous image (if you saved it)
docker load < /tmp/tromso-wallpaper-app-backup.tar.gz

# Start with previous version
docker compose up -d
```

---

## Security Considerations

1. **Firewall**: Only open necessary ports
   ```bash
   sudo ufw status
   sudo ufw allow 3001/tcp
   ```

2. **Docker Socket Permissions**: Don't expose Docker socket to network

3. **Update Regularly**:
   ```bash
   # Update system
   sudo apt update && sudo apt upgrade

   # Update Docker images
   docker pull node:20-alpine
   ```

4. **Use Environment Variables**: For sensitive configuration
   ```bash
   # Create .env file
   echo "API_KEY=your-secret-key" > .env

   # Reference in docker-compose.yml
   env_file:
     - .env
   ```

---

## Directory Structure on Server

```
/opt/tromso-wallpaper-app/
├── docker-compose.yml
└── (Docker will create these)
    ├── volumes/
    └── logs/
```

---

## Architecture

```
[Development Machine]
        ↓
   docker build
        ↓
   docker save
        ↓
   scp to 192.168.1.111
        ↓
[Remote Server 192.168.1.111]
        ↓
   docker load
        ↓
   docker compose up
        ↓
   App running on port 3001
```

---

## Monitoring

### Check Resource Usage

```bash
# On remote server
docker stats

# Check disk space
df -h

# Check memory
free -h
```

### Set Up Log Rotation

```bash
# Edit Docker daemon config
sudo nano /etc/docker/daemon.json
```

Add:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Restart Docker:
```bash
sudo systemctl restart docker
```

---

## Support

If you encounter issues:

1. Check logs: `docker compose logs -f`
2. Verify Docker is running: `sudo systemctl status docker`
3. Check network connectivity: `ping 192.168.1.111`
4. Verify firewall rules: `sudo ufw status`
5. Check disk space: `df -h`
