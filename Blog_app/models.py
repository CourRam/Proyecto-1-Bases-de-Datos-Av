# models.py (versión corregida)
import oracledb  # <--- IMPORTANTE: agregar esta importación
from database import execute_procedure, execute_function, fetch_all, get_db
from flask import current_app
import traceback

# ====================================================
# MODELOS DE USUARIOS
# ====================================================

def register_user(name, email, password):
    """
    Registrar un nuevo usuario
    
    Args:
        name: Nombre del usuario
        email: Email del usuario
        password: Contraseña
    
    Returns:
        dict: {'success': 0/1, 'message': '...', 'user_id': id (si success=1)}
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        # Crear variables para los parámetros OUT
        user_id_var = cursor.var(int)
        success_var = cursor.var(int)
        message_var = cursor.var(str)
        
        # Llamar al procedimiento
        cursor.callproc(
            'register_user',
            [name, email, password, user_id_var, success_var, message_var]
        )
        
        db.commit()
        
        return {
            'success': success_var.getvalue(),
            'message': message_var.getvalue(),
            'user_id': user_id_var.getvalue() if success_var.getvalue() == 1 else None
        }
    except Exception as e:
        current_app.logger.error(f"Error en register_user: {str(e)}")
        current_app.logger.error(traceback.format_exc())
        return {'success': 0, 'message': str(e), 'user_id': None}

def login_user(email, password):
    """
    Iniciar sesión usando callfunc con el nombre corregido loginUser
    
    Args:
        email: Email del usuario
        password: Contraseña
    
    Returns:
        int: user_id si éxito, -1 si credenciales incorrectas, -2 si error
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        # callfunc con el nuevo nombre de función
        result = cursor.callfunc(
            "loginUser",            # Nombre de la función (sin guión bajo)
            int,                    # Tipo de retorno (NUMBER en Oracle = int en Python)
            [email, password]       # Parámetros en el mismo orden que en Oracle
        )
        
        return result
        
    except Exception as e:
        current_app.logger.error(f"Error en login_user: {str(e)}")
        import traceback
        current_app.logger.error(traceback.format_exc())
        return -2
# ====================================================
# MODELOS DE CATEGORÍAS
# ====================================================

def get_all_categories():
    """Obtener todas las categorías"""
    try:
        return fetch_all('get_all_categories')
    except Exception as e:
        current_app.logger.error(f"Error en get_all_categories: {str(e)}")
        return []

def create_category(name, description=None):
    """
    Crear una nueva categoría
    
    Args:
        name: Nombre de la categoría
        description: Descripción (opcional)
    
    Returns:
        dict: {'success': 0/1, 'message': '...', 'category_id': id, 'url': '...'}
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        category_id_var = cursor.var(int)
        success_var = cursor.var(int)
        message_var = cursor.var(str)
        
        cursor.callproc(
            'create_category',
            [name, description, category_id_var, success_var, message_var]
        )
        
        db.commit()
        
        return {
            'success': success_var.getvalue(),
            'message': message_var.getvalue(),
            'category_id': category_id_var.getvalue() if success_var.getvalue() == 1 else None
        }
    except Exception as e:
        current_app.logger.error(f"Error en create_category: {str(e)}")
        return {'success': 0, 'message': str(e), 'category_id': None}

# ====================================================
# MODELOS DE TAGS
# ====================================================

def get_all_tags():
    """Obtener todos los tags"""
    try:
        return fetch_all('get_all_tags')
    except Exception as e:
        current_app.logger.error(f"Error en get_all_tags: {str(e)}")
        return []

def create_tag(name):
    """
    Crear un nuevo tag
    
    Args:
        name: Nombre del tag
    
    Returns:
        dict: {'success': 0/1, 'message': '...', 'tag_id': id}
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        tag_id_var = cursor.var(int)
        success_var = cursor.var(int)
        message_var = cursor.var(str)
        
        cursor.callproc(
            'create_tag',
            [name, tag_id_var, success_var, message_var]
        )
        
        db.commit()
        
        return {
            'success': success_var.getvalue(),
            'message': message_var.getvalue(),
            'tag_id': tag_id_var.getvalue() if success_var.getvalue() == 1 else None
        }
    except Exception as e:
        current_app.logger.error(f"Error en create_tag: {str(e)}")
        return {'success': 0, 'message': str(e), 'tag_id': None}

# ====================================================
# MODELOS DE ARTÍCULOS
# ====================================================

