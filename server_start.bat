@echo off
cd /d "%~dp0"

REM Use embedded (portable) Python if present, otherwise fall back to venv
if exist "python\python.exe" (
    python\python.exe app.py >> karaoke.log 2>&1
) else (
    call venv\Scripts\activate.bat
    python app.py >> karaoke.log 2>&1
)
