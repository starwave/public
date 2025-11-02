#!/bin/bash

# Deployment script for Tromso Wallpaper App to 192.168.1.111

TARGET_HOST="192.168.1.111"
TARGET_USER="starwave"  # Update this
TARGET_PATH="/opt/tromso-wallpaper-app"  # Update this
IMAGE_NAME="tromso-wallpaper-app"

echo "Detecting platform..."
LOCAL_PLATFORM=$(uname -m)
echo "Local platform: ${LOCAL_PLATFORM}"

# Build for linux/amd64 (most common server architecture)
echo "Building Docker image for linux/amd64..."
docker buildx build --platform linux/amd64 -t ${IMAGE_NAME}:latest --load .

if [ $? -ne 0 ]; then
    echo "Docker build failed!"
    echo ""
    echo "Note: If buildx is not available, enable it:"
    echo "  docker buildx create --use"
    exit 1
fi

#echo "Creating target directory on remote server..."
#ssh ${TARGET_USER}@${TARGET_HOST} "sudo -S mkdir -p ${TARGET_PATH} && sudo -S chown ${TARGET_USER}:${TARGET_USER} ${TARGET_PATH}"

echo "Saving Docker image..."
docker save ${IMAGE_NAME}:latest | gzip > /tmp/${IMAGE_NAME}.tar.gz

echo "Copying files to ${TARGET_HOST}..."
scp /tmp/${IMAGE_NAME}.tar.gz ${TARGET_USER}@${TARGET_HOST}:/tmp/
scp docker-compose.yml ${TARGET_USER}@${TARGET_HOST}:${TARGET_PATH}/

echo "Loading image on remote server..."
ssh ${TARGET_USER}@${TARGET_HOST} "docker load < /tmp/${IMAGE_NAME}.tar.gz"

echo "Detecting Docker Compose version on remote server..."
COMPOSE_CMD=$(ssh ${TARGET_USER}@${TARGET_HOST} "if command -v docker-compose &> /dev/null; then echo 'docker-compose'; else echo 'docker compose'; fi")
echo "Using: ${COMPOSE_CMD}"

echo "Starting container on ${TARGET_HOST}..."
ssh ${TARGET_USER}@${TARGET_HOST} "cd ${TARGET_PATH} && ${COMPOSE_CMD} up -d"

echo "Cleaning up..."
rm /tmp/${IMAGE_NAME}.tar.gz
ssh ${TARGET_USER}@${TARGET_HOST} "rm /tmp/${IMAGE_NAME}.tar.gz"

echo "Deployment complete!"
echo "App should be running on http://${TARGET_HOST}:3001"
