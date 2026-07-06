/* DARK RECON RAPTOR — Signal Overlay Control Center */
const API = window.location.origin + '/api';
let mode = localStorage.getItem('dr-mode') || 'grind';
let scanning = false;
let socket = null;

async function api(path, opts) {
  try {
    const r = await fetch(API + path, { cache: 'no-store', ...opts });
    return r.ok ? await r.json() : null;
  } catch (e) { return null; }
}

function setMode(m) {
  mode = m;
  localStorage.setItem('dr-mode', m);
  document.querySelectorAll('.mode-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.mode === m);
  });
  document.getElementById('mood-label').textContent = m === 'gaming' ? 'GAMING FACE' : 'GRIND $$$';
  document.getElementById('grind-panel').style.display = m === 'grind' ? 'block' : 'none';
  api('/signals/mode', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ mode: m }) });
}

function drawSpectrum(data) {
  const c = document.getElementById('spectrum-canvas');
  if (!c || !data) return;
  const ctx = c.getContext('2d');
  const w = c.width = c.offsetWidth;
  const h = c.height = c.offsetHeight || 180;
  ctx.fillStyle = '#050508';
  ctx.fillRect(0, 0, w, h);
  const spec = data.spectrum || [];
  const step = w / spec.length;
  spec.forEach((p, i) => {
    const norm = (p + 100) / 80;
    const barH = Math.max(2, norm * h * 0.9);
    const g = ctx.createLinearGradient(0, h, 0, 0);
    g.addColorStop(0, '#00f7ff');
    g.addColorStop(0.5, '#ffd700');
    g.addColorStop(1, '#ff0022');
    ctx.fillStyle = g;
    ctx.fillRect(i * step, h - barH, step - 1, barH);
  });
  ctx.fillStyle = 'rgba(0,247,255,0.6)';
  ctx.font = '10px monospace';
  ctx.fillText('SDR SPECTRUM — RTL→Lime pack ready', 8, 14);
}

function drawWaterfall(data) {
  const c = document.getElementById('waterfall-canvas');
  if (!c || !data?.spectrum) return;
  const ctx = c.getContext('2d');
  const w = c.width = c.offsetWidth;
  const h = c.height = c.offsetHeight || 120;
  const img = ctx.getImageData(0, 0, w, h - 1);
  ctx.putImageData(img, 0, 1);
  const spec = data.spectrum;
  const step = w / spec.length;
  for (let i = 0; i < spec.length; i++) {
    const norm = (spec[i] + 100) / 80;
    const r = Math.floor(norm * 255);
    const g = Math.floor(norm * 180);
    const b = Math.floor((1 - norm) * 255);
    ctx.fillStyle = `rgb(${r},${g},${b})`;
    ctx.fillRect(i * step, 0, step, 1);
  }
}

function addSignalLine(sig) {
  const feed = document.getElementById('signals-feed');
  if (!feed || !sig) return;
  const d = document.createElement('div');
  d.className = 'sig-line ' + (sig.severity || 'cyan');
  d.textContent = `[${(sig.band || '').toUpperCase()}] ${sig.text}`;
  feed.insertBefore(d, feed.firstChild);
  while (feed.children.length > 40) feed.removeChild(feed.lastChild);
}

function updateState(st) {
  if (!st) return;
  scanning = st.scanning;
  document.getElementById('scan-status').textContent = st.scanning ? 'SCANNING' : 'STANDBY';
  if (st.profit_today != null) {
    document.getElementById('profit-today').textContent = '$' + Math.floor(st.profit_today).toLocaleString();
  }
  drawSpectrum(st);
  drawWaterfall(st);
  (st.signals || []).slice(0, 3).forEach(s => {}); // bulk refresh on poll only first load
  const anom = document.getElementById('anomaly-list');
  if (anom) {
    anom.innerHTML = (st.anomalies || []).map(a =>
      `<div class="sig-line red">${a.text}</div>`).join('') ||
      '<div class="sig-line" style="color:#666">No interference detected</div>';
  }
  const dead = document.getElementById('deadspot-list');
  if (dead) {
    dead.innerHTML = (st.dead_spots || []).map(d =>
      `<div class="sig-line gold">${d.text}</div>`).join('') ||
      '<div class="sig-line" style="color:#666">Spectrum clear</div>';
  }
  const hw = document.getElementById('hardware-pack');
  if (hw && st.hardware_pack) {
    hw.innerHTML = Object.entries(st.hardware_pack).map(([k, v]) => {
      const cls = v.status === 'planned' ? 'hw-plan' : v.status === 'simulated' ? 'hw-sim' : 'hw-ok';
      return `<div><span class="${cls}">●</span> ${v.label} <em>(${v.status})</em></div>`;
    }).join('');
  }
}

async function pollSignals() {
  const st = await api('/signals');
  updateState(st);
}

async function toggleScan() {
  if (scanning) {
    await api('/signals/stop', { method: 'POST' });
  } else {
    await api('/signals/start', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ mode }) });
  }
  pollSignals();
}

async function askDarkMind() {
  const input = document.getElementById('dm-input');
  const log = document.getElementById('dm-log');
  const q = input.value.trim();
  if (!q) return;
  log.innerHTML += `<div class="sig-line cyan">YOU> ${q}</div>`;
  input.value = '';
  const res = await api('/jarvis/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: q }),
  });
  const msg = res?.message || res?.response || '[DARKMIND offline — start HUD backend]';
  log.innerHTML += `<div class="sig-line gold">DARKMIND> ${msg}</div>`;
  log.scrollTop = log.scrollHeight;
}

function enterQuestVR() {
  document.body.classList.add('vr-mode');
  if (document.documentElement.requestFullscreen) {
    document.documentElement.requestFullscreen().catch(() => {});
  }
  addSignalLine({ band: 'vr', text: 'Quest VR mode — sideload this URL in Meta Browser for AR overlay', severity: 'gold' });
}

function initBands() {
  const el = document.getElementById('bands-list');
  const bands = [
    ['wifi','📡','WiFi 2.4/5GHz'],['ble','🦷','BLE'],['nfc','📱','NFC 13.56'],
    ['rfid','🏷️','RFID'],['emv','💳','EMV/POS'],['gsm','📶','GSM'],
    ['lte','📡','LTE'],['subghz','📻','SubGHz'],['sdr','🌊','SDR'],['adsb','✈️','ADS-B'],
  ];
  el.innerHTML = bands.map(([k, ic, lb]) =>
    `<div class="band-item" data-band="${k}"><span class="icon">${ic}</span> ${lb}</div>`
  ).join('');
}

function connectSocket() {
  if (typeof io === 'undefined') return;
  socket = io();
  socket.on('signals_update', st => {
    updateState(st);
    if (st.signals && st.signals[0]) addSignalLine(st.signals[0]);
  });
  socket.on('signal_event', sig => addSignalLine(sig));
}

window.addEventListener('load', () => {
  initBands();
  setMode(mode);
  connectSocket();
  pollSignals();
  setInterval(pollSignals, 2000);
  toggleScan();
});

document.addEventListener('keydown', e => {
  if (e.key === 'g') setMode('gaming');
  if (e.key === 'm') setMode('grind');
});