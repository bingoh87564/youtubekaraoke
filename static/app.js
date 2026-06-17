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
    setTimeout(() => { showSuccess(data.filename, data.output_dir); loadLibrary(); }, 400);
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

// ── Enter key support + library init ─────────────────────────────────────

document.addEventListener('DOMContentLoaded', () => {
  const input = document.getElementById('url-input');
  if (input) {
    input.addEventListener('keydown', e => {
      if (e.key === 'Enter') startProcessing();
    });
    input.addEventListener('animationend', () => input.classList.remove('shake'));
  }
  loadLibrary();
});

// ── Library ───────────────────────────────────────────────────────────────

let currentFilename = null;

function loadLibrary() {
  const btn = document.querySelector('.btn-refresh');
  if (btn) btn.classList.add('spinning');

  fetch('/files')
    .then(r => r.json())
    .then(data => {
      renderLibrary(data.files || []);
    })
    .catch(() => {})
    .finally(() => {
      if (btn) btn.classList.remove('spinning');
    });
}

function renderLibrary(files) {
  const list  = document.getElementById('lib-list');
  const empty = document.getElementById('lib-empty');
  if (!list) return;

  list.innerHTML = '';

  if (files.length === 0) {
    if (empty) empty.hidden = false;
    return;
  }
  if (empty) empty.hidden = true;

  files.forEach(f => {
    const li = document.createElement('li');
    li.className = 'lib-item' + (f.filename === currentFilename ? ' playing' : '');
    li.dataset.filename = f.filename;
    li.innerHTML = `
      <button class="lib-play-btn ${f.filename === currentFilename ? 'playing' : 'paused'}"
              onclick="playTrack('${esc(f.filename)}', '${esc(f.display)}', this)"
              title="Play"></button>
      <span class="lib-name" title="${esc(f.display)}">${esc(f.display)}</span>
      <span class="lib-size">${f.size_mb} MB</span>
      <button class="lib-del" onclick="deleteTrack('${esc(f.filename)}', event)" title="Delete">&#128465;</button>
    `;
    list.appendChild(li);
  });
}

function playTrack(filename, displayName, btn) {
  const player = document.getElementById('audio-player');
  const wrap   = document.getElementById('player-wrap');
  const title  = document.getElementById('player-title');
  if (!player || !wrap || !title) return;

  // If clicking the currently playing track, toggle pause/play
  if (filename === currentFilename) {
    if (player.paused) {
      player.play();
      btn.classList.replace('paused', 'playing');
    } else {
      player.pause();
      btn.classList.replace('playing', 'paused');
    }
    return;
  }

  // Reset previous playing state
  document.querySelectorAll('.lib-item.playing').forEach(el => el.classList.remove('playing'));
  document.querySelectorAll('.lib-play-btn.playing').forEach(el => {
    el.classList.replace('playing', 'paused');
  });

  currentFilename = filename;
  player.src      = '/audio/' + encodeURIComponent(filename);
  title.textContent = displayName;
  wrap.hidden       = false;

  // Highlight the row
  const row = document.querySelector(`.lib-item[data-filename="${CSS.escape(filename)}"]`);
  if (row) row.classList.add('playing');
  btn.classList.replace('paused', 'playing');

  player.play().catch(() => {});

  // When track ends, reset the play button
  player.onended = () => {
    btn.classList.replace('playing', 'paused');
    if (row) row.classList.remove('playing');
    currentFilename = null;
  };
}

function deleteTrack(filename, e) {
  e.stopPropagation();
  if (!confirm(`Delete "${filename}"?\n\nThis cannot be undone.`)) return;

  // Stop player if this track is playing
  if (filename === currentFilename) {
    const player = document.getElementById('audio-player');
    if (player) { player.pause(); player.src = ''; }
    const wrap = document.getElementById('player-wrap');
    if (wrap) wrap.hidden = true;
    currentFilename = null;
  }

  fetch('/delete/' + encodeURIComponent(filename), { method: 'DELETE' })
    .then(r => r.json())
    .then(() => loadLibrary())
    .catch(() => alert('Could not delete the file. Please try again.'));
}

// Escape HTML special chars for use inside attributes / text
function esc(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
