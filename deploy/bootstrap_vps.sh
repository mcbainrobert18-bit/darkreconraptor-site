#!/usr/bin/env bash
# DarkReconRaptor — one-shot VPS bootstrap (nginx + SSL + firewall)
# Run on the server after deploy.ps1 uploads files.

set -euo pipefail

REMOTE_PATH="${REMOTE_PATH:-/var/www/darkreconraptor}"
DOMAIN="darkreconraptor.com"
SUBDOMAINS="www hud beast operator"
EMAIL="${CERTBOT_EMAIL:-admin@${DOMAIN}}"

echo "[+] DarkReconRaptor VPS bootstrap — $(date -Iseconds)"

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq nginx certbot python3-certbot-nginx ufw curl

mkdir -p "$REMOTE_PATH"
chown -R www-data:www-data "$REMOTE_PATH" 2>/dev/null || true

cp "${REMOTE_PATH}/deploy/nginx.conf" /etc/nginx/sites-available/darkreconraptor
ln -sf /etc/nginx/sites-available/darkreconraptor /etc/nginx/sites-enabled/darkreconraptor
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable nginx
systemctl restart nginx

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

CERT_ARGS=()
for sub in $SUBDOMAINS; do
  CERT_ARGS+=(-d "${sub}.${DOMAIN}")
done
CERT_ARGS+=(-d "$DOMAIN")

certbot --nginx --non-interactive --agree-tos --email "$EMAIL" --redirect "${CERT_ARGS[@]}" || {
  echo "[!] certbot failed — DNS may not point here yet."
  echo "    Fix Njalla A records, wait 10 min, then run:"
  echo "    sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} -d hud.${DOMAIN} -d beast.${DOMAIN} -d operator.${DOMAIN}"
}

systemctl reload nginx

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  DARKRECONRAPTOR VPS READY                               ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Site:  https://www.${DOMAIN}/                           ║"
echo "║  Path:  ${REMOTE_PATH}                                   ║"
echo "╚══════════════════════════════════════════════════════════╝"