#!/usr/bin/env bash
# Quick start script for Substrate Ecosystem Docker setup

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Substrate Ecosystem - Docker Quick Start"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✓ Docker found: $(docker --version)"
echo "✓ Docker Compose found: $(docker-compose --version)"
echo ""

# Step 1: Build base image
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1/4: Building base image with synapse"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will take several minutes on first run..."
echo ""

docker build -f Dockerfile.base -t ghcr.io/hypermemetic/substrate-base:latest .

echo ""
echo "✓ Base image built successfully"
echo ""

# Step 2: Build service images
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2/4: Building service images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker-compose build

echo ""
echo "✓ Service images built successfully"
echo ""

# Step 3: Create secrets directory
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3/4: Setting up secrets directory"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -f "secrets/secrets.yaml" ]; then
    echo "Creating initial secrets.yaml from example..."
    cp secrets/secrets.yaml.example secrets/secrets.yaml
    echo "✓ Created secrets/secrets.yaml"
    echo "  Edit this file to add your actual secrets"
else
    echo "✓ secrets/secrets.yaml already exists"
fi

echo ""

# Step 4: Start services
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4/4: Starting services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker-compose up -d

echo ""
echo "Waiting for services to be healthy..."
sleep 5

# Check health
echo ""
docker-compose ps

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Services running:"
echo "  • Substrate Hub:  ws://localhost:4444"
echo "  • Registry:       ws://localhost:4445"
echo "  • Auth Hub:       ws://localhost:4446"
echo ""
echo "Quick commands:"
echo "  View logs:        docker-compose logs -f"
echo "  Stop services:    docker-compose down"
echo "  Restart:          docker-compose restart"
echo ""
echo "Using Makefile:"
echo "  make help         Show all available commands"
echo "  make logs         Follow all logs"
echo "  make health       Check service health"
echo "  make test         Run test commands"
echo ""
echo "For full documentation, see README.docker.md"
echo ""
