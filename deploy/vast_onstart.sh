#!/usr/bin/env bash
# DarkReconRaptor Signal World — Vast.ai on-start script
# Paste into Vast instance "On-start Script" or run after SSH login

set -euo pipefail

ROOT="${DARK187_ROOT:-/workspace/dark187_v5.2_release}"
WEB="${ROOT}/ninja_framework/web"
LOG="/workspace/logs"
mkdir -p "$LOG"

echo "[+] DarkReconRaptor Vast.ai boot — $(date -Iseconds)"

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git curl python3 python3-pip python3-venv nginx 2>/dev/null || true

# Ollama (DarkMind GPU backend)
if ! command -v ollama &>/dev/null; then
  echo "[+] Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
fi
ollama serve > "$LOG/ollama.log" 2>&1 &
sleep 3
ollama pull llama3.2:3b 2>/dev/null || true

# Python deps for HUD
pip3 install -q flask flask-socketio flask-cors psutil 2>/dev/null || \
  python3 -m pip install -q flask flask-socketio flask-cors psutil

if [[ ! -d "$WEB" ]]; then
  echo "[!] ninja_framework not found at $WEB"
  echo "    Upload via: scp -P PORT -r dark187_v5.2_release root@IP:/workspace/"
  exit 1
fi

export NINJA_HOST="0.0.0.0"
export NINJA_PORT="5099"
export OLLAMA_HOST="http://127.0.0.1:11434"

# Signal World HUD (tmux session — survives SSH disconnect)
if command -v tmux &>/dev/null; then
  tmux kill-session -t signalworld 2>/dev/null || true
  tmux new-session -d -s signalworld "cd '$WEB' && python3 hud_server.py >> '$LOG/hud.log' 2>&1"
  echo "[+] Signal World HUD → 0.0.0.0:5099 (tmux: signalworld)"
else
  cd "$WEB" && nohup python3 hud_server.py >> "$LOG/hud.log" 2>&1 &
  echo "[+] Signal World HUD → 0.0.0.0:5099 (nohup)"
fi

# Optional: static darkreconraptor site
SITE="/workspace/darkreconraptor_site"
if [[ -d "$SITE" ]]; then
  tmux kill-session -t static 2>/dev/null || true
  tmux new-session -d -s static "cd '$SITE' && python3 -m http.server 3000 >> '$LOG/static.log' 2>&1"
  echo "[+] Static site → 0.0.0.0:3000"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  DARKRECONRAPTOR — VAST.AI SIGNAL WORLD ONLINE           ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  HUD:     http://0.0.0.0:5099/                           ║"
echo "║  Ollama:  http://0.0.0.0:11434/                          ║"
echo "║  Logs:    $LOG"
echo "║  tmux:    tmux attach -t signalworld                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "PUBLIC_IP: ${PUBLIC_IPADDR:-check Vast IP Port Info panel}"