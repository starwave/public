#!/bin/bash

# Deployment script for ggwave-bible-app to 192.168.1.111

SERVER="192.168.1.111"
APP_NAME="ggwave-bible-app"
REMOTE_DIR="/opt/${APP_NAME}"

echo "🚀 Starting deployment to ${SERVER}..."

# Build Docker image locally
echo "📦 Building Docker image..."
docker build -t ${APP_NAME}:latest .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

echo "✅ Docker image built successfully"

# Save image to tar file
echo "💾 Saving Docker image..."
docker save ${APP_NAME}:latest -o ${APP_NAME}.tar

# Copy files to server
echo "📤 Copying files to server..."
ssh root@${SERVER} "mkdir -p ${REMOTE_DIR}"
scp ${APP_NAME}.tar docker-compose.yml root@${SERVER}:${REMOTE_DIR}/

# Load and run on server
echo "🚢 Deploying on server..."
ssh root@${SERVER} << EOF
    cd ${REMOTE_DIR}
    docker load -i ${APP_NAME}.tar
    docker-compose down
    docker-compose up -d
    docker-compose ps
    echo "✅ Deployment complete!"
    echo "🌐 App is running at http://${SERVER}:3000"
EOF

# Cleanup
rm ${APP_NAME}.tar

echo "🎉 Deployment finished!"
echo "Visit: http://${SERVER}:3000"
