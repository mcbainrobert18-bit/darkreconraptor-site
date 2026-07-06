# DarkReconRaptor.com — Njalla DNS Setup

**Domain:** `darkreconraptor.com`  
**Registrar:** [njal.la](https://njal.la)  
**Operator:** XxDark187xX

---

## Current status (check before editing)

As of setup, DNS may still point to NinjaTech:

| Host | Current | Target |
|------|---------|--------|
| `@` (apex) | AWS CloudFront IPs | **Your VPS IP** |
| `www` | CNAME → `sites.super.myninja.ai` | **A → Your VPS IP** |

**Fix:** Remove the `www` CNAME to NinjaTech. Replace with an A record to your VPS.

---

## Step 1 — Njalla DNS records

Log in to [njal.la](https://njal.la) → **Domains** → `darkreconraptor.com` → **DNS**

Replace `YOUR_SERVER_IP` with your VPS public IPv4 (e.g. RackNerd, Hetzner, Njalla VPS).

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A | `@` | `YOUR_SERVER_IP` | 3600 |
| A | `www` | `YOUR_SERVER_IP` | 3600 |
| A | `hud` | `YOUR_SERVER_IP` | 3600 |
| A | `beast` | `YOUR_SERVER_IP` | 3600 |
| A | `operator` | `YOUR_SERVER_IP` | 3600 |

**Delete** any existing record that points `www` to `sites.super.myninja.ai` or other third-party hosts.

Propagation: usually 5–60 minutes. Verify:

```bash
nslookup darkreconraptor.com
nslookup www.darkreconraptor.com
```

Both should return `YOUR_SERVER_IP`.

---

## Step 2 — Upload site files to VPS

From your Windows machine (PowerShell):

```powershell
scp -r C:\Users\xxdae\darkreconraptor_site\* user@YOUR_SERVER_IP:/var/www/darkreconraptor/
```

Or use the included `deploy.ps1` / `deploy.sh` after setting `SERVER_IP` and `SSH_USER`.

---

## Step 3 — Nginx + SSL on VPS

```bash
sudo apt update && sudo apt install -y nginx certbot python3-certbot-nginx
sudo mkdir -p /var/www/darkreconraptor
sudo cp deploy/nginx.conf /etc/nginx/sites-available/darkreconraptor
sudo ln -sf /etc/nginx/sites-available/darkreconraptor /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

sudo certbot --nginx -d darkreconraptor.com -d www.darkreconraptor.com \
  -d hud.darkreconraptor.com -d beast.darkreconraptor.com -d operator.darkreconraptor.com
```

---

## Step 4 — URL map (what lives where)

| URL | Content |
|-----|---------|
| `https://www.darkreconraptor.com/` | Main hub landing |
| `https://www.darkreconraptor.com/guide/` | XxDark187xX Master Guide |
| `https://www.darkreconraptor.com/shop/` | Lab Edition product shop |
| `https://www.darkreconraptor.com/lab/` | Recon Raptor Lab overview |
| `https://hud.darkreconraptor.com/` | Signal Overlay (port 5000 when app running) |
| `https://beast.darkreconraptor.com/` | BEAST dashboard (port 8888) |
| `https://operator.darkreconraptor.com/` | Operator console (port 5000) |

Static pages (/, /guide/, /shop/, /lab/) work immediately after nginx deploy.  
Subdomains proxy to local apps when you start them:

```bash
# If using ReconRaptor LAB launcher:
python3 launch.py --landing   # port 3000 (optional override)
python3 launch.py --hud       # port 5000
python3 launch.py --beast     # port 8888
```

---

## Step 5 — Keep it alive (systemd)

```bash
sudo nano /etc/systemd/system/darkreconraptor-landing.service
```

```ini
[Unit]
Description=DarkReconRaptor static site (optional app server)
After=network.target

[Service]
WorkingDirectory=/var/www/darkreconraptor
ExecStart=/usr/bin/python3 -m http.server 3000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable darkreconraptor-landing
sudo systemctl start darkreconraptor-landing
```

Nginx serves static files directly — the systemd unit is only needed if you proxy port 3000.

---

## Njalla + crypto stack (privacy)

| Item | Provider | Cost |
|------|----------|------|
| Domain | Njalla | ~$15/year (BTC/XMR) |
| VPS | Njalla / RackNerd / Hetzner | $3–6/mo |
| SSL | Let's Encrypt | Free |

Pay with Monero on Njalla for maximum privacy. Same registrar for domain + VPS = one dashboard.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `www` still shows NinjaTech | Delete CNAME at Njalla; wait for TTL; flush DNS `ipconfig /flushdns` |
| SSL fails | Ensure all A records point to same VPS before certbot |
| 502 on hud/beast | App not running on 5000/8888 — start launcher or disable proxy blocks |
| Apex works, www doesn't | Add explicit `www` A record (don't rely on CNAME) |

---

**You own it forever:** code on GitHub + VPS + Njalla domain = no NinjaTech session dependency.