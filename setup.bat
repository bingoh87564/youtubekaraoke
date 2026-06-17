@echo off
setlocal enabledelayedexpansion
title Karaoke Maker — Setup
color 0A
cd /d "%~dp0"

echo.
echo  ============================================================
echo    Karaoke Maker — First-Time Setup
echo  ============================================================
echo.
echo  This window sets up everything automatically.
echo  Please leave it open until you see "All done!"
echo.
echo  It may take 10-20 minutes on a slow internet connection.
echo.
pause

REM ── Step 1: Check Python ──────────────────────────────────────────────
echo.
echo  [1 of 7]  Checking for Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo  Python is not installed.
    echo.
    echo  Please do the following:
    echo    1. Go to:  https://www.python.org/downloads/
    echo    2. Click the big Download button.
    echo    3. Run the downloaded file.
    echo    4. On the FIRST screen, tick "Add Python to PATH".
    echo    5. Click Install Now and wait for it to finish.
    echo    6. Then double-click setup.bat again.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  Found: %%v

REM ── Step 2: Create virtual environment ───────────────────────────────
echo.
echo  [2 of 7]  Creating app environment...
if exist venv (
    echo  Already exists, continuing.
) else (
    python -m venv venv
    if errorlevel 1 (
        echo  ERROR: Could not create environment. Check Python install and retry.
        pause
        exit /b 1
    )
)
call venv\Scripts\activate.bat

REM ── Step 3: Upgrade pip ───────────────────────────────────────────────
echo.
echo  [3 of 7]  Updating installer tools...
python -m pip install --upgrade pip --quiet
echo  Done.

REM ── Step 4: Install PyTorch (CPU) ─────────────────────────────────────
echo.
echo  [4 of 7]  Installing AI engine  (large download — please wait)...
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cpu
if errorlevel 1 (
    echo.
    echo  ERROR: Could not download AI components.
    echo  Check your internet connection and run setup again.
    pause
    exit /b 1
)
echo.

REM ── Remove torchcodec — its DLL does not load reliably on Windows ──────
echo  Removing incompatible audio component (torchcodec)...
pip uninstall torchcodec -y >nul 2>&1
echo  Done.

REM ── Step 5: Install remaining packages ───────────────────────────────
echo.
echo  [5 of 7]  Installing remaining components...
pip install flask yt-dlp "demucs>=4.0.1" imageio-ffmpeg "soundfile>=0.12.0"
if errorlevel 1 (
    echo.
    echo  ERROR: Could not install components. Check internet and retry.
    pause
    exit /b 1
)
echo  Done.

REM ── Step 6: Download ffmpeg + ffprobe ─────────────────────────────────
echo.
echo  [6 of 7]  Downloading audio tools (ffmpeg)...
if exist ffmpeg\ffmpeg.exe (
    echo  Already downloaded, skipping.
) else (
    python -c "import urllib.request,zipfile,shutil,pathlib; p=pathlib.Path('ffmpeg'); p.mkdir(exist_ok=True); print('  Downloading...'); urllib.request.urlretrieve('https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip','ff.zip'); print('  Extracting...'); z=zipfile.ZipFile('ff.zip'); [z.extract(m,'fftmp') for m in z.namelist() if m.endswith('.exe')]; [shutil.copy(str(e),str(p/e.name)) for e in pathlib.Path('fftmp').rglob('*.exe')]; shutil.rmtree('fftmp'); pathlib.Path('ff.zip').unlink(); print('  Done.')"
    if errorlevel 1 (
        echo  WARNING: Could not download ffmpeg. The app may not work correctly.
        echo  Please check your internet connection and run setup again.
    )
)

REM ── Step 7: Create desktop shortcut ──────────────────────────────────
echo.
echo  [7 of 7]  Creating your desktop shortcut...
set "VBS=%~dp0KaraokeMaker.vbs"
set "DESK=%USERPROFILE%\Desktop"
powershell -NoProfile -Command ^
  "$s=(New-Object -COM WScript.Shell).CreateShortcut('%DESK%\Karaoke Maker.lnk');" ^
  "$s.TargetPath='wscript.exe';" ^
  "$s.Arguments='\"%VBS%\"';" ^
  "$s.Description='Open Karaoke Maker';" ^
  "$s.WorkingDirectory='%~dp0';" ^
  "$s.Save()"
if exist "%DESK%\Karaoke Maker.lnk" (
    echo  Shortcut created on your Desktop!
) else (
    echo  Could not create shortcut automatically.
    echo  You can manually right-click KaraokeMaker.vbs and choose "Send to Desktop".
)

REM ── All done! ─────────────────────────────────────────────────────────
echo.
echo  ============================================================
echo    All done!
echo  ============================================================
echo.
echo  A "Karaoke Maker" shortcut has been placed on your Desktop.
echo.
echo  HOW TO USE:
echo    1. Double-click "Karaoke Maker" on your Desktop.
echo    2. The app will open in your browser automatically.
echo    3. Bookmark  http://localhost:5000  in your browser.
echo    4. Next time: double-click the Desktop icon, then use the bookmark.
echo.
echo  You never need to touch this folder again!
echo.
pause
