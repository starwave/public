# Deployment Guide

## Deploy to 192.168.1.111 using Docker

### Prerequisites
- Docker installed on your local machine
- SSH access to 192.168.1.111 as root
- Docker and docker-compose installed on the server

### Quick Deploy

Simply run the deployment script:

```bash
./deploy.sh
```

This will:
1. Build the Docker image locally
2. Save the image to a tar file
3. Copy files to the server
4. Load and run the container on the server

### Manual Deployment

If you prefer to deploy manually:

#### 1. Build Docker image locally
```bash
docker build -t ggwave-bible-app:latest .
```

#### 2. Save image
```bash
docker save ggwave-bible-app:latest -o ggwave-bible-app.tar
```

#### 3. Copy to server
```bash
scp ggwave-bible-app.tar docker-compose.yml root@192.168.1.111:/opt/ggwave-bible-app/
```

#### 4. Deploy on server
```bash
ssh root@192.168.1.111
cd /opt/ggwave-bible-app
docker load -i ggwave-bible-app.tar
docker-compose up -d
```

### Access the Application

Once deployed, access the app at:
- **http://192.168.1.111:3000**

### Managing the Deployment

#### View logs
```bash
ssh root@192.168.1.111
cd /opt/ggwave-bible-app
docker-compose logs -f
```

#### Stop the app
```bash
ssh root@192.168.1.111
cd /opt/ggwave-bible-app
docker-compose down
```

#### Restart the app
```bash
ssh root@192.168.1.111
cd /opt/ggwave-bible-app
docker-compose restart
```

#### Update deployment
Just run `./deploy.sh` again to update with latest changes.

### Troubleshooting

If the deployment fails:
1. Check if Docker is running on the server: `ssh root@192.168.1.111 docker ps`
2. Check logs: `ssh root@192.168.1.111 "cd /opt/ggwave-bible-app && docker-compose logs"`
3. Verify port 3000 is not in use: `ssh root@192.168.1.111 "netstat -tuln | grep 3000"`

### Configuration

To change the port, edit `docker-compose.yml`:
```yaml
ports:
  - "3000:3000"  # Change the first port to desired host port
```
