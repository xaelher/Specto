# Specto Backend Setup Script
# Run this after Python is installed: powershell -ExecutionPolicy Bypass -File setup_backend.ps1

$ErrorActionPreference = "Stop"
$BackendDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Specto Backend Setup ===" -ForegroundColor Cyan

# 1. Create virtual environment
Write-Host "`n[1/6] Creating virtual environment..." -ForegroundColor Yellow
python -m venv "$BackendDir\.venv"
Write-Host "  -> .venv created" -ForegroundColor Green

# 2. Activate and install packages
Write-Host "`n[2/6] Installing packages from requirements.txt..." -ForegroundColor Yellow
& "$BackendDir\.venv\Scripts\pip.exe" install -r "$BackendDir\requirements.txt"
Write-Host "  -> Packages installed" -ForegroundColor Green

# 3. Initialize Django project
Write-Host "`n[3/6] Initializing Django project 'config'..." -ForegroundColor Yellow
Set-Location $BackendDir
& "$BackendDir\.venv\Scripts\django-admin.exe" startproject config .
Write-Host "  -> Django project 'config' created" -ForegroundColor Green

# 4. Create 'core' app
Write-Host "`n[4/6] Creating Django app 'core'..." -ForegroundColor Yellow
& "$BackendDir\.venv\Scripts\python.exe" manage.py startapp core
Write-Host "  -> App 'core' created" -ForegroundColor Green

Write-Host "`n[5/6] Applying migrations..." -ForegroundColor Yellow
Write-Host "  -> Skipped (run manually after settings.py and models.py are configured)" -ForegroundColor DarkYellow

Write-Host "`n=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. The settings.py, models.py and admin.py will be configured automatically" -ForegroundColor White
Write-Host "  2. Run: .\.venv\Scripts\python.exe manage.py makemigrations" -ForegroundColor White
Write-Host "  3. Run: .\.venv\Scripts\python.exe manage.py migrate" -ForegroundColor White
