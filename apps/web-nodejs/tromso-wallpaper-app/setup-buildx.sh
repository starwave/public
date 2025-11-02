#!/bin/bash

# Setup Docker Buildx for cross-platform builds
# Required for building images on Mac (ARM64) for deployment to Linux servers (AMD64)

echo "=========================================="
echo "Docker Buildx Setup"
echo "=========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ ERROR: Docker is not installed"
    echo "Please install Docker Desktop first"
    exit 1
fi

echo "✅ Docker is installed"
echo ""

# Check current platform
LOCAL_PLATFORM=$(uname -m)
echo "Local platform: ${LOCAL_PLATFORM}"

if [[ "$LOCAL_PLATFORM" == "arm64" ]]; then
    echo "ℹ️  Running on Apple Silicon (ARM64)"
    echo "   Cross-platform builds are needed for x86_64 servers"
elif [[ "$LOCAL_PLATFORM" == "x86_64" ]]; then
    echo "ℹ️  Running on x86_64"
    echo "   Cross-platform builds may still be useful"
fi
echo ""

# Check if buildx is available
echo "Checking Docker buildx..."
if docker buildx version &> /dev/null; then
    echo "✅ Docker buildx is available"
    VERSION=$(docker buildx version)
    echo "   Version: ${VERSION}"
else
    echo "❌ Docker buildx is not available"
    echo "Please update Docker Desktop to the latest version"
    exit 1
fi
echo ""

# List existing builders
echo "Current builders:"
docker buildx ls
echo ""

# Check if a multi-platform builder exists
if docker buildx ls | grep -q "multiplatform"; then
    echo "✅ Multi-platform builder already exists"
    echo ""
    echo "Setting it as default..."
    docker buildx use multiplatform
else
    echo "Creating multi-platform builder..."
    docker buildx create --name multiplatform --driver docker-container --use

    if [ $? -eq 0 ]; then
        echo "✅ Multi-platform builder created successfully"
    else
        echo "❌ Failed to create builder"
        exit 1
    fi
fi
echo ""

# Bootstrap the builder
echo "Bootstrapping builder (this may take a moment)..."
docker buildx inspect --bootstrap

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Builder is ready"
else
    echo ""
    echo "❌ Failed to bootstrap builder"
    exit 1
fi
echo ""

# Show builder capabilities
echo "Builder capabilities:"
docker buildx inspect
echo ""

echo "=========================================="
echo "✅ Setup complete!"
echo "=========================================="
echo ""
echo "Your system is now configured for cross-platform builds."
echo ""
echo "Supported platforms:"
docker buildx inspect | grep "Platforms:"
echo ""
echo "You can now deploy to AMD64 servers from your Mac:"
echo "  ./deploy.sh"
echo ""
echo "To build for multiple platforms:"
echo "  docker buildx build --platform linux/amd64,linux/arm64 -t myapp ."
echo ""
