#!/usr/bin/env bash
# setup.sh — one-command bootstrap for docker-monitoring-stack
# Usage: ./setup.sh [--down] [--purge]

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

MODE="up"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --down)  MODE="down"; shift ;;
        --purge) MODE="purge"; shift ;;
        *) echo "Usage: $0 [--down] [--purge]"; exit 1 ;;
    esac
done

# ── Detect docker compose ──────────────────────────────────────────────────────
if docker compose version &>/dev/null 2>&1; then
    DC="docker compose"
elif docker-compose version &>/dev/null 2>&1; then
    DC="docker-compose"
else
    echo -e "${RED}Docker Compose not found.${NC}"
    echo "Install: https://docs.docker.com/compose/install/"
    exit 1
fi

command -v docker &>/dev/null || { echo -e "${RED}Docker not found.${NC}"; exit 1; }

# ── Down / purge ───────────────────────────────────────────────────────────────
if [[ "$MODE" == "down" ]]; then
    $DC down
    echo -e "${GREEN}Stack stopped. Data volumes preserved.${NC}"
    exit 0
fi

if [[ "$MODE" == "purge" ]]; then
    echo -e "${RED}Warning: this removes all monitoring data (volumes).${NC}"
    read -r -p "Confirm? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
    $DC down -v
    echo -e "${GREEN}Stack and volumes removed.${NC}"
    exit 0
fi

# ── Create .env ────────────────────────────────────────────────────────────────
if [[ ! -f .env ]]; then
    cp .env.example .env
    echo -e "${CYAN}Created .env from .env.example. Edit GRAFANA_PASSWORD before production use.${NC}"
fi

source .env

# ── Pull images ────────────────────────────────────────────────────────────────
echo -e "${CYAN}Pulling images...${NC}"
$DC pull --quiet

# ── Start stack ────────────────────────────────────────────────────────────────
echo -e "${CYAN}Starting stack...${NC}"
$DC up -d

# ── Wait for Grafana ───────────────────────────────────────────────────────────
GRAFANA_PORT="${GRAFANA_PORT:-3000}"
echo -n "Waiting for Grafana"
for i in {1..30}; do
    if curl -sf "http://localhost:${GRAFANA_PORT}/api/health" 2>/dev/null | grep -q '"database": "ok"'; then
        echo ""
        break
    fi
    echo -n "."
    sleep 2
done

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo "================================================================"
echo -e " ${GREEN}Stack is up${NC}"
echo ""
echo " Grafana      : http://localhost:${GRAFANA_PORT}"
echo "   User       : ${GRAFANA_USER:-admin}"
echo "   Password   : ${GRAFANA_PASSWORD:-changeme}"
echo " Prometheus   : http://localhost:${PROMETHEUS_PORT:-9090}"
echo " Alertmanager : http://localhost:${ALERTMANAGER_PORT:-9093}"
echo ""
echo " Stop         : ./setup.sh --down"
echo " Remove all   : ./setup.sh --purge"
echo "================================================================"
