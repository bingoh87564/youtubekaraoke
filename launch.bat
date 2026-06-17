@echo off
setlocal
title Karaoke Maker
color 0B
cd /d "%~dp0"

REM ── Check setup has been run ───────────────────────────────────────────
if not exist "venv\Scripts\activate.bat" (
    echo.
    echo  Setup has not been completed yet.
    echo  Please double-click "setup.bat" first, then try again.
    echo.
    pause
    exit /b 1
)

REM ── Activate environment ──────────────────────────────────────────────
call venv\Scripts\activate.bat

echo.
echo  ============================================================
echo    Karaoke Maker is starting...
echo  ============================================================
echo.
echo  Your browser will open automatically in a few seconds.
echo.
echo  IMPORTANT: Keep this window open while using the app.
echo  To stop the app, close this window.
echo.

REM ── Open Chrome (or fallback to default browser) after 3 s ────────────
start "" cmd /c "timeout /t 3 /nobreak >nul && (start \"\" \"C:\Program Files\Google\Chrome\Application\chrome.exe\" --new-window http://127.0.0.1:5000 2>nul || start \"\" \"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe\" --new-window http://127.0.0.1:5000 2>nul || start http://127.0.0.1:5000)"

REM ── Start the Flask server (runs until window is closed) ───────────────
python app.py

echo.
echo  Karaoke Maker has stopped.
pause
