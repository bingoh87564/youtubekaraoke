'use strict';

let currentJobId  = null;
let pollTimer     = null;

// ── Helpers ───────────────────────────────────────────────────────────────

function show(id) {
  ['sec-input', 'sec-progress', 'sec-success', 'sec-error'].forEach(s => {
    const el = document.getElementById(s);
    if (el) el.hidden = (s !== id);
  });
}

function setBar(pct) {
  const fill  = document.getElementById('bar-fill');
  const label = document.getElementById('bar-label');
  if (fill)  fill.style.width = pct + '%';
  if (label) label.textContent = pct + '%';
}

// ── Start ─────────────────────────────────────────────────────────────────

function startProcessing() {
  const input = document.getElementById('url-input');
  const url   = (input ? input.value : '').trim();

  if (!url) {
    shakeInput();
    return;
  }

  const btn = document.getElementById('go-btn');
  if (btn) btn.disabled = true;

  show('sec-progress');
  setBar(5);
  document.getElementById('prog-msg').textContent = 'Getting started…';

  fetch('/process', {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify({ url }),
  })
    .then(r => r.json())
    .then(data => {
      if (data.error) { showError(data.error); return; }
      currentJobId = data.job_id;
      startPolling();
    })
    .catch(() => {
      showError(
        'Could not reach the app. Please make sure the Karaoke Maker ' +
        'window is still open and try again.'
      );
    });
}

// ── Polling ───────────────────────────────────────────────────────────────

function startPolling() {
  stopPolling();
  pollTimer = setInterval(poll, 2500);
}

function stopPolling() {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
}

function poll() {
  if (!currentJobId) return;
  fetch(`/status/${currentJobId}`)
    .then(r => r.json())
    .then(handleStatus)
    .catch(() => { /* network hiccup — keep trying */ });
}

function handleStatus(data) {
  const pct = Math.min(100, Math.max(0, data.progress || 0));
  setBar(pct);

  if (data.message) {
    document.getElementById('prog-msg').textContent = data.message;
  }

  if (data.status === 'complete') {
    stopPolling();
    setBar(100);
    setTimeout(() => showSuccess(data.filename, data.output_dir), 400);
  } else if (data.status === 'error') {
    stopPolling();
    showError(data.message || 'Something went wrong. Please try again.');
  }
}

// ── Success / Error ───────────────────────────────────────────────────────

function showSuccess(filename, folder) {
  document.getElementById('res-filename').textContent = filename  || '(unknown file)';
  document.getElementById('res-folder').textContent   = folder    || 'Karaoke Music';
  show('sec-success');
}

function showError(msg) {
  document.getElementById('err-msg').textContent = msg;
  show('sec-error');
  const btn = document.getElementById('go-btn');
  if (btn) btn.disabled = false;
}

// ── Reset ─────────────────────────────────────────────────────────────────

function resetApp() {
  stopPolling();
  currentJobId = null;
  const input = document.getElementById('url-input');
  if (input) input.value = '';
  const btn = document.getElementById('go-btn');
  if (btn) btn.disabled = false;
  setBar(0);
  show('sec-input');
}

// ── Open folder ───────────────────────────────────────────────────────────

function openFolder() {
  fetch('/open-folder').catch(() => {});
}

// ── Shake animation for empty input ──────────────────────────────────────

function shakeInput() {
  const el = document.getElementById('url-input');
  if (!el) return;
  el.classList.remove('shake');
  void el.offsetWidth;         // reflow to restart animation
  el.classList.add('shake');
  el.focus();
}

// ── Enter key support ─────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', () => {
  const input = document.getElementById('url-input');
  if (input) {
    input.addEventListener('keydown', e => {
      if (e.key === 'Enter') startProcessing();
    });
    input.addEventListener('animationend', () => input.classList.remove('shake'));
  }
});
