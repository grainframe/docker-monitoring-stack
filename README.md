# docker-monitoring-stack

Self-hosted monitoring for Linux servers: Prometheus + Grafana + Node Exporter + Alertmanager.  
Full visibility into CPU, memory, disk, and network — from `git clone` to working dashboards in under 5 minutes.

## Result

| | Before | After |
|---|---|---|
| Time to see server metrics | 30–120 min (manual install) | < 5 min (`./setup.sh`) |
| Dashboards | 0 | 8 panels auto-provisioned |
| Alert rules | 0 | 5 (CPU, memory, disk, load, node down) |
| Data retention | — | 30 days |

## Stack

| Component | Version | Role |
|---|---|---|
| Prometheus | 2.51 | Metrics collection and alerting |
| Grafana | 10.4 | Dashboards |
| Node Exporter | 1.7 | Linux host metrics |
| Alertmanager | 0.27 | Alert routing (Telegram / email) |

## Quick start

```bash
git clone https://github.com/grainframe/docker-monitoring-stack
cd docker-monitoring-stack
chmod +x setup.sh
./setup.sh
```

Then open **http://localhost:3000** (admin / changeme).

The dashboard loads automatically — no manual import needed.

## Ports

| Service | Default port |
|---|---|
| Grafana | 3000 |
| Prometheus | 9090 |
| Alertmanager | 9093 |
| Node Exporter | (internal only) |

All ports are configurable in `.env`.

## Configure alerts

Edit `alertmanager/alertmanager.yml` and uncomment the Telegram or email block:

```yaml
# Telegram
telegram_configs:
  - bot_token: 'YOUR_BOT_TOKEN'
    chat_id: YOUR_CHAT_ID
```

Then reload without restarting:

```bash
curl -X POST http://localhost:9093/-/reload
```

## Monitor additional servers

1. Install node-exporter on the target:
   ```bash
   docker run -d --pid=host --net=host \
     -v /proc:/host/proc:ro -v /sys:/host/sys:ro \
     prom/node-exporter:v1.7.0 \
     --path.procfs=/host/proc --path.sysfs=/host/sys
   ```

2. Add the target to `prometheus/prometheus.yml`:
   ```yaml
   - job_name: 'web-01'
     static_configs:
       - targets: ['192.168.1.10:9100']
   ```

3. Reload Prometheus:
   ```bash
   curl -X POST http://localhost:9090/-/reload
   ```

## Repository layout

```
docker-monitoring-stack/
├── docker-compose.yml
├── setup.sh
├── .env.example
├── prometheus/
│   ├── prometheus.yml          # Scrape config + alert rules reference
│   └── rules/
│       └── alerts.yml          # 5 alert rules (CPU, mem, disk, load, down)
├── alertmanager/
│   └── alertmanager.yml        # Routing + receiver config
└── grafana/
    └── provisioning/
        ├── datasources/
        │   └── prometheus.yml  # Auto-wires Prometheus datasource
        └── dashboards/
            ├── dashboard.yml   # Tells Grafana where to find JSON
            └── node-overview.json  # 8-panel system dashboard
```

## Stop / remove

```bash
./setup.sh --down    # stop, keep data
./setup.sh --purge   # stop, delete volumes
```

## Requirements

- Docker ≥ 24
- Docker Compose ≥ 2.x
- Linux host (Debian 11/12, Ubuntu 20.04/22.04 tested)
