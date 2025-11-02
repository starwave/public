# Troubleshooting Guide - Platform Mismatch Issue

## Problem Summary

When deploying from a Mac with Apple Silicon (M1/M2/M3) to a Linux server, you may encounter:

```
The requested image's platform (linux/arm64) does not match
the detected host platform (linux/amd64/v2)
exec /usr/local/bin/docker-entrypoint.sh: exec format error
```

## Root Cause

- **Your Mac**: Uses ARM64 (Apple Silicon) architecture
- **Server (192.168.1.111)**: Uses AMD64/x86_64 architecture
- **Issue**: Docker builds images for the host platform by default

When you build on ARM64 and deploy to AMD64, the binary formats are incompatible.

## Solution

### The Fix Applied

1. **Docker Buildx Configuration**
   - Enables cross-platform builds
   - Allows building AMD64 images on ARM64 Mac

2. **Updated deploy.sh**
   - Now builds specifically for `linux/amd64`
   - Uses: `docker buildx build --platform linux/amd64`

3. **Created setup-buildx.sh**
   - One-time setup script
   - Configures Docker for multi-platform builds

## How to Use

### First Time Setup

```bash
# 1. Configure Docker buildx (Mac only - one time)
./setup-buildx.sh

# 2. Setup remote server (one time)
./setup-remote-server.sh

# 3. Deploy
./deploy.sh
```

### Subsequent Deployments

```bash
# Just run deploy
./deploy.sh
```

## Verification

After deployment, verify the correct architecture:

```bash
# Check running container
ssh starwave@192.168.1.111 "cd /opt/tromso-wallpaper-app && docker compose ps"

# Verify architecture
ssh starwave@192.168.1.111 "docker image inspect tromso-wallpaper-app:latest --format='{{.Architecture}}'"
# Should output: amd64

# Test application
curl http://192.168.1.111:3001/health
# Should return: {"status":"ok","timestamp":"..."}
```

## What Was Fixed

### Files Modified

1. **deploy.sh**
   ```bash
   # Before
   docker build -t ${IMAGE_NAME}:latest .

   # After
   docker buildx build --platform linux/amd64 -t ${IMAGE_NAME}:latest --load .
   ```

2. **docker-compose.yml**
   ```yaml
   # Before
   services:
     tromso-wallpaper-app:
       build:
         context: .
         dockerfile: Dockerfile

   # After
   services:
     tromso-wallpaper-app:
       image: tromso-wallpaper-app:latest
   ```

### Files Created

1. **setup-buildx.sh** - Docker buildx configuration
2. **docker-compose.dev.yml** - Local development with build
3. **TROUBLESHOOTING.md** - This file
4. **Updated DEPLOYMENT.md** - Added platform instructions
5. **Updated README.md** - Added prerequisites

## Understanding Platform Architectures

### Common Architectures

| Architecture | Also Known As | Used By |
|--------------|---------------|---------|
| ARM64 | aarch64 | Apple Silicon Macs (M1/M2/M3), Raspberry Pi 4+, AWS Graviton |
| AMD64 | x86_64, x64 | Most Intel/AMD CPUs, Most cloud servers |
| ARM/v7 | armhf | Older Raspberry Pi models |

### Your Setup

- **Development Machine**: ARM64 (Apple Silicon Mac)
- **Production Server**: AMD64 (Linux x86_64)
- **Required**: Cross-platform build capability

## Docker Buildx Benefits

With buildx configured, you can:

1. **Build for Multiple Platforms**
   ```bash
   docker buildx build --platform linux/amd64,linux/arm64 -t myapp .
   ```

2. **Target Specific Platform**
   ```bash
   docker buildx build --platform linux/amd64 -t myapp --load .
   ```

3. **List Supported Platforms**
   ```bash
   docker buildx inspect
   ```

## Best Practices

### For Development

1. Always test locally first:
   ```bash
   docker compose -f docker-compose.dev.yml up --build
   ```

2. Verify platform before deploying:
   ```bash
   docker image inspect tromso-wallpaper-app:latest --format='{{.Architecture}}'
   ```

### For Production

1. Build for target platform explicitly:
   ```bash
   docker buildx build --platform linux/amd64 -t myapp --load .
   ```

2. Test on similar architecture when possible

3. Keep buildx configured and up to date

## Common Errors and Solutions

### Error 1: "buildx: command not found"

**Solution**: Update Docker Desktop to latest version
```bash
# Check Docker version
docker --version

# Should be Docker 19.03 or newer
```

### Error 2: "multiple platforms feature is currently not supported"

**Solution**: Create and use a buildx builder
```bash
docker buildx create --name multiplatform --use
docker buildx inspect --bootstrap
```

### Error 3: "failed to solve with frontend dockerfile.v0"

**Solution**: Enable experimental features in Docker Desktop
- Docker Desktop → Settings → Docker Engine
- Add: `"experimental": true`

### Error 4: Container starts but immediately exits

**Check Logs**:
```bash
ssh starwave@192.168.1.111 "docker logs tromso-wallpaper-app"
```

**Common Causes**:
- Wrong architecture (check with `docker image inspect`)
- Missing environment variables
- Port already in use

## Additional Resources

- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [Multi-platform Images](https://docs.docker.com/build/building/multi-platform/)
- [Apple Silicon and Docker](https://docs.docker.com/desktop/mac/apple-silicon/)

## Quick Reference

### Deploy Checklist

- [ ] Docker buildx configured (Mac only)
- [ ] Remote server has Docker installed
- [ ] SSH access to server configured
- [ ] Firewall allows port 3001
- [ ] Build completes without errors
- [ ] Image loaded on remote server
- [ ] Container starts successfully
- [ ] Health endpoint responds
- [ ] Application accessible in browser

### Deployment Commands

```bash
# Full deployment from scratch
./setup-buildx.sh        # Mac only, one time
./setup-remote-server.sh # One time
./deploy.sh              # Every deployment

# Check deployment
ssh starwave@192.168.1.111 "cd /opt/tromso-wallpaper-app && docker compose ps"
curl http://192.168.1.111:3001/health

# View logs
ssh starwave@192.168.1.111 "cd /opt/tromso-wallpaper-app && docker compose logs -f"

# Restart
ssh starwave@192.168.1.111 "cd /opt/tromso-wallpaper-app && docker compose restart"

# Stop
ssh starwave@192.168.1.111 "cd /opt/tromso-wallpaper-app && docker compose down"
```

---

## Success Indicators

After successful deployment, you should see:

1. ✅ Container status: "Up" (not "Restarting")
2. ✅ Architecture: amd64 (not arm64)
3. ✅ Health check: Returns {"status":"ok"}
4. ✅ Browser access: http://192.168.1.111:3001 loads
5. ✅ Logs show: "Server running on http://localhost:3001"

Your deployment is successful when all indicators are ✅!
