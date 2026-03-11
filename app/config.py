import os
from dotenv import load_dotenv

# Cargar variables de entorno desde .env
load_dotenv()

class Config:
    # Configuración de Oracle
    ORACLE_USER = os.getenv('ORACLE_USER', 'system')
    ORACLE_PASSWORD = os.getenv('ORACLE_PASSWORD', 'oracle')
    ORACLE_DSN = os.getenv('ORACLE_DSN', 'localhost:1521/FREEPDB1')
    
    # Configuración de Flask
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-key-change-in-production')
    FLASK_ENV = os.getenv('FLASK_ENV', 'development')
    DEBUG = FLASK_ENV == 'development'
    
    # Configuración de la aplicación
    ARTICLES_PER_PAGE = 10
    MAX_COMMENT_LENGTH = 2000