# routes/__init__.py
"""
Paquete de rutas para la aplicación Blog
Exporta los blueprints para ser registrados en la aplicación principal
"""

from . import articles
from . import comments

# Lista de blueprints para facilitar el registro en app.py
blueprints = [
    articles.bp,
    comments.bp
]

__all__ = ['articles', 'comments', 'blueprints']