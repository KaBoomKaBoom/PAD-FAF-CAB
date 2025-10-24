#!/bin/bash

# Four-Stage Deployment Script for PAD Microservices
echo "============================================"
echo "  PAD Microservices Deployment Script"
echo "============================================"
echo ""

echo "Checking Docker status..."
if docker info > /dev/null 2>&1; then
    echo "✓ Docker is running"
else
    echo "✗ Docker is not running"
    exit 1
fi

echo ""
echo "Checking Docker Swarm status..."
SWARM_STATUS=$(docker info --format '{{.Swarm.LocalNodeState}}')
if [ "$SWARM_STATUS" != "active" ]; then
    echo "Initializing Docker Swarm..."
    if docker swarm init; then
        echo "✓ Docker Swarm initialized"
    else
        echo "✗ Failed to initialize Docker Swarm"
        exit 1
    fi
else
    echo "✓ Docker Swarm is already active"
fi

echo ""
echo "Checking/Creating overlay network..."
NETWORK_EXISTS=$(docker network ls --filter name=test-stack_default --format "{{.Name}}")
if [ "$NETWORK_EXISTS" != "test-stack_default" ]; then
    echo "Creating test-stack_default network..."
    if docker network create --driver overlay --attachable test-stack_default; then
        echo "✓ Network created successfully"
    else
        echo "✗ Failed to create network"
        exit 1
    fi
else
    echo "✓ Network test-stack_default already exists"
fi

echo ""
echo "STAGE 1: Deploying Databases"
if docker stack deploy -c docker-compose.databases.yml test-stack; then
    echo "✓ Databases deployment initiated"
else
    echo "✗ Database deployment failed"
    exit 1
fi

echo "Waiting 10 seconds..."
sleep 10

echo ""
echo "STAGE 2: Deploying Service Discovery"
if docker stack deploy -c docker-compose.discovery.yml test-stack; then
    echo "✓ Service Discovery deployment initiated"
else
    echo "✗ Service Discovery deployment failed"
    exit 1
fi

echo "Waiting 10 seconds..."
sleep 10

echo ""
echo "STAGE 3: Deploying Microservices"
if docker stack deploy -c docker-compose.services.yml test-stack; then
    echo "✓ Microservices deployment initiated"
else
    echo "✗ Microservices deployment failed"
    exit 1
fi

echo "Waiting 30 seconds..."
sleep 30

echo ""
echo "STAGE 4: Deploying API Gateway"
if docker stack deploy -c docker-compose.gateway.yml test-stack; then
    echo "✓ API Gateway deployment initiated"
else
    echo "✗ API Gateway deployment failed"
    exit 1
fi

echo "Waiting 10 seconds..."
sleep 10

echo ""
echo "Deployment Complete!"
echo ""
echo "Service endpoints:"
echo "  API Gateway:        http://localhost:8000"
echo "  Service Discovery:  http://localhost:8002"
echo "  Adminer:            http://localhost:8090"
echo "  Mongo Express:      http://localhost:8091"
echo ""
docker stack services test-stack
