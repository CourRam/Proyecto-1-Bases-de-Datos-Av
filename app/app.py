# app.py
from flask import Flask, render_template, redirect, url_for, flash, session, request
from config import Config
from database import init_app, get_db
import models
import auth
from routes import articles
from routes import comments
app = Flask(__name__)
app.config.from_object(Config)
init_app(app)

# Registrar blueprints
app.register_blueprint(auth.bp)
app.register_blueprint(articles.bp)
app.register_blueprint(comments.bp)

@app.route('/')
def index():
    """Página principal - muestra todos los artículos con filtros opcionales"""
    # Obtener parámetros de filtro de la URL
    category_url = request.args.get('category')
    tag_url = request.args.get('tag')
    search = request.args.get('search')
    
    print(f"Filtros aplicados - Categoría: {category_url}, Tag: {tag_url}, Búsqueda: {search}")  # Depuración
    
    # Obtener artículos filtrados
    articles = models.get_articles(
        category_url=category_url,
        tag_url=tag_url,
        search_term=search
    )
    
    categories = models.get_all_categories()
    tags = models.get_all_tags()
    
    return render_template('index.html', 
                         articles=articles, 
                         categories=categories, 
                         tags=tags,
                         selected_category=category_url,
                         selected_tag=tag_url,
                         search_term=search,
                         user_id=session.get('user_id'))

@app.route('/article/<path:url>')
def view_article(url):
    """Ver un artículo completo"""
    print(f"Buscando artículo con URL: {url}")  # Para depuración
    article_data = models.get_article_by_url(url)
    
    if not article_data or not article_data['article']:
        print("Artículo no encontrado")  # Para depuración
        flash('Artículo no encontrado', 'error')
        return redirect(url_for('index'))
    
    print(f"Artículo encontrado: {article_data['article']['TITLE']}")  # Para depuración
    return render_template('article.html', 
                         article=article_data['article'],
                         comments=article_data['comments'],
                         user_id=session.get('user_id'))

if __name__ == '__main__':
    app.run(debug=True)