def create_article(user_id, category_id, title, text, tag_ids=None):
    """
    Crear un nuevo artículo
    
    Args:
        user_id: ID del autor
        category_id: ID de la categoría
        title: Título del artículo
        text: Contenido del artículo
        tag_ids: String con IDs de tags separados por comas (ej: '1,3,5')
    
    Returns:
        dict: {'success': 0/1, 'message': '...', 'article_id': id}
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        article_id_var = cursor.var(int)
        success_var = cursor.var(int)
        message_var = cursor.var(str)
        
        cursor.callproc(
            'create_article',
            [user_id, category_id, title, text, tag_ids, article_id_var, success_var, message_var]
        )
        
        db.commit()
        
        return {
            'success': success_var.getvalue(),
            'message': message_var.getvalue(),
            'article_id': article_id_var.getvalue() if success_var.getvalue() == 1 else None
        }
    except Exception as e:
        current_app.logger.error(f"Error en create_article: {str(e)}")
        return {'success': 0, 'message': str(e), 'article_id': None}

def update_article(article_id, user_id, category_id, title, text, tag_ids=None):
    """
    Actualizar un artículo existente
    
    Args:
        article_id: ID del artículo a actualizar
        user_id: ID del usuario (para verificar propiedad)
        category_id: Nueva categoría
        title: Nuevo título
        text: Nuevo contenido
        tag_ids: Nuevos tags
    
    Returns:
        dict: {'success': 0/1, 'message': '...'}
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        success_var = cursor.var(int)
        message_var = cursor.var(str)
        
        cursor.callproc(
            'update_article',
            [article_id, user_id, category_id, title, text, tag_ids, success_var, message_var]
        )
        
        db.commit()
        
        return {
            'success': success_var.getvalue(),
            'message': message_var.getvalue()
        }
    except Exception as e:
        current_app.logger.error(f"Error en update_article: {str(e)}")
        return {'success': 0, 'message': str(e)}

def delete_article(article_id, user_id):
    """
    Eliminar un artículo
    
    Args:
        article_id: ID del artículo a eliminar
        user_id: ID del usuario (para verificar propiedad)
    
    Returns:
        dict: {'success': 0/1, 'message': '...'}
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        success_var = cursor.var(int)
        message_var = cursor.var(str)
        
        cursor.callproc(
            'delete_article',
            [article_id, user_id, success_var, message_var]
        )
        
        db.commit()
        
        return {
            'success': success_var.getvalue(),
            'message': message_var.getvalue()
        }
    except Exception as e:
        current_app.logger.error(f"Error en delete_article: {str(e)}")
        return {'success': 0, 'message': str(e)}

def get_articles(category_url=None, tag_url=None, search_term=None, user_id=None):
    """
    Obtener artículos con filtros
    
    Returns:
        list: Lista de artículos
    """
    try:
        return fetch_all(
            'get_articles',
            {
                'p_category_url': category_url,
                'p_tag_url': tag_url,
                'p_search_term': search_term,
                'p_user_id': user_id
            }
        )
    except Exception as e:
        current_app.logger.error(f"Error en get_articles: {str(e)}")
        return []

def get_article_by_url(url):
    """
    Obtener un artículo por su URL (incluye comentarios)
    
    Returns:
        dict: {'article': {...}, 'comments': [...]} o None si no existe
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        # Crear variables para los cursores
        article_cursor = cursor.var(oracledb.DB_TYPE_CURSOR)
        comments_cursor = cursor.var(oracledb.DB_TYPE_CURSOR)
        
        # Llamar al procedimiento
        cursor.callproc(
            'get_article_details',
            [url, article_cursor, comments_cursor]
        )
        
        # Obtener resultados del artículo
        article_result = article_cursor.getvalue()
        article_data = None
        if article_result:
            columns = [col[0] for col in article_result.description]
            row = article_result.fetchone()
            if row:
                article_data = dict(zip(columns, row))
                print(f"Artículo recuperado: {article_data}")  # Depuración
        
        # Obtener comentarios
        comments_result = comments_cursor.getvalue()
        comments_data = []
        if comments_result:
            columns = [col[0] for col in comments_result.description]
            rows = comments_result.fetchall()
            comments_data = [dict(zip(columns, row)) for row in rows]
        
        if not article_data:
            print(f"No se encontró artículo con URL: {url}")  # Depuración
            return None
            
        return {
            'article': article_data,
            'comments': comments_data
        }
    except Exception as e:
        current_app.logger.error(f"Error en get_article_by_url: {str(e)}")
        current_app.logger.error(traceback.format_exc())
        return None

def get_user_articles(user_id):
    """
    Obtener artículos de un usuario específico
    
    Args:
        user_id: ID del usuario
    
    Returns:
        list: Lista de artículos del usuario
    """
    try:
        return fetch_all('get_user_articles', {'p_user_id': user_id})
    except Exception as e:
        current_app.logger.error(f"Error en get_user_articles: {str(e)}")
        return []

# ====================================================
# MODELOS DE COMENTARIOS
# ====================================================

