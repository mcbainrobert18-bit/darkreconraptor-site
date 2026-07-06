# DarkReconRaptor + Signal World on Vast.ai

**Use case:** Cheap GPU cloud for Ollama (DarkMind), Hackers Underground HUD, and BEAST — pay per hour, destroy when done.

| Provider | Best for | Cost |
|----------|----------|------|
| **Vast.ai** | GPU + Ollama + Signal World sessions | ~$0.15–0.60/hr |
| **Njalla VPS** | 24/7 domain (`darkreconraptor.com`) | ~$5/mo |
| **Stack both** | Vast = AI power, Njalla = permanent brand URL | Best of both |

---

## Step 1 — Vast.ai account + SSH key

1. Sign up: [cloud.vast.ai](https://cloud.vast.ai/)
2. Generate SSH key (PowerShell):

```powershell
ssh-keygen -t ed25519 -C "xxdark187@vast"
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
```

3. Paste public key at [cloud.vast.ai/manage-keys](https://cloud.vast.ai/manage-keys/)

Optional CLI:

```powershell
py -m pip install vastai
vastai set api-key YOUR_VAST_API_KEY
vastai create ssh-key
```

---

## Step 2 — Rent a GPU instance

Search filters (cheapest that works):

| Setting | Value |
|---------|-------|
| GPU | RTX 3090 / 4090 / A10 (any 8GB+ VRAM) |
| Disk | **30GB+** (Ollama models need space) |
| Image | `pytorch/pytorch` or `ubuntu:22.04` |
| Launch mode | **SSH** |
| On-start | paste `vast_onstart.sh` contents (see below) |

**Docker options** — add these ports in the instance template:

```
-p 5099:5099 -p 8888:8888 -p 11434:11434 -e OPEN_BUTTON_PORT=5099
```

After boot → click instance → **IP Port Info** to see mapped external ports.

Example:

```
65.130.162.74:33526 -> 5099/tcp   ← Signal World HUD
65.130.162.74:33527 -> 8888/tcp   ← BEAST
65.130.162.74:33528 -> 11434/tcp  ← Ollama
```

---

## Step 3 — Upload your ninja build

From Windows (replace IP, port, paths):

```powershell
cd C:\Users\xxdae\darkreconraptor_site\deploy
.\deploy_vast.ps1 -SshHost "142.214.185.187" -SshPort 20544
```

Or manual SCP:

```powershell
scp -P 20544 -r "C:\Users\xxdar\OneDrive\Desktop\dark187_v5.2_release" root@INSTANCE_IP:/workspace/dark187_v5.2_release
scp -P 20544 "C:\Users\xxdae\darkreconraptor_site\deploy\vast_onstart.sh" root@INSTANCE_IP:/workspace/onstart.sh
```

SSH in and start:

```bash
chmod +x /workspace/onstart.sh
bash /workspace/onstart.sh
```

---

## Step 4 — Open Signal World

**Option A — Direct (use Vast mapped port from IP Port Info):**

```
http://PUBLIC_IP:EXTERNAL_PORT_5099/
```

**Option B — SSH tunnel (works from localhost, Quest on same LAN):**

```powershell
ssh -p SSH_PORT root@INSTANCE_IP -L 5099:localhost:5099 -L 8888:localhost:8888 -L 11434:localhost:11434
```

Then open: [http://127.0.0.1:5099/](http://127.0.0.1:5099/)

**Quest VR:** Use your PC's LAN IP with the tunnel, or open the Vast external URL in Quest Browser.

---

## Step 5 — Pull Ollama model (first run)

SSH into instance:

```bash
ollama pull llama3.2:3b
# or for GPU: ollama pull mistral:7b
```

DarkMind will use Ollama at `http://127.0.0.1:11434`.

---

## Step 6 — Link to darkreconraptor.com (optional)

Vast IPs and ports change every session. Two patterns:

| Pattern | How |
|---------|-----|
| **Dev / demos** | SSH tunnel → localhost (no DNS change) |
| **Live subdomain** | Point `hud.darkreconraptor.com` A record to Vast `PUBLIC_IP` — update Njalla each session |
| **Production** | Keep Njalla VPS for static site; Vast only for GPU sessions |

For a stable URL, use Njalla VPS ($5/mo) for the site and spin up Vast only when you need GPU/Ollama.

---

## Cost control

```bash
# Stop instance (keeps disk, stops billing)
vastai stop instance $CONTAINER_ID --api-key $CONTAINER_API_KEY

# Destroy when done (no more charges)
vastai destroy instance $CONTAINER_ID --api-key $CONTAINER_API_KEY
```

**Rule:** Destroy the instance when you're done. Vast bills per second while running.

---

## What runs on the instance

| Service | Port | URL path |
|---------|------|----------|
| Hackers Underground Signal World | 5099 | `/` |
| ReconRaptor BEAST | 8888 | `/` |
| Ollama (DarkMind backend) | 11434 | API |
| Static site (optional) | 80 | nginx |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Permission denied SSH | Key not in Vast account — add at manage-keys, **new instance only** |
| HUD 502 | `bash /workspace/onstart.sh` — check `tmux attach -t signalworld` |
| Ollama slow | Pull smaller model: `llama3.2:3b` |
| Out of disk | Rent instance with 40GB+ disk at create time (can't resize after) |
| Port not reachable | Check IP Port Info — Vast maps random external ports |

---

**Operator:** XxDark187xX · **Brand:** darkreconraptor.com · **Authorized research only**