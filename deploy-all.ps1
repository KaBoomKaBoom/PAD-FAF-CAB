# Four-Stage Deployment Script for PAD Microservices
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  PAD Microservices Deployment Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Checking Docker status..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "Docker is running" -ForegroundColor Green
} catch {
    Write-Host "Docker is not running" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Checking Docker Swarm status..." -ForegroundColor Yellow
$swarmStatus = docker info --format '{{.Swarm.LocalNodeState}}'
if ($swarmStatus -ne "active") {
    Write-Host "Initializing Docker Swarm..." -ForegroundColor Yellow
    docker swarm init
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker Swarm initialized" -ForegroundColor Green
    } else {
        Write-Host "Failed to initialize Docker Swarm" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Docker Swarm is already active" -ForegroundColor Green
}

Write-Host ""
Write-Host "Checking/Creating overlay network..." -ForegroundColor Yellow
$networkExists = docker network ls --filter name=padstack_default --format "{{.Name}}"
if ($networkExists -ne "padstack_default") {
    Write-Host "Creating padstack_default network..." -ForegroundColor Yellow
    docker network create --driver overlay --attachable padstack_default
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Network created successfully" -ForegroundColor Green
    } else {
        Write-Host "Failed to create network" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Network padstack_default already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "STAGE 1: Deploying Databases" -ForegroundColor Cyan
docker stack deploy -c docker-compose.databases.yml padstack
if ($LASTEXITCODE -eq 0) {
    Write-Host "Databases deployment initiated" -ForegroundColor Green
} else {
    Write-Host "Database deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "Waiting 10 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "STAGE 2: Deploying Message Broker" -ForegroundColor Cyan
docker stack deploy -c docker-compose.broker.yml padstack
if ($LASTEXITCODE -eq 0) {
    Write-Host "Message Broker deployment initiated" -ForegroundColor Green
} else {
    Write-Host "Message Broker deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "Waiting 10 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "STAGE 3: Deploying Service Discovery" -ForegroundColor Cyan
docker stack deploy -c docker-compose.discovery.yml padstack
if ($LASTEXITCODE -eq 0) {
    Write-Host "Service Discovery deployment initiated" -ForegroundColor Green
} else {
    Write-Host "Service Discovery deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "Waiting 10 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "STAGE 4: Deploying Microservices" -ForegroundColor Cyan
docker stack deploy -c docker-compose.services.yml padstack
if ($LASTEXITCODE -eq 0) {
    Write-Host "Microservices deployment initiated" -ForegroundColor Green
} else {
    Write-Host "Microservices deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "Waiting 30 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "STAGE 5: Deploying API Gateway" -ForegroundColor Cyan
docker stack deploy -c docker-compose.gateway.yml padstack
if ($LASTEXITCODE -eq 0) {
    Write-Host "API Gateway deployment initiated" -ForegroundColor Green
} else {
    Write-Host "API Gateway deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "STAGE 6: Deploying Data Warehouse" -ForegroundColor Cyan
docker stack deploy -c docker-compose.dw.yml padstack
if ($LASTEXITCODE -eq 0) {
    Write-Host "Data Warehouse deployment initiated" -ForegroundColor Green
} else {
    Write-Host "Data Warehouse deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "Waiting 10 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Service endpoints:" -ForegroundColor Cyan
Write-Host "  API Gateway:        http://localhost:8000"
Write-Host "  Service Discovery:  http://localhost:8002"
Write-Host "  Broker:             http://localhost:5000"
Write-Host "  Adminer:            http://localhost:8090"
Write-Host "  Mongo Express:      http://localhost:8091"
Write-Host ""
docker stack services padstack