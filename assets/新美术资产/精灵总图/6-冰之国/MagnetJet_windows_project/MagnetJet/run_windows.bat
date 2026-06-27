@echo off
setlocal
cd /d "%~dp0"

where py >nul 2>nul
if errorlevel 1 (
  echo Python Launcher ^(py^) was not found. Install 64-bit Python 3.10, 3.11, or 3.12 first.
  pause
  exit /b 1
)

if not exist .venv\Scripts\python.exe (
  py -3.12 -m venv .venv 2>nul
  if errorlevel 1 py -3.11 -m venv .venv 2>nul
  if errorlevel 1 py -3.10 -m venv .venv
  if errorlevel 1 (
    echo Could not create a virtual environment. Use Python 3.10-3.12, 64-bit.
    pause
    exit /b 1
  )
  call .venv\Scripts\activate.bat
  python -m pip install --upgrade pip
  python -m pip install -r requirements.txt
  if errorlevel 1 (
    echo Dependency installation failed.
    pause
    exit /b 1
  )
)

.venv\Scripts\python.exe app.py