def add_comment(user_id, article_id, text):
    """
    Agregar un comentario a un artículo
    
    Args:
        user_id: ID del autor del comentario
        article_id: ID del artículo
        text: Contenido del comentario
    
    Returns:
        dict: {'success': 0/1, 'message': '...', 'comment_id': id}
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        comment_id_var = cursor.var(int)
        success_var = cursor.var(int)
        message_var = cursor.var(str)
        
        cursor.callproc(
            'add_comment',
            [user_id, article_id, text, comment_id_var, success_var, message_var]
        )
        
        db.commit()
        
        return {
            'success': success_var.getvalue(),
            'message': message_var.getvalue(),
            'comment_id': comment_id_var.getvalue() if success_var.getvalue() == 1 else None
        }
    except Exception as e:
        current_app.logger.error(f"Error en add_comment: {str(e)}")
        return {'success': 0, 'message': str(e), 'comment_id': None}

def update_comment(comment_id, user_id, text):
    """
    Actualizar un comentario
    
    Args:
        comment_id: ID del comentario
        user_id: ID del usuario (para verificar propiedad)
        text: Nuevo texto
    
    Returns:
        dict: {'success': 0/1, 'message': '...'}
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        success_var = cursor.var(int)
        message_var = cursor.var(str)
        
        cursor.callproc(
            'update_comment',
            [comment_id, user_id, text, success_var, message_var]
        )
        
        db.commit()
        
        return {
            'success': success_var.getvalue(),
            'message': message_var.getvalue()
        }
    except Exception as e:
        current_app.logger.error(f"Error en update_comment: {str(e)}")
        return {'success': 0, 'message': str(e)}

def delete_comment(comment_id, user_id):
    """
    Eliminar un comentario
    
    Args:
        comment_id: ID del comentario
        user_id: ID del usuario (para verificar propiedad)
    
    Returns:
        dict: {'success': 0/1, 'message': '...'}
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        success_var = cursor.var(int)
        message_var = cursor.var(str)
        
        cursor.callproc(
            'delete_comment',
            [comment_id, user_id, success_var, message_var]
        )
        
        db.commit()
        
        return {
            'success': success_var.getvalue(),
            'message': message_var.getvalue()
        }
    except Exception as e:
        current_app.logger.error(f"Error en delete_comment: {str(e)}")
        return {'success': 0, 'message': str(e)}

def get_user_comments(user_id):
    """
    Obtener comentarios de un usuario específico
    
    Args:
        user_id: ID del usuario
    
    Returns:
        list: Lista de comentarios del usuario
    """
    try:
        return fetch_all('get_user_comments', {'p_user_id': user_id})
    except Exception as e:
        current_app.logger.error(f"Error en get_user_comments: {str(e)}")
        return []
    
# Agrega esta función temporal para depurar
def debug_articles():
    """Función de depuración para ver qué artículos hay"""
    try:
        articles = get_articles()
        print("=" * 50)
        print("ARTÍCULOS EN BASE DE DATOS:")
        for a in articles:
            print(f"ID: {a.get('ARTICLE_ID')}, Título: {a.get('TITLE')}, URL: {a.get('URL')}")
        print("=" * 50)
        return articles
    except Exception as e:
        print(f"Error en depuración: {e}")
        return []
    
def get_article_by_id(article_id):
    """
    Obtener un artículo por su ID
    
    Args:
        article_id: ID del artículo
    
    Returns:
        dict: Artículo o None si no existe
    """
    try:
        db = get_db()
        cursor = db.cursor()
        
        cursor.execute("""
            SELECT a.article_id, a.title, a.url, a.text, a.created_date, 
                   a.views, a.user_id as author_id, a.category_id,
                   u.name as author, c.name as category, c.url as category_url
            FROM articles a
            JOIN users u ON a.user_id = u.user_id
            JOIN categories c ON a.category_id = c.category_id
            WHERE a.article_id = :1
        """, [article_id])
        
        columns = [col[0] for col in cursor.description]
        row = cursor.fetchone()
        
        if row:
            article = dict(zip(columns, row))
            
            # Obtener tags del artículo
            cursor.execute("""
                SELECT t.tag_id, t.name
                FROM tags t
                JOIN article_tags at ON t.tag_id = at.tag_id
                WHERE at.article_id = :1
            """, [article_id])
            
            tags = cursor.fetchall()
            article['TAGS'] = [{'ID': t[0], 'NAME': t[1]} for t in tags]
            article['TAG_IDS'] = ','.join([str(t[0]) for t in tags])
            
            return article
        else:
            return None
            
    except Exception as e:
        current_app.logger.error(f"Error en get_article_by_id: {str(e)}")
        current_app.logger.error(traceback.format_exc())
        return None