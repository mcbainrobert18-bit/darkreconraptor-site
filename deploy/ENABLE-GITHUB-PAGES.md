# Enable GitHub Pages (2 minutes)

Repo: https://github.com/mcbainrobert18-bit/darkreconraptor-site

## 1. Turn on Pages

1. Open **Settings** → **Pages**
2. **Build and deployment** → Source: **Deploy from a branch**
3. Branch: **main** · Folder: **/ (root)** → **Save**

Site preview (before custom domain):  
https://mcbainrobert18-bit.github.io/darkreconraptor-site/

## 2. Custom domain

Still on the Pages settings screen:

1. **Custom domain** → enter `www.darkreconraptor.com` → **Save**
2. Wait for DNS check (needs Njalla CNAME from step 3 below)
3. When green checkmark appears → enable **Enforce HTTPS**

## 3. Njalla DNS

See `njalla-dns-github.txt` — one CNAME record:

```
www  CNAME  mcbainrobert18-bit.github.io
```

Delete the old `www` → `sites.super.myninja.ai` record first.

## 4. Update site later

Double-click `PUBLISH-GITHUB.bat` or run:

```powershell
cd C:\Users\xxdae\darkreconraptor_site\deploy
.\PUBLISH-GITHUB.ps1
```