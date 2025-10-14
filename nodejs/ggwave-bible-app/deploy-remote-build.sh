#!/bin/bash

# Deployment script that builds on the server (no local Docker needed)

SERVER="192.168.1.111"
USER="starwave"
APP_NAME="ggwave-bible-app"
REMOTE_DIR="/home/${USER}/${APP_NAME}"

echo "🚀 Starting deployment to ${SERVER}..."
echo "Building will happen on the server..."

# Create directory structure on server
echo "📁 Setting up directories on server..."
ssh ${USER}@${SERVER} "mkdir -p ${REMOTE_DIR}"

# Copy all files to server
echo "📤 Copying project files to server..."
rsync -avz --exclude 'node_modules' \
           --exclude '.next' \
           --exclude '.git' \
           --exclude '*.tar' \
           . ${USER}@${SERVER}:${REMOTE_DIR}/

# Build and run on server
echo "🏗️  Building and deploying on server..."
ssh ${USER}@${SERVER} << EOF
    cd ${REMOTE_DIR}
    echo "Building Docker image..."
    docker build -t ${APP_NAME}:latest .

    if [ \$? -ne 0 ]; then
        echo "❌ Docker build failed on server!"
        exit 1
    fi

    echo "Starting containers..."
    docker compose down
    docker compose up -d

    echo ""
    echo "✅ Deployment complete!"
    echo "📊 Container status:"
    docker compose ps
    echo ""
    echo "🌐 App is running at http://${SERVER}:3000"
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Deployment finished successfully!"
    echo "Visit: http://${SERVER}:3000"
else
    echo "❌ Deployment failed. Check the logs above."
    exit 1
fi
