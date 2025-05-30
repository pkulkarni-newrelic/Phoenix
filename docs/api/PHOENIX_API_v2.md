# Phoenix Platform API Documentation v2

## Overview

Phoenix Platform API provides a unified control plane for observability cost optimization. The API follows REST principles with JSON payloads and includes WebSocket support for real-time updates.

## Base URLs

- **API**: `http://localhost:8080/api/v1`
- **WebSocket**: `ws://localhost:8081/api/v1/ws`

## Table of Contents

- [Authentication](#authentication)
- [Experiments API](#experiments-api)
- [Fleet Management API](#fleet-management-api)
- [Pipeline API](#pipeline-api)
- [Metrics & Analytics API](#metrics--analytics-api)
- [Agent API](#agent-api)
- [WebSocket Events](#websocket-events)
- [Error Handling](#error-handling)

---

## Authentication

Agent endpoints require the `X-Agent-Host-ID` header. User-facing endpoints currently don't require authentication in development mode.

```bash
# Agent authentication
curl -H "X-Agent-Host-ID: agent-001" http://localhost:8080/api/v1/agent/tasks
```

---

## Experiments API

### Create Experiment (Wizard)

**POST** `/api/v1/experiments/wizard`

Simplified experiment creation for UI.

```json
{
  "name": "Reduce API costs Q1",
  "description": "Optimize high-traffic API metrics",
  "host_selector": ["group:prod-api", "env=production"],
  "pipeline_type": "top-k-20",
  "duration_hours": 24
}
```

**Response**: `201 Created`
```json
{
  "id": "exp-123",
  "name": "Reduce API costs Q1",
  "status": "pending",
  "created_at": "2024-01-15T10:00:00Z",
  "estimated_savings_percent": 72
}
```

### List Experiments

**GET** `/api/v1/experiments`

**Response**: `200 OK`
```json
[
  {
    "id": "exp-123",
    "name": "Reduce API costs Q1",
    "status": "running",
    "phase": "baseline",
    "baseline_cost": 5000,
    "candidate_cost": 3000,
    "savings_percent": 40,
    "created_at": "2024-01-15T10:00:00Z"
  }
]
```

### Get Experiment Details

**GET** `/api/v1/experiments/{id}`

### Start Experiment

**POST** `/api/v1/experiments/{id}/start`

### Stop Experiment

**POST** `/api/v1/experiments/{id}/stop`

### Promote Experiment

**POST** `/api/v1/experiments/{id}/promote`

Promotes candidate pipeline to production.

### Instant Rollback

**POST** `/api/v1/experiments/{id}/rollback`

Immediately rolls back to baseline configuration.

**Response**: `200 OK`
```json
{
  "status": "success",
  "message": "Rollback initiated",
  "affected_hosts": 45
}
```

---

## Fleet Management API

### Get Fleet Status

**GET** `/api/v1/fleet/status`

Returns comprehensive agent fleet status.

**Response**: `200 OK`
```json
{
  "total_agents": 150,
  "healthy_agents": 145,
  "offline_agents": 2,
  "updating_agents": 3,
  "total_savings": 125000,
  "agents": [
    {
      "host_id": "prod-api-001",
      "status": "healthy",
      "group": "prod-api",
      "active_tasks": [],
      "metrics": {
        "cpu_percent": 12.5,
        "memory_mb": 256,
        "metrics_per_sec": 45000,
        "dropped_count": 0
      },
      "cost_savings": 2500,
      "last_heartbeat": "2024-01-15T10:30:00Z",
      "location": {
        "region": "us-east",
        "zone": "us-east-1a"
      }
    }
  ]
}
```

### Get Agent Map

**GET** `/api/v1/fleet/map`

Returns agents with geographical location for map visualization.

---

## Pipeline API

### List Pipeline Templates

**GET** `/api/v1/pipelines/templates`

**Response**: `200 OK`
```json
[
  {
    "id": "top-k-20",
    "name": "Top-K Filter (K=20)",
    "description": "Keep only top 20 metrics by value",
    "category": "cost_optimization",
    "estimated_savings_percent": 72,
    "estimated_cpu_impact": 0.5,
    "estimated_memory_impact_mb": 10,
    "ui_preview": {
      "processor_blocks": [
        {
          "type": "top_k",
          "name": "Top 20 Filter",
          "config": {"k": 20}
        }
      ]
    }
  }
]
```

### Preview Pipeline Impact

**POST** `/api/v1/pipelines/preview`

Calculate impact without deploying.

```json
{
  "pipeline_config": {
    "processors": [
      {"type": "top_k", "config": {"k": 20}}
    ]
  },
  "target_hosts": ["group:prod-api"]
}
```

**Response**: `200 OK`
```json
{
  "estimated_cost_reduction": 65.5,
  "estimated_cardinality_reduction": 72.3,
  "estimated_cpu_impact": 1.2,
  "estimated_memory_impact": 45,
  "confidence_level": 0.85
}
```

### Quick Deploy Pipeline

**POST** `/api/v1/pipelines/quick-deploy`

One-click pipeline deployment.

```json
{
  "pipeline_template": "top-k-20",
  "target_hosts": ["group:prod-api"],
  "auto_rollback": true
}
```

**Response**: `202 Accepted`
```json
{
  "deployment_id": "dep-456",
  "hosts_count": 45,
  "status": "deploying"
}
```

---

## Metrics & Analytics API

### Get Metric Cost Flow

**GET** `/api/v1/metrics/cost-flow`

Real-time metric cost breakdown.

**Response**: `200 OK`
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "total_cost_rate": 125.50,
  "top_metrics": [
    {
      "metric_name": "process.cpu.usage",
      "cost_per_minute": 45.25,
      "cardinality": 125000,
      "percentage": 36.1,
      "labels": {
        "service": "api-gateway",
        "env": "production"
      }
    }
  ],
  "by_service": {
    "api-gateway": 45.25,
    "auth-service": 23.10
  },
  "by_namespace": {
    "production": 98.50,
    "staging": 27.00
  }
}
```

### Get Cardinality Breakdown

**GET** `/api/v1/metrics/cardinality?namespace=production&service=api`

### Get Cost Analytics

**GET** `/api/v1/cost-analytics?period=30d`

---

## Agent API

These endpoints are used by Phoenix agents.

### Poll for Tasks (Long-poll)

**GET** `/api/v1/agent/tasks`

Headers: `X-Agent-Host-ID: agent-001`

Long-polling endpoint with 30s timeout.

**Response**: `200 OK`
```json
[
  {
    "id": "task-789",
    "type": "deploy_pipeline",
    "experiment_id": "exp-123",
    "config": {
      "pipeline_url": "http://api/configs/top-k-20.yaml",
      "variant": "candidate"
    },
    "priority": 1
  }
]
```

### Update Task Status

**POST** `/api/v1/agent/tasks/{taskId}/status`

```json
{
  "status": "completed",
  "message": "Pipeline deployed successfully",
  "metrics": {
    "deployment_time_ms": 1250
  }
}
```

### Send Heartbeat

**POST** `/api/v1/agent/heartbeat`

```json
{
  "status": "healthy",
  "metrics": {
    "cpu_percent": 12.5,
    "memory_mb": 256,
    "metrics_per_sec": 45000
  },
  "active_pipelines": ["baseline", "candidate"],
  "agent_version": "1.0.0"
}
```

---

## WebSocket Events

Connect to `ws://localhost:8081/api/v1/ws` for real-time updates.

### Event Types

#### agent_status
```json
{
  "type": "agent_status",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "host_id": "prod-api-001",
    "status": "healthy",
    "metrics": {
      "cpu_percent": 12.5,
      "metrics_per_sec": 45000
    }
  }
}
```

#### experiment_update
```json
{
  "type": "experiment_update",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "experiment_id": "exp-123",
    "status": "running",
    "progress": 65,
    "metrics": {
      "baseline_cost": 5000,
      "candidate_cost": 3000,
      "savings_percent": 40
    }
  }
}
```

#### metric_flow
```json
{
  "type": "metric_flow",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "total_cost_rate": 125.50,
    "top_metrics": [...]
  }
}
```

#### task_progress
```json
{
  "type": "task_progress",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "task_id": "task-789",
    "progress": 80,
    "total_hosts": 45,
    "completed_hosts": 36
  }
}
```

### Subscribing to Events

Send subscription message after connecting:

```json
{
  "type": "subscribe",
  "payload": {
    "events": ["agent_status", "experiment_update"],
    "filters": {
      "experiments": ["exp-123"],
      "hosts": ["prod-api-*"]
    }
  }
}
```

---

## Task Management API

### Get Active Tasks

**GET** `/api/v1/tasks/active?status=running&limit=100`

### Get Task Queue Status

**GET** `/api/v1/tasks/queue`

**Response**: `200 OK`
```json
{
  "pending_tasks": 12,
  "running_tasks": 5,
  "completed_tasks": 145,
  "failed_tasks": 2,
  "tasks_by_type": {
    "deploy_pipeline": 8,
    "start_collector": 4
  },
  "average_wait_time": 2500
}
```

---

## Error Handling

All errors follow consistent format:

```json
{
  "error": "invalid_request",
  "message": "Pipeline template not found",
  "details": {
    "template": "unknown-template",
    "available": ["top-k-20", "priority-sli-slo"]
  }
}
```

Common status codes:
- `200 OK`: Success
- `201 Created`: Resource created
- `202 Accepted`: Async operation started
- `400 Bad Request`: Invalid parameters
- `401 Unauthorized`: Missing authentication
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

---

## Rate Limiting

- Default: 1000 requests/minute per IP
- Agent endpoints: 10,000 requests/minute
- WebSocket: 100 messages/second

Headers:
- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `X-RateLimit-Reset`

---

## SDK Examples

### JavaScript/TypeScript
```typescript
// Connect to WebSocket
const ws = new WebSocket('ws://localhost:8081/api/v1/ws');

ws.on('open', () => {
  // Subscribe to events
  ws.send(JSON.stringify({
    type: 'subscribe',
    payload: {
      events: ['metric_flow', 'agent_status']
    }
  }));
});

ws.on('message', (data) => {
  const event = JSON.parse(data);
  console.log(`Event: ${event.type}`, event.data);
});

// Create experiment via API
const response = await fetch('/api/v1/experiments/wizard', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    name: 'Optimize API costs',
    host_selector: ['env=prod'],
    pipeline_type: 'top-k-20',
    duration_hours: 24
  })
});
```

### Python
```python
import requests
import websocket

# Get fleet status
response = requests.get('http://localhost:8080/api/v1/fleet/status')
fleet = response.json()
print(f"Healthy agents: {fleet['healthy_agents']}/{fleet['total_agents']}")

# Quick deploy pipeline
response = requests.post('http://localhost:8080/api/v1/pipelines/quick-deploy',
    json={
        'pipeline_template': 'top-k-20',
        'target_hosts': ['group:prod-api']
    })
print(f"Deployment started: {response.json()['deployment_id']}")
```

### Go
```go
// Agent heartbeat
type Heartbeat struct {
    Status  string      `json:"status"`
    Metrics AgentMetrics `json:"metrics"`
}

client := &http.Client{}
data, _ := json.Marshal(Heartbeat{
    Status: "healthy",
    Metrics: AgentMetrics{
        CPUPercent: 12.5,
        MemoryMB: 256,
    },
})

req, _ := http.NewRequest("POST", "http://localhost:8080/api/v1/agent/heartbeat", bytes.NewBuffer(data))
req.Header.Set("X-Agent-Host-ID", "agent-001")
req.Header.Set("Content-Type", "application/json")
client.Do(req)
```

---

## Migration from v1

Key changes from previous API:
- Consolidated endpoints under single Phoenix API
- Agent-based instead of Kubernetes-centric
- WebSocket for real-time updates
- Simplified experiment creation with wizard
- Visual pipeline configuration support

---

## OpenAPI Specification

Available at: `http://localhost:8080/api/v1/openapi.json` (planned)