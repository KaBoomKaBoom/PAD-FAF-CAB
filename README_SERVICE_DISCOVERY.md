# PAD-Service-Discovery

A microservices architecture with Docker Swarm deployment and a custom Service Discovery system built in Go.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Service Discovery](#service-discovery)
  - [Features](#features)
  - [API Endpoints](#api-endpoints)
  - [Health Checking](#health-checking)
- [Deployment](#deployment)
  - [Four-Stage Automated Deployment](#four-stage-automated-deployment-recommended)
  - [Manual Four-Stage Deployment](#manual-four-stage-deployment)
  - [Single-File Deployment](#single-file-deployment-alternative)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Integration Guide](#integration-guide)

---

## Overview

This project implements a microservices architecture with:
- **11 Microservices**: budgeting, lost-found, user-management, notification, cab-booking, checkin, tea-management, communication, sharing, fund-raising, and API Gateway
- **Service Discovery**: Custom Go-based service registry with health checking
- **Databases**: 10 PostgreSQL instances, 1 MongoDB, 1 Redis
- **Admin Tools**: Adminer, Mongo Express
- **Orchestration**: Docker Swarm for production-grade deployment

---

## Architecture

### Services Layer

```
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway (8080)                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Service Discovery (8002)                       │
│  - Service Registration                                     │
│  - Service Lookup                                           │
│  - Health Monitoring                                        │
│  - Gateway Load Balancing Info                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│                    Microservices                           │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │ Budgeting  │  │Lost & Found│  │User Mgmt   │            │
│  │   (8087)   │  │   (8088)   │  │   (8080)   │            │
│  └────────────┘  └────────────┘  └────────────┘            │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │Notification│  │ Cab Booking│  │  Check-in  │            │
│  │   (8081)   │  │   (8084)   │  │   (8085)   │            │
│  └────────────┘  └────────────┘  └────────────┘            │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │   Tea      │  │Communicatio│  │  Sharing   │            │
│  │   (8082)   │  │   (8083)   │  │   (8088)   │            │
│  └────────────┘  └────────────┘  └────────────┘            │
│  ┌────────────┐                                            │
│  │Fund Raising│                                            │
│  │   (8089)   │                                            │
│  └────────────┘                                            │
└────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│                     Database Layer                           │
│  10 PostgreSQL + 1 MongoDB + 1 Redis                         │
└──────────────────────────────────────────────────────────────┘
```

### Network
All services run on the Docker Swarm overlay network (`test-stack_default`) created by the stack.

### Volumes
Each database has persistent storage via Docker volumes for data persistence.

---

## Service Discovery

A simple, modular Service Discovery service written in Go that allows microservices to register themselves on startup and provides health monitoring.

### Features

- ✅ **Service Registration**: POST endpoint for microservices to register
- ✅ **Service Lookup**: GET endpoints to retrieve registered services
- ✅ **Automated Health Checking**: Periodic health checks of registered services
- ✅ **Health Status Tracking**: Monitor service health and request counts
- ✅ **Gateway Load Balancing**: Optimized endpoint for API Gateway routing decisions
- ✅ **Thread-Safe**: Concurrent access handled with mutex locks
- ✅ **Modular Design**: Clean separation of concerns

### API Endpoints

#### 1. Register a Service
**POST** `/register`

Register a new microservice with the discovery service.

**Request Body:**
```json
{
  "name": "budgeting",
  "host": "test-stack_budgeting-service.1.xyz",
  "port": 8087,
  "health_check": "<health_route>"
}
```

**Response (201 Created):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "budgeting",
  "host": "test-stack_budgeting-service.1.xyz",
  "port": 8087,
  "health_check": "health",
  "registered_at": "2025-10-21T10:30:00Z",
  "status": "healthy"
}
```

#### 2. Get All Services
**GET** `/services`

Retrieve all registered services with their health status.

**Response (200 OK):**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "budgeting",
    "host": "test-stack_budgeting-service.1.xyz",
    "port": 8087,
    "health_check": "health",
    "registered_at": "2025-10-21T10:30:00Z",
    "status": "healthy",
    "last_check": "2025-10-21T10:35:00Z",
    "request_count": 42,
    "message": "Service is healthy"
  }
]
```

#### 3. Get Services by Name
**GET** `/services?name=budgeting`

Retrieve all instances of a specific service.

**Response (200 OK):**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "budgeting",
    "host": "test-stack_budgeting-service.1.xyz",
    "port": 8087,
    "status": "healthy",
    "request_count": 42
  }
]
```

#### 4. Get Gateway Service Info
**GET** `/gateway/services?name=budgeting`

Get service instances optimized for API Gateway load balancing decisions. Returns active hosts with their request counts.

**Response (200 OK):**
```json
{
  "name": "budgeting",
  "instances": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "host": "test-stack_budgeting-service.1.xyz",
      "port": 8087,
      "status": "healthy",
      "request_count": 42
    },
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "host": "test-stack_budgeting-service.2.abc",
      "port": 8087,
      "status": "healthy",
      "request_count": 38
    }
  ],
  "total": 2,
  "healthy": 2
}
```

**Use Case**: Gateway can use this to:
- Route to the instance with lowest `request_count` (load balancing)
- Filter only `healthy` instances
- Implement round-robin or least-connections routing

#### 5. Increment Request Count
**PUT** `/services/increment?id={service_id}`

Increment the request count for a service. This endpoint is called by the Gateway on each forwarded request to track load.

**Request:**
```bash
curl -X PUT http://localhost:8002/services/increment?id=550e8400-e29b-41d4-a716-446655440000
```

**Response (200 OK):**
```json
{
  "message": "Request count incremented"
}
```

**Response (404 Not Found):**
```json
{
  "error": "Service not found: 550e8400-e29b-41d4-a716-446655440000"
}
```

**Use Case**: Gateway calls this endpoint after successfully forwarding a request to track which instances are receiving more load.

#### 6. Deregister a Service
**DELETE** `/deregister?id={host}`

Remove a service from the registry by its host address.

**Request:**
```bash
curl -X DELETE http://localhost:8002/deregister?id=test-stack_budgeting-service.1.xyz
```

**Response (200 OK):**
```json
{
  "message": "Service deregistered successfully"
}
```

**Response (404 Not Found):**
```json
{
  "error": "Service not found: test-stack_budgeting-service.1.xyz"
}
```

**Use Case**: Called when a service is shutting down or being removed from the system.

#### 7. Get Logs
**GET** `/logs`

Retrieve system logs from the Service Discovery.

**Optional Query Parameters:**
- `type`: Filter by log type (`INFO`, `WARNING`, `ERROR`, `CRITICAL`)
- `since`: Filter logs since a specific time (RFC3339 format)

**Request:**
```bash
# Get all logs
curl http://localhost:8002/logs

# Get only error logs
curl http://localhost:8002/logs?type=ERROR

# Get logs since a specific time
curl "http://localhost:8002/logs?since=2025-10-24T10:00:00Z"
```

**Response (200 OK):**
```json
{
  "total": 42,
  "logs": [
    {
      "timestamp": "2025-10-24T10:30:00Z",
      "type": "INFO",
      "message": "Service Discovery running on port 8002"
    },
    {
      "timestamp": "2025-10-24T10:30:15Z",
      "type": "INFO",
      "message": "Service 'budgeting' registered successfully"
    }
  ]
}
```

#### 8. Download Logs
**GET** `/logs/download`

Download all logs as a text file.

**Request:**
```bash
curl http://localhost:8002/logs/download -o service-discovery-logs.txt
```

**Response**: Plain text file with all logs

#### 9. Health Check
**GET** `/health`

Check if the Service Discovery itself is running.

**Response (200 OK):**
```json
{
  "status": "healthy"
}
```

### Health Checking

The Service Discovery automatically monitors all registered services at configurable intervals (default: 30 seconds).

#### How It Works

1. **Automatic Monitoring**: Service Discovery sends GET requests to each service's health endpoint
2. **Health Check Format**: `http://<host>:<port>/<health_check_path>`
3. **Expected Response**:
   ```json
   {
     "message": "Service is healthy",
     "requestsCount": 123
   }
   ```
   **Note**: The `requestsCount` field is informational only and is not used by Service Discovery. Request counts are managed separately by the Gateway using the increment endpoint.

4. **Request Count Tracking**: The Gateway increments request counts via the PUT `/services/increment` endpoint when forwarding requests. Initial count is 0 when a service registers.

#### Health Status Values

- **`unknown`**: Initial status after registration
- **`healthy`**: Service responded with valid health check
- **`unhealthy`**: Service failed to respond or returned error

#### Implementing Health Endpoints

```csharp
[ApiController]
[Route("[controller]")]
public class HealthController : ControllerBase
{
    private static int _requestCount = 0;

    [HttpGet]
    public IActionResult Get()
    {
        Interlocked.Increment(ref _requestCount);
        
        return Ok(new
        {
            message = "Service is healthy",
            requestsCount = _requestCount
        });
    }
}
```

##### Node.js/Express Example

```javascript
let requestCount = 0;

app.get('/health', (req, res) => {
  requestCount++;
  res.json({
    message: 'Service is healthy',
    requestsCount: requestCount
  });
});
```

##### Python/Flask Example

```python
request_count = 0

@app.route('/health', methods=['GET'])
def health():
    global request_count
    request_count += 1
    return jsonify({
        'message': 'Service is healthy',
        'requestsCount': request_count
    })
```

#### Configuration

| Environment Variable | Description | Default |
|---------------------|-------------|---------|
| `PORT` | Service Discovery port | `8002` |
| `HEALTH_CHECK_INTERVAL` | Seconds between health checks | `30` |

### Email Alerts

The Service Discovery system can send email notifications for important events. See [EMAIL_ALERTS.md](./EMAIL_ALERTS.md) for full configuration details.

#### Alert Types

- **🚀 Startup Summary** (Default): One consolidated email 5 minutes after startup showing all registered services
- **📧 Individual Registration** (Optional): Email for each service registration (enable with `SEND_INDIVIDUAL_ALERTS=true`)
- **⚠️ Service Deregistration**: Immediate alert when services are removed
- **🚨 Critical Load**: Alert when a service reaches the critical load threshold

#### Quick Setup

Add to your `.env` file:
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SENDER_EMAIL=your-email@gmail.com
SENDER_PASSWORD=your-app-password
RECIPIENT_EMAIL=alerts@example.com

# Optional: Enable individual alerts (default: false)
SEND_INDIVIDUAL_ALERTS=false
```

For Gmail setup instructions and testing, see the [Email Alerts Documentation](./EMAIL_ALERTS.md).

---

## Deployment

### Prerequisites

- Docker Desktop with Swarm mode enabled
- PowerShell (Windows) or Bash (Linux/Mac)

### Four-Stage Automated Deployment (Recommended)

This approach deploys the stack in the optimal order: Databases → Service Discovery → Microservices → API Gateway.

#### Using the Automated Script

```powershell
.\deploy-all.ps1
```

This script will:
1. ✅ Check Docker status and initialize Swarm if needed
2. ✅ Deploy databases and wait for initialization (60s)
3. ✅ Deploy Service Discovery and wait (30s)
4. ✅ Deploy all microservices and wait (45s)
5. ✅ Deploy API Gateway and wait (20s)
6. ✅ Display deployment summary and useful commands

### Manual Four-Stage Deployment

**Step 1: Initialize Docker Swarm**
```powershell
docker swarm init
```

**Step 2: Deploy Databases**
```powershell
docker stack deploy -c docker-compose.databases.yml test-stack
```

Wait 30-60 seconds for databases to initialize and become healthy.

**Step 3: Deploy Service Discovery**
```powershell
docker stack deploy -c docker-compose.discovery.yml test-stack
```

Wait 30 seconds for Service Discovery to start.

**Step 4: Deploy Microservices**
```powershell
docker stack deploy -c docker-compose.services.yml test-stack
```

Wait 45 seconds for microservices to initialize.

**Step 5: Deploy API Gateway**
```powershell
docker stack deploy -c docker-compose.gateway.yml test-stack
```

### Single-File Deployment (Alternative)

If you prefer using the original single compose file:

```powershell
docker stack deploy -c docker-compose.yml test-stack
```

**Note**: Services have restart policies configured, so they will retry connecting to databases automatically.

---

## Monitoring

### View All Services

```powershell
docker stack services test-stack
```

### View Service Logs

```powershell
# View logs
docker service logs test-stack_<service-name>

# Follow logs in real-time
docker service logs -f test-stack_<service-name>

# View Service Discovery logs
docker service logs -f test-stack_service-discovery
```

### Check Service Details

```powershell
docker service ps test-stack_<service-name>
```

