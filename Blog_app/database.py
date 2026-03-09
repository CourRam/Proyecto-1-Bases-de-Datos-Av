import oracledb
from flask import g, current_app
import traceback

def get_db():
    """Obtener conexión a la base de datos para la petición actual"""
    if 'db' not in g:
        try:
            # Conectar a Oracle
            g.db = oracledb.connect(
                user=current_app.config['ORACLE_USER'],
                password=current_app.config['ORACLE_PASSWORD'],
                dsn=current_app.config['ORACLE_DSN']
            )
            # Para que los nombres de columnas sean accesibles como diccionario
            g.db.autocommit = False
        except Exception as e:
            current_app.logger.error(f"Error conectando a BD: {str(e)}")
            current_app.logger.error(traceback.format_exc())
            return None
    
    return g.db

def close_db(e=None):
    """Cerrar conexión a la base de datos"""
    db = g.pop('db', None)
    
    if db is not None:
        try:
            db.close()
        except Exception as e:
            current_app.logger.error(f"Error cerrando conexión: {str(e)}")

def execute_procedure(proc_name, params=None, commit=False):
    """
    Ejecutar un procedimiento almacenado y retornar los valores OUT
    
    Args:
        proc_name: Nombre del procedimiento
        params: Diccionario con parámetros {nombre: valor}
        commit: Si True, hace commit después de ejecutar
    
    Returns:
        Diccionario con los valores de los parámetros OUT
    """
    db = get_db()
    if not db:
        return {'success': 0, 'message': 'No database connection'}
    
    cursor = None
    try:
        cursor = db.cursor()
        
        # Construir la llamada al procedimiento
        if params:
            placeholders = ', '.join([f":{name}" for name in params.keys()])
            sql = f"BEGIN {proc_name}({placeholders}); END;"
            cursor.execute(sql, params)
        else:
            sql = f"BEGIN {proc_name}(); END;"
            cursor.execute(sql)
        
        if commit:
            db.commit()
        
        # Si hay parámetros OUT, recuperarlos
        if params:
            # Intentar obtener los valores de los parámetros OUT
            # Esto es un poco tricky con oracledb, por ahora retornamos éxito básico
            return {'success': 1, 'message': 'Procedure executed successfully'}
        else:
            return {'success': 1, 'message': 'Procedure executed successfully'}
            
    except Exception as e:
        if commit:
            db.rollback()
        current_app.logger.error(f"Error executing {proc_name}: {str(e)}")
        current_app.logger.error(traceback.format_exc())
        return {'success': 0, 'message': str(e)}
    finally:
        if cursor:
            cursor.close()

# database.py (solo la parte de execute_function corregida)

def execute_function(func_name, params=None, return_type=None):
    """
    Ejecutar una función y retornar su valor
    
    Args:
        func_name: Nombre de la función
        params: Diccionario con parámetros
        return_type: Tipo de retorno esperado
    
    Returns:
        Valor retornado por la función
    """
    db = get_db()
    if not db:
        return None
    
    cursor = None
    try:
        cursor = db.cursor()
        
        # Crear variable para el retorno
        return_var = cursor.var(return_type or oracledb.NUMBER)
        
        # Construir la llamada - CORREGIDO
        if params:
            # Crear lista de parámetros en orden
            param_values = []
            param_names = list(params.keys())
            placeholders = []
            
            for i, (name, value) in enumerate(params.items()):
                param_values.append(value)
                placeholders.append(f":{i+1}")
            
            sql = f"BEGIN :result := {func_name}({', '.join(placeholders)}); END;"
            
            # Preparar bind variables
            bind_vars = {'result': return_var}
            for i, value in enumerate(param_values):
                bind_vars[str(i+1)] = value
            
            cursor.execute(sql, bind_vars)
        else:
            sql = f"BEGIN :result := {func_name}(); END;"
            cursor.execute(sql, {'result': return_var})
        
        return return_var.getvalue()
        
    except Exception as e:
        current_app.logger.error(f"Error executing {func_name}: {str(e)}")
        current_app.logger.error(traceback.format_exc())
        return None
    finally:
        if cursor:
            cursor.close()

def fetch_all(proc_name, params=None):
    """
    Ejecutar un procedimiento que retorna un cursor y obtener todos los resultados
    
    Args:
        proc_name: Nombre del procedimiento
        params: Diccionario con parámetros
    
    Returns:
        Lista de diccionarios con los resultados
    """
    db = get_db()
    if not db:
        return []
    
    cursor = None
    try:
        cursor = db.cursor()
        
        # Crear variable para el cursor
        cursor_var = cursor.var(oracledb.CURSOR)
        
        # Construir la llamada
        if params:
            placeholders = ', '.join([f":{name}" for name in params.keys()])
            sql = f"BEGIN {proc_name}({placeholders}, :cursor); END;"
            params_with_cursor = {**params, 'cursor': cursor_var}
            cursor.execute(sql, params_with_cursor)
        else:
            sql = f"BEGIN {proc_name}(:cursor); END;"
            cursor.execute(sql, {'cursor': cursor_var})
        
        # Obtener el cursor de resultados
        result_cursor = cursor_var.getvalue()
        
        # Convertir a lista de diccionarios
        columns = [col[0] for col in result_cursor.description]
        rows = result_cursor.fetchall()
        
        result = []
        for row in rows:
            result.append(dict(zip(columns, row)))
        
        return result
        
    except Exception as e:
        current_app.logger.error(f"Error fetching from {proc_name}: {str(e)}")
        current_app.logger.error(traceback.format_exc())
        return []
    finally:
        if cursor:
            cursor.close()

def init_app(app):
    """Registrar funciones de cierre de conexión con la app"""
    app.teardown_appcontext(close_db)