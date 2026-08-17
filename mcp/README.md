# MCP Docker

Docker Compose services for Grafana and Prometheus MCP endpoints.

Persian version: [README.fa.md](./README.fa.md)

## Services

| Service | Endpoint |
|---|---|
| Grafana | `http://127.0.0.1:8101/mcp` |
| Prometheus | `http://127.0.0.1:8103/mcp` |

All ports bind to loopback and are not exposed to the network.

## File-based setup

```powershell
Set-Location 'D:\path\to\repository\mcp'
Copy-Item mcp-grafana.env.example mcp-grafana.env
```

Edit the copied files and replace all placeholder values. Then run:

```powershell
docker compose -f docker-compose.mcp.yml config
docker compose -f docker-compose.mcp.yml up -d
docker compose -f docker-compose.mcp.yml ps
```

## Process environment setup

Use `docker-compose.mcp.env.yml` when configuration is supplied through process environment variables. Required observability variables are:

```text
GRAFANA_URL
GRAFANA_SERVICE_ACCOUNT_TOKEN
PROMETHEUS_URL
```

Missing required variables cause Compose validation to fail before startup.

## Client configuration

```json
{
  "mcpServers": {
    "grafana": { "url": "http://127.0.0.1:8101/mcp" },
    "prometheus": { "url": "http://127.0.0.1:8103/mcp" }
  }
}
```

## Operations

```powershell
docker compose -f docker-compose.mcp.yml logs -f grafana
docker compose -f docker-compose.mcp.yml logs -f prometheus
docker compose -f docker-compose.mcp.yml down
```

Never commit populated `.env` files or access tokens. Only `*.env.example` files belong in Git.
