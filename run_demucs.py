"""
Demucs launcher that patches torchaudio to use soundfile instead of
torchcodec, which fails to load its DLL on many Windows systems.
Auto-installs soundfile if it isn't present yet.
"""
import sys
import subprocess

# ── Auto-install soundfile if missing ─────────────────────────────────────
try:
    import soundfile as sf
except ImportError:
    subprocess.run(
        [sys.executable, "-m", "pip", "install", "soundfile", "-q"],
        check=True,
    )
    import soundfile as sf

import numpy as np

# ── Build a soundfile-based replacement for torchaudio.save ───────────────
def _sf_save(uri, src, sample_rate, channels_first=True, **kwargs):
    arr = src.detach().cpu().numpy()
    if channels_first and arr.ndim == 2:
        arr = arr.T                    # (C, T) → (T, C) for soundfile
    subtype = "FLOAT" if arr.dtype == np.float32 else "PCM_16"
    sf.write(str(uri), arr, int(sample_rate), subtype=subtype)

# ── Patch torchaudio before demucs imports it ──────────────────────────────
import torchaudio

torchaudio.save = _sf_save

# Also patch the internal _torchcodec dispatcher that calls save_with_torchcodec
try:
    import torchaudio._torchcodec as _tc
    _tc.save_with_torchcodec = lambda uri, src, sample_rate, **kw: _sf_save(
        uri, src, sample_rate
    )
except Exception:
    pass

# Patch any backend dispatcher that might route to torchcodec
try:
    import torchaudio.backend.common as _tbc
    if hasattr(_tbc, "AudioMetaData"):
        pass  # module loaded fine, patching not needed here
except Exception:
    pass

# ── Run demucs with the patched torchaudio in place ───────────────────────
import runpy
try:
    runpy.run_module("demucs", run_name="__main__", alter_sys=True)
except SystemExit as exc:
    sys.exit(exc.code)
