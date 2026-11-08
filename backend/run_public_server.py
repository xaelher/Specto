"""
Specto — Запуск Django сервера с публичным интернет-туннелем (ngrok).
Позволяет подключиться к серверу из любой точки мира через 4G/5G и сторонние Wi-Fi сети.
"""
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Загрузка переменных окружения
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / '.env')

token = os.getenv('NGROK_AUTHTOKEN', '').strip()
domain = os.getenv('NGROK_DOMAIN', '').strip()

public_url = None

if token:
    try:
        from pyngrok import ngrok
        ngrok.set_auth_token(token)
        
        connect_options = {'addr': '8000', 'proto': 'http'}
        if domain:
            connect_options['domain'] = domain
            
        tunnel = ngrok.connect(**connect_options)
        public_url = tunnel.public_url
        if public_url.startswith('http://'):
            public_url = public_url.replace('http://', 'https://')
    except Exception as e:
        print(f"⚠️ Предупреждение: Ошибка подключения ngrok: {e}")
        print("💡 Сервер продолжит работу в локальном режиме.")

print("")
print("=" * 68)
if public_url:
    clean_domain = public_url.replace('https://', '').replace('http://', '')
    print(" 🚀 SPECTO PUBLIC SERVER ЗАПУЩЕН!")
    print("=" * 68)
    print(" 🌍 СЕРВЕР ДОСТУПЕН В ИНТЕРНЕТЕ ПО АДРЕСУ:")
    print(f"    👉 {public_url}")
    print("")
    print(" 📱 На ЛЮБОМ телефоне (в 4G/5G или любом Wi-Fi) в приложении Specto:")
    print("    1. Нажмите иконку ⚙️ на экране входа")
    print(f"    2. Введите адрес: {clean_domain}")
    print("=" * 68)
    print(" 🔑 Логин администратора: admin  |  Пароль: admin123")
    print(f" 🌐 Админ-панель: {public_url}/admin/")
else:
    print(" 🚀 SPECTO ЛОКАЛЬНЫЙ СЕРВЕР ЗАПУЩЕН!")
    print("=" * 68)
    print(" 📱 На ЭТОМ устройстве адрес: 127.0.0.1:8000")
    print(" ℹ️ Чтобы включить доступ через интернет, укажите NGROK_AUTHTOKEN в .env")
print("=" * 68)
print(" (Нажмите Ctrl+C для остановки сервера)")
print("")

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

try:
    from django.core.management import execute_from_command_line
    execute_from_command_line([sys.argv[0], 'runserver', '0.0.0.0:8000', '--noreload'])
except KeyboardInterrupt:
    print("\n🛑 Остановка сервера...")
    if token:
        try:
            from pyngrok import ngrok
            ngrok.kill()
        except Exception:
            pass

