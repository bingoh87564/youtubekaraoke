@echo off
setlocal enabledelayedexpansion
title Karaoke Maker — Setup
color 0A
cd /d "%~dp0"

echo.
echo  ============================================================
echo    Karaoke Maker — Setup
echo  ============================================================
echo.
echo  This sets up everything automatically.
echo  No installation or admin rights required.
echo.
echo  Please leave this window open until you see "All done!"
echo  It may take 10-20 minutes on a slow connection.
echo.
pause

REM ── Decide which Python to use ────────────────────────────────────────
set PYTHON_EXE=

REM Option 1: Embedded Python already downloaded in this folder
if exist "python\python.exe" (
    set PYTHON_EXE=%~dp0python\python.exe
    echo  Using existing portable Python.
    goto :got_python
)

REM Option 2: System Python is installed
python --version >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  Found system %%v
    set PYTHON_EXE=python
    goto :got_python
)

REM Option 3: Download portable (embedded) Python — no installation needed
echo  [Step 1]  Python not found. Downloading a portable version...
echo  (This is a zip file — no installation or admin rights needed.)
echo.

set PY_URL=https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip
set PY_ZIP=py_embed.zip

REM Try PowerShell first
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%PY_URL%' -OutFile '%PY_ZIP%'" >nul 2>&1
if not exist "%PY_ZIP%" (
    REM Fallback: bitsadmin (available on all Windows without extra tools)
    bitsadmin /transfer "Downloading Python" "%PY_URL%" "%CD%\%PY_ZIP%" >nul 2>&1
)

if not exist "%PY_ZIP%" (
    echo  ERROR: Could not download Python. Please check your internet connection.
    pause
    exit /b 1
)

echo  Extracting portable Python...
powershell -NoProfile -Command "Expand-Archive -Path '%PY_ZIP%' -DestinationPath 'python' -Force"
del /q "%PY_ZIP%" 2>nul

if not exist "python\python.exe" (
    echo  ERROR: Could not extract Python. Please try again.
    pause
    exit /b 1
)

REM Enable pip and site-packages for embedded Python
echo  Configuring portable Python...
powershell -NoProfile -Command ^
  "$pth = Get-ChildItem 'python' -Filter '*._pth' | Select-Object -First 1;" ^
  "if ($pth) { (Get-Content $pth.FullName) -replace '#import site','import site' | Set-Content $pth.FullName }"

REM Download and install pip
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'get-pip.py'" >nul 2>&1
if not exist "get-pip.py" (
    bitsadmin /transfer "Downloading pip" "https://bootstrap.pypa.io/get-pip.py" "%CD%\get-pip.py" >nul 2>&1
)
python\python.exe get-pip.py --no-warn-script-location --quiet
del /q get-pip.py 2>nul

set PYTHON_EXE=%~dp0python\python.exe
echo  Portable Python is ready!

:got_python
echo.
echo  Using Python: %PYTHON_EXE%
echo.

REM ── Upgrade pip ───────────────────────────────────────────────────────
echo  [Step 2]  Updating installer tools...
"%PYTHON_EXE%" -m pip install --upgrade pip --quiet
echo  Done.

REM ── Remove torchcodec if it was previously installed ──────────────────
"%PYTHON_EXE%" -m pip uninstall torchcodec demucs torch torchaudio -y >nul 2>&1

REM ── Install packages ──────────────────────────────────────────────────
echo.
echo  [Step 3]  Installing app components...
echo  (Downloading ~300 MB of AI tools — please wait, this takes a few minutes)
echo.
"%PYTHON_EXE%" -m pip install flask yt-dlp "audio-separator[onnx]" imageio-ffmpeg soundfile --quiet
if errorlevel 1 (
    echo.
    echo  ERROR: Could not install components. Check your internet connection and retry.
    pause
    exit /b 1
)
echo  Done.

REM ── Download ffmpeg + ffprobe ─────────────────────────────────────────
echo.
echo  [Step 4]  Downloading audio tools (ffmpeg)...
if exist "ffmpeg\ffmpeg.exe" (
    echo  Already downloaded, skipping.
) else (
    "%PYTHON_EXE%" -c "import urllib.request,zipfile,shutil,pathlib; p=pathlib.Path('ffmpeg'); p.mkdir(exist_ok=True); print('  Downloading...'); urllib.request.urlretrieve('https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip','ff.zip'); z=zipfile.ZipFile('ff.zip'); [z.extract(m,'fftmp') for m in z.namelist() if m.endswith('.exe')]; [shutil.copy(str(e),str(p/e.name)) for e in pathlib.Path('fftmp').rglob('*.exe')]; shutil.rmtree('fftmp'); pathlib.Path('ff.zip').unlink(); print('  Done.')"
)

REM ── Create desktop shortcut ───────────────────────────────────────────
echo.
echo  [Step 5]  Creating desktop shortcut...
set "VBS=%~dp0KaraokeMaker.vbs"
powershell -NoProfile -Command ^
  "$s=(New-Object -COM WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\Karaoke Maker.lnk');" ^
  "$s.TargetPath='wscript.exe';" ^
  "$s.Arguments='\"%VBS%\"';" ^
  "$s.Description='Open Karaoke Maker';" ^
  "$s.WorkingDirectory='%~dp0';" ^
  "$s.Save()"
if exist "%USERPROFILE%\Desktop\Karaoke Maker.lnk" (
    echo  Shortcut created on your Desktop!
) else (
    echo  Could not auto-create shortcut.
    echo  Right-click KaraokeMaker.vbs and choose "Send to Desktop" manually.
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
echo    2. The app opens in your browser automatically.
echo    3. Bookmark  http://127.0.0.1:5000  in your browser.
echo.
pause
