# routes/comments.py
from flask import Blueprint, render_template, request, redirect, url_for, flash, session
import models

bp = Blueprint('comments', __name__, url_prefix='/comments')

@bp.route('/add/<int:article_id>', methods=['POST'])
def add(article_id):
    """Agregar un comentario a un artículo"""
    if 'user_id' not in session:
        flash('Debes iniciar sesión para comentar', 'error')
        return redirect(url_for('auth.login'))
    
    text = request.form.get('text', '').strip()
    
    if not text:
        flash('El comentario no puede estar vacío', 'error')
        return redirect(request.referrer or url_for('index'))
    
    if len(text) > 2000:
        flash('El comentario es demasiado largo (máximo 2000 caracteres)', 'error')
        return redirect(request.referrer or url_for('index'))
    
    result = models.add_comment(
        user_id=session['user_id'],
        article_id=article_id,
        text=text
    )
    
    if result['success']:
        flash('Comentario agregado correctamente', 'success')
    else:
        flash(result['message'], 'error')
    
    return redirect(request.referrer or url_for('index'))

@bp.route('/edit/<int:comment_id>', methods=['POST'])
def edit(comment_id):
    """Editar un comentario"""
    if 'user_id' not in session:
        flash('Debes iniciar sesión', 'error')
        return redirect(url_for('auth.login'))
    
    text = request.form.get('text', '').strip()
    
    if not text:
        flash('El comentario no puede estar vacío', 'error')
        return redirect(request.referrer or url_for('index'))
    
    result = models.update_comment(
        comment_id=comment_id,
        user_id=session['user_id'],
        text=text
    )
    
    if result['success']:
        flash('Comentario actualizado', 'success')
    else:
        flash(result['message'], 'error')
    
    return redirect(request.referrer or url_for('index'))

@bp.route('/delete/<int:comment_id>', methods=['POST'])
def delete(comment_id):
    """Eliminar un comentario"""
    if 'user_id' not in session:
        flash('Debes iniciar sesión', 'error')
        return redirect(url_for('auth.login'))
    
    result = models.delete_comment(
        comment_id=comment_id,
        user_id=session['user_id']
    )
    
    if result['success']:
        flash('Comentario eliminado', 'success')
    else:
        flash(result['message'], 'error')
    
    return redirect(request.referrer or url_for('index'))