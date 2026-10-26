# Prometheus Target Manager

FastAPI + PostgreSQL form for managing Prometheus HTTP service discovery targets.

## Start

```bash
cd target-manager
cp .env.example .env
# Edit .env, use long random passwords (DB_PASSWORD must be URL-safe).
docker compose up -d --build
```

UI: http://127.0.0.1:8080/ (HTTP Basic credentials from .env).

By default the service binds **only to localhost**. Put it behind a TLS reverse proxy with access controls for remote administrators. Restrict `/api/discovery/` to trusted Prometheus hosts using proxy or firewall rules; discovery itself does not require Basic authentication.

## Prometheus integration

The existing file discovery is retained. An optional scrape configuration snippet is provided in `prometheus-http-sd.example.yml` for Windows and SQL exporters. Copy the jobs into the main Prometheus configuration after adapting the URL and verifying connectivity. **Change `target-manager:8080` to a hostname/IP reachable from the Prometheus process**; that Docker hostname only works when Prometheus joins the same Docker network. With a host-installed Prometheus, expose the discovery API over a trusted internal HTTPS endpoint or a private interface (localhost Docker binding will not be accessible remotely). Restart/reload Prometheus after changing its YAML once; subsequent target edits are discovered automatically (30-second refresh).

New exporters added here (`node_exporter`, `postgres_exporter`, `mysql_exporter`) need separate Prometheus scrape jobs before being monitored. Exporters are **not installed** on target hosts by this application.

For existing Windows/SQL exporter jobs, the current `basic_auth` remains in effect for both file-discovered and HTTP-discovered targets. Validate exporter-side credentials and metric paths.

Endpoints: `GET /health`; authenticated `GET/POST /api/targets`, `PUT/DELETE /api/targets/{id}`; `GET /api/discovery/{exporter}`.

### Operational constraints

- Allow only trusted administrators to access the panel; HTTP Basic requires TLS for off-host access.
- Back up the PostgreSQL volume and rotate credentials regularly.
- HTTP discovery returns one group per enabled target. Disabled/deleted entries disappear from discovery on refresh.
- Avoid entering the same target via both legacy JSON files and the new form to prevent duplicate scrape configurations.
- The initial version does not provision exporters, test connectivity, support LDAP/RBAC, or keep audit history. Add these before broad multi-user production rollout.
