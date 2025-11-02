# Deployment Guide - Tromso Wallpaper App (Ruby)

Complete deployment instructions for production environments.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Local Deployment](#local-deployment)
- [Docker Deployment](#docker-deployment)
- [Remote Server Deployment](#remote-server-deployment)
- [Systemd Service](#systemd-service)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

- **Ruby**: 3.0 or higher
- **OS**: Ubuntu 22.04 LTS or macOS 12+
- **RAM**: 512MB minimum, 1GB recommended
- **Disk**: 100MB for application

### Software Requirements

- Ruby 3.0+
- Bundler 2.0+
- Git
- (Optional) Docker for containerized deployment

---

## Local Deployment

### Step 1: Prepare Application

```bash
# Navigate to project
cd /path/to/tromso-wallpaper-app

# Copy environment file
cp .env.example .env

# Edit configuration
nano .env
```

### Step 2: Install Dependencies

```bash
bundle install --deployment --without development test
```

### Step 3: Build Frontend (if applicable)

```bash
# If you have a separate frontend build process
# Copy built files to public/ directory
cp -r /path/to/frontend/dist/* public/
```

### Step 4: Run Application

```bash
# Production mode
RACK_ENV=production bundle exec puma -C config/puma.rb

# Or using systemd (see below)
```

---

## Docker Deployment

### Build Docker Image

```bash
# For local platform
docker build -t tromso-wallpaper-app-ruby:latest .

# For specific platform (e.g., AMD64 for servers)
docker buildx build --platform linux/amd64 -t tromso-wallpaper-app-ruby:latest --load .
```

### Run Docker Container

```bash
# Run locally
docker run -d -p 3001:3001 \
  --name tromso-wallpaper-app \
  -e RACK_ENV=production \
  tromso-wallpaper-app-ruby:latest

# Or using docker-compose
docker compose up -d
```

### Test Container

```bash
# Check status
docker ps | grep tromso

# View logs
docker logs tromso-wallpaper-app

# Test endpoint
curl http://localhost:3001/health
```

---

## Remote Server Deployment

### Method 1: Direct Installation

#### On Remote Server (192.168.1.111)

```bash
# SSH into server
ssh starwave@192.168.1.111

# Install Ruby (if not installed)
# See INSTALL.md for detailed instructions

# Clone or copy application
git clone <repository-url> /opt/tromso-wallpaper-app
# Or use scp/rsync to copy files

# Install dependencies
cd /opt/tromso-wallpaper-app
bundle install --deployment --without development test

# Create log directory
mkdir -p log

# Start application (see systemd section below)
```

### Method 2: Docker Deployment

#### On Development Machine

```bash
# Build for AMD64
docker buildx build --platform linux/amd64 -t tromso-wallpaper-app-ruby:latest --load .

# Save image
docker save tromso-wallpaper-app-ruby:latest | gzip > tromso-app-ruby.tar.gz

# Transfer to server
scp tromso-app-ruby.tar.gz starwave@192.168.1.111:/tmp/
scp docker-compose.yml starwave@192.168.1.111:/opt/tromso-wallpaper-app/
```

#### On Remote Server

```bash
# Load image
docker load < /tmp/tromso-app-ruby.tar.gz

# Start container
cd /opt/tromso-wallpaper-app
docker compose up -d

# Verify
docker ps
curl http://localhost:3001/health
```

---

## Systemd Service

### Create Service File

```bash
sudo nano /etc/systemd/system/tromso-wallpaper-app.service
```

Add the following:

```ini
[Unit]
Description=Tromso Wallpaper App (Ruby)
After=network.target

[Service]
Type=simple
User=starwave
Group=starwave
WorkingDirectory=/opt/tromso-wallpaper-app

Environment="RACK_ENV=production"
Environment="PORT=3001"
Environment="WEB_CONCURRENCY=2"
Environment="MAX_THREADS=5"

ExecStart=/home/starwave/.rbenv/shims/bundle exec puma -C config/puma.rb
ExecReload=/bin/kill -USR1 $MAINPID

Restart=always
RestartSec=10
StandardOutput=append:/opt/tromso-wallpaper-app/log/puma_access.log
StandardError=append:/opt/tromso-wallpaper-app/log/puma_error.log

[Install]
WantedBy=multi-user.target
```

### Enable and Start Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable tromso-wallpaper-app

# Start service
sudo systemctl start tromso-wallpaper-app

# Check status
sudo systemctl status tromso-wallpaper-app

# View logs
sudo journalctl -u tromso-wallpaper-app -f
```

### Manage Service

```bash
# Start
sudo systemctl start tromso-wallpaper-app

# Stop
sudo systemctl stop tromso-wallpaper-app

# Restart
sudo systemctl restart tromso-wallpaper-app

# Reload (zero-downtime)
sudo systemctl reload tromso-wallpaper-app

# Status
sudo systemctl status tromso-wallpaper-app

# View logs
sudo journalctl -u tromso-wallpaper-app --since "1 hour ago"
```

---

## Nginx Reverse Proxy

### Install Nginx

```bash
sudo apt-get install -y nginx
```

### Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/tromso-wallpaper-app
```

Add configuration:

```nginx
upstream tromso_app {
    server 127.0.0.1:3001 fail_timeout=0;
}

server {
    listen 80;
    server_name 192.168.1.111;  # or your domain

    root /opt/tromso-wallpaper-app/public;

    location / {
        proxy_pass http://tromso_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/tromso-wallpaper-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## Monitoring

### Check Application Health

```bash
# Health endpoint
curl http://localhost:3001/health

# Full status
systemctl status tromso-wallpaper-app
```

### View Logs

```bash
# Application logs
tail -f /opt/tromso-wallpaper-app/log/puma_access.log
tail -f /opt/tromso-wallpaper-app/log/puma_error.log

# Systemd logs
sudo journalctl -u tromso-wallpaper-app -f

# Nginx logs (if using reverse proxy)
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### Performance Monitoring

```bash
# Process stats
ps aux | grep puma

# Memory usage
free -h

# Disk usage
df -h

# Network connections
netstat -tulpn | grep :3001
```

---

## Scaling

### Increase Workers

Edit `config/puma.rb`:

```ruby
workers ENV.fetch('WEB_CONCURRENCY', 4).to_i
```

Or set environment variable:

```bash
WEB_CONCURRENCY=4 bundle exec puma -C config/puma.rb
```

### Increase Threads

```bash
MAX_THREADS=10 bundle exec puma -C config/puma.rb
```

### Use jemalloc

```bash
# Install jemalloc
sudo apt-get install -y libjemalloc-dev

# Run with jemalloc
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2 \
  bundle exec puma -C config/puma.rb
```

---

## Security

### Firewall Configuration

```bash
# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS
sudo ufw allow 443/tcp

# Allow SSH (if not already)
sudo ufw allow 22/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### SSL/TLS Setup

```bash
# Install Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo certbot renew --dry-run
```

### Application Security

1. **Keep dependencies updated**:
   ```bash
   bundle update
   bundle exec bundle-audit check --update
   ```

2. **Use environment variables** for sensitive data
3. **Enable HTTPS** in production
4. **Restrict CORS** if not needed globally
5. **Set up rate limiting** with Rack::Attack

---

## Backup and Recovery

### Backup

```bash
# Backup application
tar -czf tromso-app-backup-$(date +%Y%m%d).tar.gz \
  /opt/tromso-wallpaper-app \
  --exclude=log \
  --exclude=tmp

# Backup database (if applicable)
# pg_dump dbname > backup.sql
```

### Restore

```bash
# Stop application
sudo systemctl stop tromso-wallpaper-app

# Restore files
tar -xzf tromso-app-backup-20251030.tar.gz -C /

# Install dependencies
cd /opt/tromso-wallpaper-app
bundle install --deployment

# Start application
sudo systemctl start tromso-wallpaper-app
```

---

## Troubleshooting

### Service Won't Start

```bash
# Check logs
sudo journalctl -u tromso-wallpaper-app -n 50

# Check permissions
ls -la /opt/tromso-wallpaper-app
sudo chown -R starwave:starwave /opt/tromso-wallpaper-app

# Check Ruby version
ruby --version

# Check dependencies
bundle check
```

### High Memory Usage

```bash
# Check memory
free -h

# Reduce workers
WEB_CONCURRENCY=1 bundle exec puma -C config/puma.rb

# Use jemalloc
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2 bundle exec puma
```

### Port Already in Use

```bash
# Find process
sudo lsof -i :3001

# Kill process
sudo kill -9 <PID>

# Or change port
PORT=3002 bundle exec puma -C config/puma.rb
```

### Slow Response Times

1. **Increase threads**: `MAX_THREADS=10`
2. **Add workers**: `WEB_CONCURRENCY=4`
3. **Enable caching**: Add Redis/Memcached
4. **Use CDN**: For static assets
5. **Optimize database**: Add indexes, connection pooling

---

## Rollback

### To Previous Version

```bash
# Stop service
sudo systemctl stop tromso-wallpaper-app

# Restore from backup
tar -xzf tromso-app-backup-previous.tar.gz -C /

# Install dependencies
cd /opt/tromso-wallpaper-app
bundle install --deployment

# Start service
sudo systemctl start tromso-wallpaper-app
```

### Docker Rollback

```bash
# List images
docker images | grep tromso

# Tag current as backup
docker tag tromso-wallpaper-app-ruby:latest tromso-wallpaper-app-ruby:backup

# Pull/load previous version
docker load < previous-version.tar.gz

# Restart
docker compose down
docker compose up -d
```

---

## Production Checklist

- [ ] Ruby 3.0+ installed
- [ ] Dependencies installed with `--deployment`
- [ ] Environment variables configured
- [ ] Logs directory created
- [ ] Systemd service configured
- [ ] Service enabled and started
- [ ] Firewall configured
- [ ] Nginx reverse proxy (optional)
- [ ] SSL/TLS certificate (optional)
- [ ] Monitoring set up
- [ ] Backups configured
- [ ] Health check responds
- [ ] Application accessible

---

## Performance Tuning

### Puma Configuration

```ruby
# config/puma.rb
workers 4              # Number of processes
threads 5, 5           # Min and max threads
preload_app!           # Preload application
```

### System Limits

```bash
# Edit limits
sudo nano /etc/security/limits.conf
```

Add:
```
* soft nofile 65536
* hard nofile 65536
```

### Kernel Parameters

```bash
# Edit sysctl
sudo nano /etc/sysctl.conf
```

Add:
```
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
```

Apply:
```bash
sudo sysctl -p
```

---

## Support

- **Installation**: See [INSTALL.md](INSTALL.md)
- **Application**: See [README.md](README.md)
- **Logs**: Check `/opt/tromso-wallpaper-app/log/`
- **System**: `sudo journalctl -u tromso-wallpaper-app`
