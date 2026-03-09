# routes/articles.py
from flask import Blueprint, render_template, request, redirect, url_for, flash, session
import models

bp = Blueprint('articles', __name__, url_prefix='/articles')

@bp.route('/create', methods=['GET', 'POST'])
def create():
    """Crear un nuevo artículo"""
    if 'user_id' not in session:
        flash('Debes iniciar sesión para crear artículos', 'error')
        return redirect(url_for('auth.login'))
    
    if request.method == 'POST':
        title = request.form['title']
        category_id = request.form['category_id']
        text = request.form['text']
        # Obtener tags seleccionados del multiselect
        selected_tags = request.form.getlist('tag_ids')  # Cambiado de get a getlist
        tag_ids = ','.join(selected_tags) if selected_tags else None
        
        print(f"Creando artículo: {title}, categoría: {category_id}, tags: {tag_ids}")  # Depuración
        
        # Validaciones básicas
        if not title or len(title) < 5:
            flash('El título debe tener al menos 5 caracteres', 'error')
            return render_template('create_article.html', 
                                 categories=models.get_all_categories(),
                                 tags=models.get_all_tags())
        
        if not text or len(text) < 10:
            flash('El contenido debe tener al menos 10 caracteres', 'error')
            return render_template('create_article.html', 
                                 categories=models.get_all_categories(),
                                 tags=models.get_all_tags())
        
        # Crear artículo
        result = models.create_article(
            user_id=session['user_id'],
            category_id=category_id,
            title=title,
            text=text,
            tag_ids=tag_ids
        )
        
        print(f"Resultado creación: {result}")  # Depuración
        
        if result['success']:
            flash(result['message'], 'success')
            # Extraer la URL del mensaje
            if '/article/' in result['message']:
                url = result['message'].split('/article/')[-1]
                return redirect(url_for('view_article', url=url))
            else:
                return redirect(url_for('index'))
        else:
            flash(result['message'], 'error')
            return render_template('create_article.html', 
                                 categories=models.get_all_categories(),
                                 tags=models.get_all_tags())
    
    # GET request - mostrar formulario
    return render_template('create_article.html', 
                         categories=models.get_all_categories(),
                         tags=models.get_all_tags())

@bp.route('/<int:article_id>/edit', methods=['GET', 'POST'])
def edit(article_id):
    """Editar un artículo existente"""
    if 'user_id' not in session:
        flash('Debes iniciar sesión para editar artículos', 'error')
        return redirect(url_for('auth.login'))
    
    # Obtener el artículo primero para verificar propiedad
    # Necesitamos una función para obtener artículo por ID
    # Por ahora, usamos un método temporal
    articles = models.get_articles(user_id=session['user_id'])
    article = next((a for a in articles if a['ARTICLE_ID'] == article_id), None)
    
    if not article:
        flash('Artículo no encontrado', 'error')
        return redirect(url_for('index'))
    
    if request.method == 'POST':
        title = request.form['title']
        category_id = request.form['category_id']
        text = request.form['text']
        tag_ids = request.form.get('tag_ids', '')
        
        result = models.update_article(
            article_id=article_id,
            user_id=session['user_id'],
            category_id=category_id,
            title=title,
            text=text,
            tag_ids=tag_ids
        )
        
        if result['success']:
            flash(result['message'], 'success')
            return redirect(url_for('view_article', url=title))  # Simplificado, mejor usar URL real
        else:
            flash(result['message'], 'error')
    
    # GET request - mostrar formulario con datos actuales
    return render_template('edit_article.html', 
                         article=article,
                         categories=models.get_all_categories(),
                         tags=models.get_all_tags())

@bp.route('/<int:article_id>/delete', methods=['POST'])
def delete(article_id):
    """Eliminar un artículo"""
    if 'user_id' not in session:
        flash('Debes iniciar sesión', 'error')
        return redirect(url_for('auth.login'))
    
    result = models.delete_article(article_id, session['user_id'])
    
    if result['success']:
        flash('Artículo eliminado correctamente', 'success')
    else:
        flash(result['message'], 'error')
    
    return redirect(url_for('index'))