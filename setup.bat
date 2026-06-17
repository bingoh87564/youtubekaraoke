@echo off
setlocal enabledelayedexpansion
title Karaoke Maker — First-Time Setup
color 0A
cd /d "%~dp0"

echo.
echo  ============================================================
echo    Karaoke Maker — First-Time Setup
echo  ============================================================
echo.
echo  Welcome! This window will set up everything you need.
echo  It only needs to run ONCE and may take 10-20 minutes
echo  because it downloads the AI model and tools.
echo.
echo  Please DO NOT close this window until you see "Setup done!"
echo.
pause

REM ── Check Python ──────────────────────────────────────────────────────
echo.
echo  [Step 1 of 5]  Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ERROR: Python is not installed on this computer.
    echo.
    echo  Please follow these steps:
    echo    1. Open your web browser and go to: https://www.python.org/downloads/
    echo    2. Click the big yellow "Download Python" button.
    echo    3. Run the downloaded file.
    echo    4. IMPORTANT: Check the box "Add Python to PATH" before clicking Install.
    echo    5. After Python installs, come back and double-click setup.bat again.
    echo.
    pause
    exit /b 1
)
python --version
echo  Python found! Great.

REM ── Create virtual environment ────────────────────────────────────────
echo.
echo  [Step 2 of 5]  Creating an isolated environment for the app...
if exist venv (
    echo  Environment already exists, skipping creation.
) else (
    python -m venv venv
    if errorlevel 1 (
        echo.
        echo  ERROR: Could not create the environment.
        echo  Please make sure Python is installed correctly and try again.
        pause
        exit /b 1
    )
)
echo  Done.

REM ── Activate venv ─────────────────────────────────────────────────────
call venv\Scripts\activate.bat

REM ── Upgrade pip ───────────────────────────────────────────────────────
echo.
echo  [Step 3 of 5]  Updating package manager...
python -m pip install --upgrade pip --quiet
echo  Done.

REM ── Install PyTorch (CPU) first — it is large ─────────────────────────
echo.
echo  [Step 4 of 5]  Installing AI components (large download — please wait)...
echo  This step can take 5-15 minutes depending on your internet speed.
echo.
pip install "torch==2.3.0" "torchaudio==2.3.0" --index-url https://download.pytorch.org/whl/cpu
if errorlevel 1 (
    echo.
    echo  ERROR: Could not download the AI components.
    echo  Please check your internet connection and try again.
    pause
    exit /b 1
)
echo.
echo  AI components installed!

REM ── Install remaining requirements ────────────────────────────────────
echo.
echo  [Step 5 of 5]  Installing remaining components...
pip install -r requirements.txt
if errorlevel 1 (
    echo.
    echo  ERROR: Could not install all components.
    echo  Please check your internet connection and try again.
    pause
    exit /b 1
)

REM ── Download ffmpeg + ffprobe ─────────────────────────────────────────
echo.
echo  Downloading ffmpeg audio tools (required for audio processing)...
echo  This may take a minute...
echo.
python -c "import urllib.request, zipfile, shutil, pathlib; p=pathlib.Path('ffmpeg'); p.mkdir(exist_ok=True); urllib.request.urlretrieve('https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip','ff.zip'); z=zipfile.ZipFile('ff.zip'); [z.extract(m,'fftmp') for m in z.namelist() if m.endswith('.exe')]; [shutil.copy(str(e),str(p/e.name)) for e in pathlib.Path('fftmp').rglob('*.exe')]; shutil.rmtree('fftmp'); pathlib.Path('ff.zip').unlink(); print('ffmpeg ready!')"
if errorlevel 1 (
    echo  WARNING: Could not download ffmpeg automatically.
    echo  The app may not work. Check your internet connection and run setup again.
)

REM ── Pre-download the Demucs AI model ─────────────────────────────────
echo.
echo  Pre-downloading the AI vocal-removal model (~80 MB)...
echo  This avoids a delay the first time you use the app.
echo.
python -c "import demucs; print('Checking model...')" 2>nul
python -m demucs --help >nul 2>&1
echo.
echo  Model ready!

REM ── Done! ─────────────────────────────────────────────────────────────
echo.
echo  ============================================================
echo    Setup is complete!
echo  ============================================================
echo.
echo  You're all set! From now on, just double-click:
echo.
echo     launch.bat
echo.
echo  ...to open Karaoke Maker in your browser.
echo.
pause
