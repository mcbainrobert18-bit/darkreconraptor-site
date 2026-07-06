#!/usr/bin/env bash
# DarkReconRaptor — deploy static site to VPS
# Usage: SERVER_IP=1.2.3.4 SSH_USER=root ./deploy.sh

set -euo pipefail

SERVER_IP="${SERVER_IP:?Set SERVER_IP}"
SSH_USER="${SSH_USER:-root}"
REMOTE_PATH="${REMOTE_PATH:-/var/www/darkreconraptor}"
SITE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Deploying $SITE_ROOT -> ${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}"

ssh "${SSH_USER}@${SERVER_IP}" "mkdir -p ${REMOTE_PATH}"
scp -r "${SITE_ROOT}/"* "${SSH_USER}@${SERVER_IP}:${REMOTE_PATH}/"

cat <<EOF

Next on VPS:
  sudo cp ${REMOTE_PATH}/deploy/nginx.conf /etc/nginx/sites-available/darkreconraptor
  sudo ln -sf /etc/nginx/sites-available/darkreconraptor /etc/nginx/sites-enabled/
  sudo nginx -t && sudo systemctl reload nginx
  sudo certbot --nginx -d darkreconraptor.com -d www.darkreconraptor.com \\
    -d hud.darkreconraptor.com -d beast.darkreconraptor.com -d operator.darkreconraptor.com

Njalla: A records @, www, hud, beast, operator -> ${SERVER_IP}
See deploy/NJALLA_DNS_SETUP.md
EOF