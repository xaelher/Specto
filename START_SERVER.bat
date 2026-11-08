@echo off
chcp 65001 >nul
title Specto Server (Public / Local)

cd /d "%~dp0\backend"

if not exist ".env" type nul > .env

echo ⏳ Подготовка окружения Specto...

if not exist ".venv" (
    echo 📦 Создание виртуального окружения .venv...
    python -m venv .venv
)

call .venv\Scripts\activate.bat

python -c "import django, rest_framework, corsheaders, pyngrok" 2>nul
if errorlevel 1 (
    echo 📥 Установка зависимостей...
    pip install -q --disable-pip-version-check -r requirements-mobile.txt
)

echo 🔄 Проверка базы данных...
python manage.py migrate --noinput

python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@specto.local', 'admin123')"

:: Проверяем наличие NGROK_AUTHTOKEN в .env
findstr /R /C:"^[ ]*NGROK_AUTHTOKEN=[^ ]" .env >nul 2>&1
if not errorlevel 1 (
    echo 🌐 Обнаружен сохранённый токен Ngrok. Запуск интернет-сервера...
    python run_public_server.py
    goto :end
)

echo.
echo ==================================================================
echo  🌐 ВЫБЕРИТЕ РЕЖИМ РАБОТЫ СЕРВЕРА SPECTO:
echo ==================================================================
echo  [1] Постоянный интернет-адрес через Ngrok (Рекомендуется)
echo      • Доступен из любой точки мира через 4G/5G и любой Wi-Fi
echo      • Бесплатный токен и домен на https://dashboard.ngrok.com
echo      • Настраивается 1 раз — дальше сервер всегда на этом адресе
echo.
echo  [2] Быстрый интернет-туннель Pinggy (Без регистрации)
echo      • Работает везде через SSH
echo.
echo  [3] Только локальная сеть (без интернета)
echo      • Только для устройств в одной домашней сети Wi-Fi
echo ==================================================================
set /p MODE="Введите номер режима (1, 2 или 3) [1]: "
if "%MODE%"=="" set MODE=1

if "%MODE%"=="1" (
    echo.
    echo 🔑 Настройка постоянного интернет-доступа (Ngrok):
    echo 1. Откройте https://dashboard.ngrok.com (бесплатно)
    echo 2. Скопируйте Authtoken из раздела 'Your Authtoken'
    set /p USER_TOKEN="Вставьте ваш NGROK_AUTHTOKEN: "
    echo.
    echo 3. В разделе 'Domains' нажмите 'New Domain' и скопируйте его
    set /p USER_DOMAIN="Вставьте ваш NGROK_DOMAIN (или Enter для случайного адреса): "
    
    if not "%USER_TOKEN%"=="" (
        echo. >> .env
        echo NGROK_AUTHTOKEN=%USER_TOKEN%>> .env
        if not "%USER_DOMAIN%"=="" (
            echo NGROK_DOMAIN=%USER_DOMAIN%>> .env
        )
        echo ✅ Настройки сохранены в backend/.env! Запуск интернет-сервера...
        python run_public_server.py
        goto :end
    )
)

if "%MODE%"=="2" (
    echo 🚀 Запуск быстрого интернет-туннеля Pinggy...
    start /b python manage.py runserver 0.0.0.0:8000 --noreload
    timeout /t 2 /nobreak >nul
    ssh -p 443 -R0:127.0.0.1:8000 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 a.pinggy.io
    goto :end
)

:: Режим 3: локальная сеть
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | Select-Object -ExpandProperty IPAddress -First 1)"`) do set "LOCAL_IP=%%i"
if "%LOCAL_IP%"=="" set "LOCAL_IP=127.0.0.1"

echo.
echo ==================================================================
echo  🚀 SPECTO ЛОКАЛЬНЫЙ СЕРВЕР ЗАПУЩЕН!
echo ==================================================================
echo  📱 На ЭТОМ компьютере в браузере: 127.0.0.1:8000
echo  📲 На ТЕЛЕФОНЕ (в том же Wi-Fi): %LOCAL_IP%:8000
echo  🔑 Логин: admin  ^|  Пароль: admin123
echo ==================================================================
echo  (Нажмите Ctrl+C для остановки)
echo.

python manage.py runserver 0.0.0.0:8000 --noreload

:end
pause
