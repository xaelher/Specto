#!/bin/bash
# =====================================================================
# Specto — Автономный запуск сервера на Android (Termux)
# Поддерживает глобальный интернет (Ngrok/Pinggy) и локальную сеть.
# =====================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/backend"

if [ ! -f ".env" ]; then
    touch .env
fi

echo "⏳ Подготовка окружения Specto..."

if command -v python3 &>/dev/null; then
    PY_CMD="python3"
elif command -v python &>/dev/null; then
    PY_CMD="python"
else
    echo "❌ Ошибка: Python не найден. Установите: pkg install python"
    exit 1
fi

if [ ! -d ".venv" ]; then
    echo "📦 Создание виртуального окружения .venv..."
    $PY_CMD -m venv .venv
fi

if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
fi

if ! python -c "import django, rest_framework, corsheaders, pyngrok" &>/dev/null; then
    echo "📥 Установка зависимостей из requirements-mobile.txt..."
    pip install -q --disable-pip-version-check -r requirements-mobile.txt
fi

echo "🔄 Применение миграций базы данных..."
python manage.py migrate --noinput

python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@specto.local', 'admin123')
    print('✅ Создан администратор: admin / admin123')
"

# Проверка токена ngrok в .env
NGROK_TOKEN=$(grep -E '^[[:space:]]*NGROK_AUTHTOKEN=' .env 2>/dev/null | cut -d '=' -f2- | tr -d ' "' || true)

if [ -n "$NGROK_TOKEN" ]; then
    echo "🌐 Запуск сервера с постоянным интернет-доступом (Ngrok)..."
    exec python run_public_server.py
fi

# Если токен не задан, предлагаем выбор режима
echo ""
echo "=================================================================="
echo " 🌐 ВЫБЕРИТЕ РЕЖИМ РАБОТЫ СЕРВЕРА SPECTO:"
echo "=================================================================="
echo " [1] Постоянный интернет-адрес через Ngrok (Рекомендуется)"
echo "     • Работает через 4G/5G и любые сети по всему миру"
echo "     • Бесплатный токен и вечный домен на https://dashboard.ngrok.com"
echo "     • Настраивается 1 раз — дальше сервер всегда на этом адресе"
echo ""
echo " [2] Быстрый интернет-туннель Pinggy (Без регистрации)"
echo "     • Работает везде через SSH-туннель в 1 клик"
echo ""
echo " [3] Только локальная сеть (без интернета)"
echo "     • Оба телефона должны быть в одной сети Wi-Fi"
echo "=================================================================="
read -p "Введите номер режима (1, 2 или 3) [1]: " MODE_CHOICE
MODE_CHOICE=${MODE_CHOICE:-1}

if [ "$MODE_CHOICE" = "1" ]; then
    echo ""
    echo "🔑 Настройка постоянного интернет-доступа (Ngrok):"
    echo "1. Зайдите на https://dashboard.ngrok.com (бесплатно)"
    echo "2. Скопируйте токен в разделе 'Your Authtoken'"
    read -p "Вставьте ваш NGROK_AUTHTOKEN: " USER_TOKEN
    echo ""
    echo "3. В разделе 'Domains' нажмите 'New Domain' и скопируйте его (например: my-specto.ngrok-free.app)"
    read -p "Вставьте ваш NGROK_DOMAIN (или Enter для случайного адреса): " USER_DOMAIN

    if [ -n "$USER_TOKEN" ]; then
        echo "" >> .env
        echo "NGROK_AUTHTOKEN=$USER_TOKEN" >> .env
        if [ -n "$USER_DOMAIN" ]; then
            echo "NGROK_DOMAIN=$USER_DOMAIN" >> .env
        fi
        echo "✅ Настройки сохранены в backend/.env! Запуск интернет-сервера..."
        exec python run_public_server.py
    else
        echo "⚠️ Токен не введён. Переключение в локальный режим..."
    fi
elif [ "$MODE_CHOICE" = "2" ]; then
    echo "🚀 Запуск быстрого интернет-туннеля Pinggy..."
    python manage.py runserver 0.0.0.0:8000 --noreload &
    SERVER_PID=$!
    trap "kill $SERVER_PID 2>/dev/null || true; exit 0" INT TERM EXIT
    sleep 2
    if command -v ssh &>/dev/null; then
        exec ssh -p 443 -R0:127.0.0.1:8000 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 a.pinggy.io
    else
        echo "⚠️ Утилита ssh не найдена. Установите: pkg install openssh"
    fi
fi

# Режим 3: локальный Wi-Fi
LOCAL_IP=""
if command -v ip &>/dev/null; then
    LOCAL_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}')
fi
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="127.0.0.1"
fi

echo ""
echo "=================================================================="
echo " 🚀 SPECTO ЛОКАЛЬНЫЙ СЕРВЕР ЗАПУЩЕН!"
echo "=================================================================="
echo " 📱 На ЭТОМ телефоне в приложении адрес: 127.0.0.1:8000"
echo " 📲 На ВТОРОМ телефоне (в том же Wi-Fi): $LOCAL_IP:8000"
echo " 🔑 Логин: admin  |  Пароль: admin123"
echo "=================================================================="
echo " (Нажмите Ctrl+C для остановки)"
echo ""

exec python manage.py runserver 0.0.0.0:8000 --noreload
