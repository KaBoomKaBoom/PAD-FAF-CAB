# PAD-FAF-CAB-GATEWAY

## Table of Contents

- [Overview](#overview)
- [Architecture Overview](#architecture-overview)
  - [Dual-Port Benefits](#dual-port-benefits)
- [Integrated Microservices](#integrated-microservices)
- [Key Features](#key-features)
  - [🔐 JWT Authentication & Security](#-jwt-authentication--security)
  - [⚡ Performance & Caching](#-performance--caching)
  - [🚦 Concurrency & Rate Limiting](#-concurrency--rate-limiting)
  - [⏱️ Timeout Management](#️-timeout-management)
  - [🔄 Load Balancing & Service Discovery](#-load-balancing--service-discovery)
  - [⚡ Circuit Breaker Pattern](#-circuit-breaker-pattern)
  - [📊 Monitoring & Observability](#-monitoring--observability)
- [Request Flow](#request-flow)
  - [External Request Flow](#external-request-flow)
  - [Internal Request Flow](#internal-request-flow)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
  - [Service Discovery Configuration](#service-discovery-configuration)
- [API Endpoints](#api-endpoints)
  - [Authentication Endpoints](#authentication-endpoints)
  - [Service Endpoints](#service-endpoints)
  - [Internal Endpoints](#internal-endpoints)
- [Circuit Breaker Details](#circuit-breaker-details)
  - [Circuit Breaker States](#circuit-breaker-states)
  - [Configuration](#configuration-1)
  - [Monitoring](#monitoring)
- [Prometheus Metrics](#prometheus-metrics)
- [Docker Deployment](#docker-deployment)
  - [Prerequisites](#prerequisites)
  - [Building the Image](#building-the-image)
  - [Running with Docker Compose](#running-with-docker-compose)
- [Development](#development)
  - [Prerequisites](#prerequisites-1)
  - [Local Setup](#local-setup)
  - [Running Locally](#running-locally)
- [Testing](#testing)
  - [Testing Circuit Breaker](#testing-circuit-breaker)
  - [Testing Load Balancer](#testing-load-balancer)
- [Monitoring & Debugging](#monitoring--debugging)
  - [Grafana Dashboards](#grafana-dashboards)
  - [Log Analysis](#log-analysis)
- [Troubleshooting](#troubleshooting)
- [Performance Tuning](#performance-tuning)
- [Security Best Practices](#security-best-practices)
- [Contributing](#contributing)
- [License](#license)

## Overview

PAD-FAF-CAB-GATEWAY is a high-performance API Gateway built with Go and Gin framework, serving as the central entry point for a distributed microservices architecture. This gateway orchestrates communication between clients and 10 distinct microservices, providing a unified interface while implementing essential cross-cutting concerns.

## Architecture Overview

The gateway implements a **dual-port architecture** separating external user traffic from internal service-to-service communication:

```
External Users                     Internal Services
      │                                   │
      ▼                                   ▼
┌─────────────────┐              ┌─────────────────┐
│ External Gateway│              │ Internal Gateway│
│   Port 8000     │              │   Port 8001     │
│                 │              │                 │
│ ✅ JWT Auth     │              │ ❌ No Auth      │
│ ✅ Rate Limit   │              │ ❌ No Rate Limit│
│ ✅ Caching      │              │ ❌ No Caching   │
│ ✅ Monitoring   │              │ ✅ Basic Logging│
└─────────────────┘              └─────────────────┘
      │                                   │
      └─────────────┐       ┌─────────────┘
                    ▼       ▼
              ┌─────────────────┐
              │ Microservices   │
              │   (10 Services) │
              └─────────────────┘
                      │
               ┌──────────────┐
               │ Redis Cache  │
               │  (Port 6379) │
               └──────────────┘
```

### Dual-Port Benefits
- **🔐 Security Isolation**: Internal services communicate without authentication overhead
- **⚡ Performance**: Service-to-service calls bypass unnecessary middleware
- **🎯 Network Segmentation**: Internal port not exposed to external networks
- **🔧 Simplified Integration**: Services can call each other directly via Docker network

## Integrated Microservices

The gateway routes requests to the following 10 microservices:

| Service | Path | Port | Technology | Description |
|---------|------|------|------------|-------------|
| **User Management** | `/userManagement` | 8080 | Python/FastAPI | User authentication & profile management |
| **Notification Service** | `/notification` | 8081 | Python/FastAPI | Push notifications & messaging |
| **Tea Management** | `/teaManagement` | 8082 | .NET Core | Tea inventory & ordering system |
| **Communication** | `/communication` | 8083 | .NET Core | Internal messaging & chat |
| **Cab Booking** | `/booking` | 8084 | Java/Spring Boot | Taxi/ride booking service |
| **Check-in Service** | `/checkin` | 8085 | Java/Spring Boot | Location check-in & attendance |
| **Lost & Found** | `/lostFound` | 8086 | .NET Core | Lost items tracking |
| **Budgeting Service** | `/budgeting` | 8087 | .NET Core | Financial management & budgets |
| **Fund Raising** | `/fundRaising` | 8088 | *To be deployed* | Crowdfunding & donations |
| **Sharing Service** | `/sharing` | 8089 | *To be deployed* | Resource sharing platform |

## Key Features

### 🔐 JWT Authentication & Security
- **Centralized Authentication**: All requests (except `/auth/login` and `/auth/register`) require valid JWT tokens
- **Redis Token Management**: Active tokens stored in Redis with configurable TTL (60 seconds for auth data)
- **Token Blacklisting**: Logout functionality blacklists tokens to prevent reuse
- **Automatic Token Caching**: Login/register responses automatically cache JWT tokens in Redis
- **Authorization Header Removal**: Strips authorization headers before forwarding to downstream services

### ⚡ Performance & Caching
- **Redis Caching Layer**: High-performance caching for GET requests with 30-second TTL
- **Intelligent Cache Strategy**: Only GET requests with 200 OK responses are cached
- **Cache Hit Optimization**: Cached responses served directly without downstream calls
- **Connection Pooling**: Efficient Redis connection management with context-aware operations

### 🚦 Concurrency & Rate Limiting
- **Per-Service Concurrency Control**: Configurable concurrent request limits (default: 10 per service)
- **Global Concurrency Management**: System-wide concurrency limits (default: 100)
- **Semaphore-based Limiting**: Efficient blocking semaphore implementation
- **429 Response Handling**: Graceful rejection of excess concurrent requests

### ⏱️ Timeout Management
- **Request Timeout Control**: Configurable request timeout (default: 3 seconds)
- **Upstream Timeout**: Separate timeout for upstream services (default: 10 seconds)
- **Context Propagation**: Timeout context passed through middleware chain
- **Gateway Timeout Response**: 504 status for timed-out requests
- **Circuit Breaker Timeout Tracking**: Timeout errors (504) count as failures for circuit breaker

### 🔄 Load Balancing & Service Discovery
- **Least-Load Algorithm**: Distributes requests based on current instance load
- **Dynamic Service Discovery**: Automatically discovers and routes to healthy service instances
- **Health Monitoring**: Real-time tracking of upstream instance health
- **Automatic Failover**: Unhealthy instances excluded from routing
- **Periodic Refresh**: Service discovery refreshed every 30 seconds
- **Request Count Tracking**: Increments request count per replica in service discovery

### ⚡ Circuit Breaker Pattern
- **Fail-Fast Protection**: Prevents cascading failures by quickly detecting problematic services
- **Configurable Thresholds**: Trips after 3 failures within (timeout × 3.5) seconds window
- **State Machine**: Three states - Closed (normal), Open (failing fast), Half-Open (testing recovery)
- **Automatic Deregistration**: Failing replicas automatically deregistered from service discovery
- **Per-Replica Tracking**: Each Docker Swarm replica tracked independently
- **Network Error Handling**: Connection errors and timeouts trigger circuit breaker
- **5xx Error Tracking**: Server errors count as failures toward threshold

### 🔄 Reverse Proxy Capabilities
- **Dynamic Path Routing**: Intelligent routing based on URL path prefixes
- **Query Parameter Preservation**: Maintains original query parameters in forwarded requests
- **Response Modification**: Intercepts and processes responses for caching and token management
- **Error Handling**: 404 responses for unmatched service routes
- **Hostname-Based Replica ID**: Extracts replica ID from Docker Swarm hostnames for tracking

## Technical Stack

### Core Technologies
- **Language**: Go 1.25.1
- **Framework**: Gin Web Framework
- **Cache**: Redis 7
- **Authentication**: JWT with HMAC signing
- **Containerization**: Docker & Docker Compose
- **Monitoring**: Prometheus & Grafana
- **Load Balancing**: Least-load algorithm with service discovery

### Key Dependencies
```go
github.com/gin-gonic/gin v1.11.0           // Web framework
github.com/redis/go-redis/v9 v9.14.0       // Redis client
github.com/golang-jwt/jwt/v5 v5.3.0        // JWT handling
github.com/joho/godotenv v1.5.1            // Environment management
```

## Configuration

### Default Configuration Values
```go
// Port Configuration
ExternalPort: "8000"             // External user-facing port
InternalPort: "8001"             // Internal service-to-service port

// Performance Settings
GlobalConcurrency: 100           // Max concurrent requests (external only)
PerServiceLimit: 10              // Max concurrent requests per service (external only)
RequestTimeout: 3 seconds        // Request timeout (both ports)
UpstreamTimeout: 10 seconds      // Upstream service timeout

// Caching (External Only)
GetCacheTTL: 30 seconds          // GET request cache TTL
AuthCacheTTL: 60 seconds         // Auth token cache TTL

// Load Balancing & Service Discovery
ServiceDiscoveryURL: "http://service-discovery:9000"  // Service discovery endpoint
ServiceRefreshInterval: 30 seconds                     // Service list refresh interval

// Circuit Breaker
CircuitBreakerThreshold: 3                            // Failures before circuit trips
CircuitBreakerWindow: RequestTimeout × 3.5            // Time window for failure tracking
CircuitBreakerCooldown: 30 seconds                    // Time in Open state before Half-Open
```

### Environment Variables (.env)
```env
# Gateway Configuration
EXTERNAL_PORT=8000
INTERNAL_PORT=8001
JWT_SECRET=your-secret-key-here

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Performance Tuning
GLOBAL_CONCURRENCY=100
PER_SERVICE_LIMIT=10
REQUEST_TIMEOUT=3s
UPSTREAM_TIMEOUT=10s

# Service Discovery
SERVICE_DISCOVERY_URL=http://service-discovery:9000
SERVICE_REFRESH_INTERVAL=30s
```

## API Usage

### External API (Port 8000) - User Authentication Required

```bash
# 1. Login (no auth required)
POST http://localhost:8000/userManagement/auth/login
Content-Type: application/json
{
  "username": "user@example.com",
  "password": "password"
}

# 2. Response includes JWT token (automatically cached)
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}

# 3. Use token for authenticated requests
GET http://localhost:8000/budgeting/api/transactions
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### Internal API (Port 8001) - Service-to-Service Communication

```bash
# Internal services can communicate directly without authentication
# These endpoints are only accessible within the Docker network

# Example: Budgeting service calling User Management service
POST http://api-gateway:8001/internal/userManagement/users/123/profile

# Example: Notification service calling Communication service  
GET http://api-gateway:8001/internal/communication/messages/unread

# Example: Any service calling any other service
PUT http://api-gateway:8001/internal/teaManagement/inventory/update
Content-Type: application/json
{
  "item_id": "tea_001",
  "quantity": 50
}
```

### External Request Flow (Port 8000)
1. **Concurrency Check**: Request blocked if concurrent limit exceeded
2. **Timeout Setup**: Request timeout context established  
3. **Authentication**: JWT validation and Redis token verification
4. **Cache Check**: GET requests check Redis cache first
5. **Proxy Forward**: Request forwarded to appropriate microservice
6. **Response Processing**: Successful GET responses cached, JWT tokens saved
7. **Response Return**: Final response sent to client

### Internal Request Flow (Port 8001)
1. **Timeout Setup**: Request timeout context established
2. **Direct Proxy**: Request immediately forwarded to target microservice
3. **Response Return**: Response returned without processing or caching

*Internal requests bypass authentication, rate limiting, and caching for maximum performance.*

## Testing

### Performance Testing

#### Load Testing with Apache Bench
```bash
# Test external gateway with authentication
ab -n 1000 -c 50 \
   -H "Authorization: Bearer <JWT_TOKEN>" \
   http://localhost:8000/budgeting/api/transactions

# Results to look for:
# - Requests per second
# - Time per request (mean)
# - Failed requests (should be 0)
```

#### Concurrency Limit Testing
```bash
# Test with concurrent requests exceeding limit
ab -n 100 -c 15 \
   -H "Authorization: Bearer <JWT_TOKEN>" \
   http://localhost:8000/budgeting/api/transactions

# Expected: Some 429 responses when > 10 concurrent requests per service
```

#### Cache Performance Testing
```bash
# First request (cache miss) - ~50-100ms
time curl -H "Authorization: Bearer <JWT_TOKEN>" \
     http://localhost:8000/budgeting/api/transactions

# Second request within 30s (cache hit) - ~5-10ms
time curl -H "Authorization: Bearer <JWT_TOKEN>" \
     http://localhost:8000/budgeting/api/transactions

# Verify in metrics
curl http://localhost:8000/metrics | grep gateway_cache_hits_total
```

### Circuit Breaker Testing

```bash
# Test circuit breaker by simulating failures
# Make 3 requests to a failing endpoint

for i in {1..3}; do
  echo "Request $i"
  curl http://localhost:8001/internal/budgeting/api/test-circuit-breaker
  sleep 1
done

# Expected logs:
# Request 1: "Circuit Breaker: failure 1/3"
# Request 2: "Circuit Breaker: failure 2/3"
# Request 3: "Circuit Breaker: failure 3/3"
#            "🚨 CIRCUIT BREAKER TRIPPED"
#            "🗑️ Deregistered replica"

# Request 4 (should fail-fast)
curl http://localhost:8001/internal/budgeting/api/test-circuit-breaker
# Response: 503 "Circuit breaker is open"
```

### Load Balancer Testing

```bash
# Deploy service with multiple replicas
docker-compose up -d --scale budgeting-service=3

# Make multiple requests and observe distribution
for i in {1..10}; do
  curl -H "Authorization: Bearer <JWT_TOKEN>" \
       http://localhost:8000/budgeting/api/balance
done

# Check metrics for distribution
curl http://localhost:8000/metrics | grep gateway_lb_instance_load

# Should show balanced load:
# gateway_lb_instance_load{service="/budgeting",instance="replica-1"} 3
# gateway_lb_instance_load{service="/budgeting",instance="replica-2"} 4  
# gateway_lb_instance_load{service="/budgeting",instance="replica-3"} 3
```

### Stress Testing

```bash
# High load test with wrk
wrk -t4 -c100 -d30s \
    -H "Authorization: Bearer <JWT_TOKEN>" \
    http://localhost:8000/budgeting/api/transactions

# Monitor during test:
# 1. Watch Grafana dashboard for real-time metrics
# 2. Check docker stats for resource usage
# 3. Monitor circuit breaker logs for any trips
# 4. Verify no memory leaks (RSS should stabilize)
```

### Integration Testing

```bash
# Test authentication flow
# 1. Login
TOKEN=$(curl -X POST http://localhost:8000/userManagement/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test@example.com","password":"password"}' \
  | jq -r '.access_token')

# 2. Use token for authenticated request
curl -H "Authorization: Bearer $TOKEN" \
     http://localhost:8000/budgeting/api/transactions

# 3. Test internal service-to-service (no auth)
curl http://localhost:8001/internal/budgeting/api/transactions

# 4. Logout (blacklist token)
curl -X POST http://localhost:8000/userManagement/auth/logout \
     -H "Authorization: Bearer $TOKEN"

# 5. Verify token is blacklisted
curl -H "Authorization: Bearer $TOKEN" \
     http://localhost:8000/budgeting/api/transactions
# Expected: 401 Unauthorized
```

## Deployment

### Prerequisites
- Docker 20.10+ and Docker Compose 2.0+
- Redis instance
- Service Discovery service (for dynamic load balancing)
- Go 1.25.1+ (for local development)

### Docker Compose Deployment (Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/KaBoomKaBoom/PAD-FAF-CAB-GATEWAY.git
cd PAD-FAF-CAB-GATEWAY

# 2. Create .env file from template
cp .env.example .env
# Edit .env with your configuration

# 3. Start all services (gateway + monitoring)
docker-compose up -d

# 4. Verify services are running
docker-compose ps

# 5. View logs
docker-compose logs -f api-gateway

# 6. Access endpoints
# External API: http://localhost:8000
# Internal API: http://localhost:8001 (Docker network only)
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000
```

### Production Deployment

```bash
# Build production image
docker build -t pad-gateway:production .

# Run with production configuration
docker run -d \
  --name api-gateway \
  --network microservices-net \
  -p 8000:8000 \
  -e JWT_SECRET=${JWT_SECRET} \
  -e REDIS_HOST=redis-prod \
  -e SERVICE_DISCOVERY_URL=http://service-discovery:9000 \
  pad-gateway:production

# Use Docker secrets for sensitive data
docker secret create jwt_secret ./jwt_secret.txt
docker service create \
  --name api-gateway \
  --secret jwt_secret \
  --env JWT_SECRET_FILE=/run/secrets/jwt_secret \
  pad-gateway:production
```

### Docker Swarm Deployment

```yaml
# docker-compose.swarm.yml
version: '3.8'
services:
  api-gateway:
    image: pad-gateway:latest
    deploy:
      replicas: 3
      placement:
        constraints:
          - node.role == worker
      resources:
        limits:
          cpus: '1'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    ports:
      - "8000:8000"
    networks:
      - microservices
    secrets:
      - jwt_secret
    environment:
      JWT_SECRET_FILE: /run/secrets/jwt_secret
      SERVICE_DISCOVERY_URL: http://service-discovery:9000
```

```bash
# Deploy to Swarm
docker stack deploy -c docker-compose.swarm.yml gateway-stack

# Scale the gateway
docker service scale gateway-stack_api-gateway=5

# View service status
docker service ls
docker service ps gateway-stack_api-gateway
```

### Local Development

```bash
# 1. Install dependencies
go mod download

# 2. Set up environment
cp .env.example .env

# 3. Start Redis locally
docker run -d -p 6379:6379 redis:7-alpine

# 4. Run gateway
go run gateway/main.go

# 5. Run with hot reload (using air)
go install github.com/cosmtrek/air@latest
air
```

### Health Checks

```bash
# Gateway health (via any successful request)
curl http://localhost:8000/metrics

# Redis connectivity
docker exec api-gateway redis-cli -h redis ping

# Service discovery
curl http://localhost:9000/services

# Check all services
docker-compose ps
```

## Troubleshooting

### Common Issues

#### 1. Gateway Won't Start

**Problem**: Container exits immediately
```bash
docker logs api-gateway
```

**Solutions**:
- **Missing environment variables**: Check `.env` file exists
- **Redis connection failed**: Verify Redis is running: `docker ps | grep redis`
- **Port already in use**: Check ports 8000/8001 are available: `netstat -an | grep 8000`
- **Invalid configuration**: Validate go.mod and dependencies

#### 2. 401 Unauthorized Errors

**Problem**: All requests return 401 even with valid token

**Solutions**:
- **JWT secret mismatch**: Ensure JWT_SECRET in gateway matches service
- **Token not in Redis**: Check Redis: `redis-cli GET "token:<your-token>"`
- **Token expired**: Generate new token via `/auth/login`
- **Excluded path**: Verify `/auth/login` and `/auth/register` are excluded

**Debug**:
```bash
# Check JWT secret
docker exec api-gateway env | grep JWT_SECRET

# Test Redis connection
docker exec api-gateway redis-cli -h redis PING

# View auth logs
docker logs api-gateway | grep "JWT"
```

#### 3. Circuit Breaker Not Tripping

**Problem**: Service keeps failing but circuit doesn't trip

**Solutions**:
- **Wrong replica**: Failures on different replicas (tracked separately)
- **Time window expired**: Failures must occur within timeout×3.5 window
- **Not enough failures**: Need 3 failures on same replica

**Debug**:
```bash
# Check circuit breaker logs
docker logs api-gateway | grep "Circuit Breaker"

# Verify failure count
docker logs api-gateway | grep "failure [0-9]/3"

# Make 3 consecutive requests to same endpoint
for i in {1..3}; do curl http://localhost:8001/internal/failing-service; done
```

#### 4. Load Balancer Not Distributing Evenly

**Problem**: All requests go to one instance

**Solutions**:
- **Service discovery not running**: Check `docker ps | grep service-discovery`
- **Refresh interval too long**: Reduce SERVICE_REFRESH_INTERVAL
- **All instances marked unhealthy**: Check `gateway_lb_instance_health` metrics
- **Static fallback**: Service discovery not configured, using fallback upstreams

**Debug**:
```bash
# Check service discovery
curl http://localhost:9000/services

# View load distribution
curl http://localhost:8000/metrics | grep gateway_lb_instance_load

# Check gateway logs for LB selection
docker logs api-gateway | grep "Load balancer selected"
```

#### 5. High Memory Usage

**Problem**: Gateway memory keeps growing

**Solutions**:
- **Redis connection leak**: Monitor connections: `redis-cli CLIENT LIST`
- **Metric cardinality**: Check Prometheus metrics count
- **Go garbage collection**: May be normal, monitor for continued growth

**Debug**:
```bash
# Monitor memory
docker stats api-gateway

# Check Go runtime metrics
curl http://localhost:8000/metrics | grep go_memstats

# Force garbage collection (development only)
docker exec api-gateway kill -USR1 1
```

#### 6. Prometheus Not Scraping Metrics

**Problem**: Grafana shows "No Data"

**Solutions**:
- **Gateway not exposing metrics**: `curl http://localhost:8000/metrics`
- **Prometheus can't reach gateway**: Check Docker network
- **Prometheus configuration error**: Check `monitoring/prometheus.yml`

**Debug**:
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Test from Prometheus container
docker exec prometheus wget -O- http://api-gateway:8000/metrics

# Check Prometheus logs
docker logs prometheus | grep error
```

#### 7. Cache Not Working

**Problem**: All requests hit downstream services

**Solutions**:
- **Only GET requests cached**: Verify using GET method
- **Redis not running**: Check `docker ps | grep redis`
- **TTL expired**: Cache TTL is 30 seconds by default
- **Non-200 responses**: Only 200 OK responses are cached

**Debug**:
```bash
# Check cache metrics
curl http://localhost:8000/metrics | grep gateway_cache

# Monitor Redis
docker exec redis redis-cli MONITOR

# Check cache keys
docker exec redis redis-cli KEYS "*"
```

### Performance Optimization

#### 1. Increase Concurrency Limits
```go
// In config.go
GlobalConcurrency: 200    // From 100
PerServiceLimit: 20       // From 10
```

#### 2. Adjust Cache TTL
```go
GetCacheTTL: 60 * time.Second    // From 30s
```

#### 3. Optimize Service Discovery Refresh
```env
SERVICE_REFRESH_INTERVAL=15s     # From 30s (more responsive)
# OR
SERVICE_REFRESH_INTERVAL=60s     # From 30s (less load)
```

#### 4. Enable Connection Pooling
```go
// Redis client already uses connection pooling
// Adjust pool size if needed
redis.NewClient(&redis.Options{
    PoolSize: 20,  // Increase from default 10
})
```

### Logging & Debugging

#### Enable Debug Logging
```bash
# Set log level
export LOG_LEVEL=debug

# View all logs
docker logs -f api-gateway

# Filter specific component
docker logs api-gateway | grep "Load balancer"
docker logs api-gateway | grep "Circuit Breaker"
docker logs api-gateway | grep "JWT"
```

#### Monitor Real-Time Logs
```bash
# Follow logs from multiple containers
docker-compose logs -f api-gateway redis prometheus

# Tail last 100 lines
docker logs --tail 100 api-gateway

# Show timestamps
docker logs -t api-gateway
```

## Development

### Project Structure
```
PAD-FAF-CAB-GATEWAY/
├── gateway/
│   └── main.go                      # Application entry point
├── internal/
│   ├── auth/
│   │   └── middleware.go            # JWT authentication
│   ├── cache/
│   │   └── middleware.go            # Redis cache management
│   ├── circuitbreaker/
│   │   └── circuit_breaker.go       # Circuit breaker implementation
│   ├── concurrency/
│   │   └── middleware.go            # Concurrent request limiting
│   ├── config/
│   │   └── config.go                # Configuration management
│   ├── loadbalancer/
│   │   ├── round_robin.go           # Least-load balancer
│   │   └── service_discovery.go     # Service discovery client
│   ├── metrics/
│   │   ├── prometheus.go            # Prometheus metrics definitions
│   │   └── middleware.go            # Metrics collection middleware
│   ├── proxy/
│   │   ├── reverse_proxy.go         # External HTTP reverse proxy
│   │   └── internal_proxy.go        # Internal service-to-service proxy
│   └── timeout/
│       └── middleware.go            # Request timeout handling
├── monitoring/
│   ├── prometheus.yml               # Prometheus scrape configuration
│   └── grafana/
│       └── provisioning/
│           ├── dashboards/          # Pre-built Grafana dashboards
│           └── datasources/         # Prometheus datasource config
├── docker-compose.yaml              # Multi-service orchestration
├── Dockerfile                       # Gateway container definition
├── go.mod                           # Go module dependencies
├── go.sum                           # Dependency checksums
├── .env.example                     # Environment variables template
└── README.md                        # This file
```

### Adding New Services
1. Add service configuration to `internal/config/config.go`:
```go
// External endpoints (for user requests)
ExternalUpstreams: map[string]string{
    "/newService": "http://new-service:8090",
    // ... existing services
},

// Internal endpoints (for service-to-service)
InternalUpstreams: map[string]string{
    "/internal/newService": "http://new-service:8090", 
    // ... existing services
},
```

2. Add service to `docker-compose.yaml`
3. Update service dependencies in gateway configuration
4. Services can now communicate via:
   - External: `http://api-gateway:8000/newService` (requires JWT)
   - Internal: `http://api-gateway:8001/internal/newService` (no auth)

## Service-to-Service Communication

### Internal Network Benefits
- **🚀 High Performance**: No authentication overhead reduces latency by ~50ms per request
- **🔒 Network Isolation**: Internal port (8001) only accessible within Docker network
- **💡 Simplified Logic**: Services don't need to manage JWT tokens for internal calls
- **🔄 Direct Communication**: Bypasses external middleware stack entirely

### Example Internal Communication
```go
// From any microservice, call another service internally
func (s *MyService) CallBudgetingService(userID string) (*Budget, error) {
    resp, err := http.Get(fmt.Sprintf(
        "http://api-gateway:8001/internal/budgeting/users/%s/budget", 
        userID,
    ))
    // No Authorization header needed!
    return parseBudgetResponse(resp)
}
```

### Migration from External to Internal
```bash
# Before: External call requiring JWT
curl -H "Authorization: Bearer <token>" \
     http://api-gateway:8000/notification/send

# After: Internal call, no auth needed  
curl http://api-gateway:8001/internal/notification/send
```

## Security Considerations

### External API Security
- **JWT Secret Management**: Use strong, randomly generated JWT secrets
- **Redis Security**: Configure Redis authentication in production  
- **HTTPS**: Use TLS termination at load balancer level
- **Token Rotation**: Implement token refresh mechanisms
- **Rate Limiting**: Configure appropriate concurrency limits for your use case

### Internal API Security
- **Network Isolation**: Internal port should NEVER be exposed outside Docker network
- **Container Security**: Ensure internal port is not accessible from host network
- **No Authentication**: Internal services communicate directly without any JWT requirements
- **Trust Boundary**: Docker network acts as the security boundary for service communication
- **Service Mesh**: Consider implementing service mesh for advanced internal security (optional)
- **Monitoring**: Log all internal requests for audit trails

## Circuit Breaker Pattern

### Overview

The gateway implements a sophisticated circuit breaker pattern to prevent cascading failures and protect the system from overwhelming unhealthy services.

### How It Works

```
State Machine:
CLOSED → (3 failures in window) → OPEN → (30s cooldown) → HALF-OPEN → (success) → CLOSED
                                     ↑                                      ↓
                                     └──────────── (failure) ───────────────┘
```

### Configuration

- **Threshold**: 3 failures within time window
- **Time Window**: `RequestTimeout × 3.5` (default: 10.5 seconds)
- **Cooldown Period**: 30 seconds in OPEN state before testing recovery
- **Failure Types**: Network errors, timeouts (504), and 5xx responses

### States

#### CLOSED (Normal Operation)
- All requests pass through to upstream services
- Failures are counted per replica
- Transitions to OPEN after threshold reached

#### OPEN (Circuit Tripped)
- Requests fail immediately with 503 status
- No upstream calls made (fail-fast)
- Failing replica deregistered from service discovery
- After cooldown period, transitions to HALF-OPEN

#### HALF-OPEN (Testing Recovery)
- Single test request allowed through
- Success → Back to CLOSED state
- Failure → Back to OPEN for another cooldown period

### Per-Replica Tracking

Each Docker Swarm replica is tracked independently:

```
Example: http://padstack_budgeting-service.1.k7oqrdzi84fqlnd59vy81zums:8087

Replica ID extracted: padstack_budgeting-service.1.k7oqrdzi84fqlnd59vy81zums
```

### Circuit Breaker Flow

```
Request 1 → Replica A → 503 Error → Record failure 1/3
Request 2 → Replica A → Timeout   → Record failure 2/3
Request 3 → Replica A → 500 Error → Record failure 3/3 → TRIP!

Circuit Trips:
  1. Log: "🚨 CIRCUIT BREAKER TRIPPED for replica A"
  2. Deregister replica A from service discovery
  3. Send DELETE request: /deregister?service_id=replica-A
  4. All subsequent requests fail-fast with 503

After 30s cooldown:
  1. Circuit enters HALF-OPEN state
  2. Next request attempts to reach service
  3. Success → Circuit closes, service may re-register
  4. Failure → Circuit opens again for another 30s
```

### Benefits

- **🛡️ Prevents Cascading Failures**: Stops overwhelming failing services
- **⚡ Fail-Fast**: Quick response without waiting for timeouts
- **🔄 Automatic Recovery**: Tests service recovery periodically
- **🎯 Granular Control**: Per-replica tracking for precise failure isolation
- **📊 Observable**: Detailed logging of all circuit breaker events

### Logs Example

```
🔔 Circuit Breaker: Service http://budgeting:8087 failure 1/3 (window: 10.50 seconds)
🔔 Circuit Breaker: Service http://budgeting:8087 failure 2/3 (window: 10.50 seconds)
🔔 Circuit Breaker: Service http://budgeting:8087 failure 3/3 (window: 10.50 seconds)
🚨 CIRCUIT BREAKER TRIPPED for http://budgeting:8087 - deregistering
🔍 Extracted replica ID: padstack_budgeting-service.1.k7oqrdzi84fqlnd59vy81zums
🗑️  Sending deregister request: http://service-discovery:9000/deregister?service_id=padstack_budgeting-service.1.k7oqrdzi84fqlnd59vy81zums
✅ Successfully deregistered replica: padstack_budgeting-service.1.k7oqrdzi84fqlnd59vy81zums
⚡ Circuit breaker OPEN for http://budgeting:8087 - request rejected (fail-fast)
```

## Load Balancing & Service Discovery

### Overview

The gateway implements a **Least-Load algorithm** that distributes requests to the upstream instance with the lowest current load, ensuring optimal resource utilization across service replicas.

### Service Discovery Integration

```yaml
Service Discovery Endpoint: http://service-discovery:9000

Endpoints:
  GET  /services          # List all registered services
  PUT  /increment?service_id={id}   # Increment request count
  DELETE /deregister?service_id={id} # Deregister failing replica
```

### How It Works

**1. Service Registration**
```
Docker Swarm starts replicas:
  - budgeting-service.1 (host: padstack_budgeting-service.1.xxx, port: 8087)
  - budgeting-service.2 (host: padstack_budgeting-service.2.xxx, port: 8087)

Each replica registers with service discovery on startup
```

**2. Gateway Discovery**
```
Gateway fetches registered services every 30s:
  GET http://service-discovery:9000/services

Builds upstream maps:
  /budgeting → [
    {URL: "http://padstack_budgeting-service.1.xxx:8087", RequestCount: 15, Healthy: true},
    {URL: "http://padstack_budgeting-service.2.xxx:8087", RequestCount: 12, Healthy: true}
  ]
```

**3. Request Routing**
```
Incoming request: GET /budgeting/api/transactions

Load Balancer selects:
  - Check all healthy instances for /budgeting
  - Find instance with minimum RequestCount (replica.2: 12 requests)
  - Route to: http://padstack_budgeting-service.2.xxx:8087
  - Increment local counter for that instance
  - Send PUT to service discovery to increment persistent counter
```

**4. Request Count Tracking**
```
After each forwarded request:
  1. Gateway increments local counter
  2. Sends: PUT http://service-discovery:9000/increment?service_id=padstack_budgeting-service.2.xxx
  3. Service discovery updates persistent request count
  4. Next discovery refresh pulls updated counts
```

### Load Balancing Algorithm

```go
// Least-Load Selection
func GetNextUpstream(path string) string {
    healthyInstances := filterHealthy(instances[path])
    
    minLoad := ∞
    selectedInstance := nil
    
    for instance in healthyInstances {
        if instance.RequestCount < minLoad {
            minLoad = instance.RequestCount
            selectedInstance = instance
        }
    }
    
    selectedInstance.RequestCount++
    return selectedInstance.URL
}
```

### Benefits

- **⚖️ Optimal Load Distribution**: Routes to least-loaded instance
- **🔄 Dynamic Scaling**: Automatically discovers new replicas
- **🏥 Health Awareness**: Excludes unhealthy instances from rotation
- **📊 Request Tracking**: Persistent request counts across gateway restarts
- **🎯 Replica-Level Precision**: Tracks each Docker Swarm replica individually

### Monitoring Load Distribution

```promql
# Prometheus queries for load balancer metrics
gateway_lb_instance_load{service="/budgeting"}           # Current load per instance
gateway_lb_instance_health{service="/budgeting"}         # Health status (1=healthy)
rate(gateway_lb_requests_total[5m])                      # Request rate per instance
```

## Monitoring & Observability

The gateway includes comprehensive monitoring with **Prometheus** and **Grafana**:

### Access Points
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Metrics Endpoint**: http://localhost:8000/metrics

### Key Metrics Tracked

#### Request Metrics
- 📊 **gateway_requests_total**: Total requests by service, method, status
- ⏱️ **gateway_request_duration_seconds**: Request latency histogram
- ❌ **gateway_request_timeouts_total**: Timeout occurrences

#### Load Balancer Metrics
- ⚖️ **gateway_lb_instance_load**: Current load per replica
- 🏥 **gateway_lb_instance_health**: Health status (1=healthy, 0=unhealthy)
- 📈 **gateway_lb_requests_total**: Requests routed to each instance

#### Circuit Breaker Metrics
- 🔥 **gateway_circuit_breaker_state**: Current state (0=closed, 1=open, 2=half-open)
- 📉 **gateway_circuit_breaker_failures_total**: Total failures recorded
- ⚡ **gateway_circuit_breaker_rejected_total**: Requests rejected while open

#### Cache Metrics
- 💾 **gateway_cache_hits_total**: Cache hit count
- 📭 **gateway_cache_misses_total**: Cache miss count
- ❗ **gateway_cache_errors_total**: Cache error count
- 📊 **Cache hit rate**: `hits / (hits + misses) × 100`

#### JWT Metrics
- 🔐 **gateway_jwt_generated_total**: JWT tokens generated
- ✅ **gateway_jwt_validation_success_total**: Successful validations
- ❌ **gateway_jwt_validation_errors_total**: Validation failures

#### Concurrency Metrics
- 🔢 **gateway_concurrent_requests**: Current concurrent requests
- 🚫 **gateway_concurrency_limit_reached_total**: Times limit was hit

### Pre-Built Grafana Dashboard

The **PAD FAF Gateway - Overview** dashboard includes:

1. **Request Rate Panel** - Requests/sec by service and method
2. **Error Rate Panel** - 5xx errors over time
3. **Request Latency Panel** - P50, P95, P99 latency percentiles
4. **Load Balancer Distribution** - Load across replica instances
5. **Instance Health Status** - Health of all upstream replicas
6. **Cache Performance** - Hit rate percentage and trends
7. **JWT Operations** - Token generation and validation rates
8. **Concurrent Requests** - Current concurrency by service
9. **Circuit Breaker Status** - Circuit states and trip events

### Quick Start
```bash
# Start monitoring stack
docker-compose up -d prometheus grafana

# Generate test traffic
curl -H "Authorization: Bearer <token>" http://localhost:8000/budgeting/api/transactions

# View dashboard
# Open http://localhost:3000 → Dashboards → PAD FAF Gateway - Overview
```

### Useful PromQL Queries

```promql
# Request rate per service
rate(gateway_requests_total[5m])

# Error percentage
rate(gateway_requests_total{status=~"5.."}[5m]) / rate(gateway_requests_total[5m]) * 100

# P95 latency
histogram_quantile(0.95, rate(gateway_request_duration_seconds_bucket[5m]))

# Cache hit rate
rate(gateway_cache_hits_total[5m]) / (rate(gateway_cache_hits_total[5m]) + rate(gateway_cache_misses_total[5m])) * 100

# Load balancer efficiency (standard deviation - lower is better)
stddev(gateway_lb_instance_load) by (service)

# Circuit breaker trip count
increase(gateway_circuit_breaker_failures_total[1h])
```


