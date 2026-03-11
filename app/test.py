# test_login.py
from models import login_user
from database import init_app
from config import Config
from flask import Flask

app = Flask(__name__)
app.config.from_object(Config)
init_app(app)

with app.app_context():
    # Prueba con credenciales correctas
    result = login_user('test@email.com', 'password123')
    print(f"Login correcto: {result}")
    
    # Prueba con credenciales incorrectas
    result = login_user('test@email.com', 'wrongpass')
    print(f"Login incorrecto: {result}")