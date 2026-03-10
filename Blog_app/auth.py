
from flask import Blueprint, render_template, request, redirect, url_for, flash, session
import models

bp = Blueprint('auth', __name__)

@bp.route('/register', methods=['GET', 'POST'])
def register():
    """Registro de nuevos usuarios"""
    if request.method == 'POST':
        name = request.form['name']
        email = request.form['email']
        password = request.form['password']
        confirm = request.form['confirm_password']
        
        # Validaciones básicas
        if password != confirm:
            flash('Las contraseñas no coinciden', 'error')
            return render_template('register.html')
        
        if len(password) < 6:
            flash('La contraseña debe tener al menos 6 caracteres', 'error')
            return render_template('register.html')
        
        # Intentar registrar
        result = models.register_user(name, email, password)
        
        if result['success']:
            flash('Registro exitoso! Ya puedes iniciar sesión', 'success')
            return redirect(url_for('auth.login'))
        else:
            flash(result['message'], 'error')
            return render_template('register.html')
    
    return render_template('register.html')

@bp.route('/login', methods=['GET', 'POST'])
def login():
    """Inicio de sesión"""
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        
        user_id = models.login_user(email, password)
        
        if user_id > 0:
            session['user_id'] = user_id
            
            session['user_email'] = email
            flash('Inicio de sesión exitoso!', 'success')
            return redirect(url_for('index'))
        elif user_id == -1:
            flash('Email o contraseña incorrectos', 'error')
        else:
            flash('Error en el servidor. Intenta más tarde', 'error')
        
        return render_template('login.html')
    
    return render_template('login.html')

@bp.route('/logout')
def logout():
    """Cerrar sesión"""
    session.clear()
    flash('Has cerrado sesión', 'info')
    return redirect(url_for('index'))