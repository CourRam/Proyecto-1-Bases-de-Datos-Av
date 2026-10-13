# Blog Web · Flask + Oracle Database

Aplicación web de blog desarrollada con **Flask** y **Oracle Database**. Los usuarios registrados pueden crear, editar y eliminar artículos, organizarlos por categorías y tags, y comentar en las publicaciones de otros usuarios.

La lógica de negocio vive en la base de datos: el registro, el inicio de sesión, el CRUD de artículos y comentarios y las consultas con filtros están implementados como **procedimientos y funciones almacenadas en PL/SQL**, que la aplicación Flask invoca.

Proyecto de la primera evaluación de Bases de Datos Avanzadas, Ingeniería en Ciencias de la Computación, Universidad Autónoma de Chihuahua (UACH).

## Funcionalidades

**Usuarios**
- Registro con validaciones (el correo no puede repetirse).
- Inicio de sesión con sesiones persistentes.

**Artículos**
- Crear artículos con título, contenido, categoría y múltiples tags.
- Editar y eliminar únicamente artículos propios.
- Vista detallada con contador de visitas.
- URLs amigables generadas automáticamente a partir del título (función PL/SQL `generate_url`).

**Comentarios**
- Solo usuarios autenticados pueden comentar.
- Editar y eliminar únicamente comentarios propios.

**Filtros y búsqueda**
- Filtrar por categoría, por tag o por texto (título y contenido).
- Filtros combinables.

## Tecnologías

| Capa | Herramientas |
|---|---|
| Backend | Python, Flask (blueprints) |
| Base de datos | Oracle Database, PL/SQL |
| Frontend | HTML, Jinja2, Bootstrap |

## Modelo de datos

```
users ──< articles >── categories
  │          │
  │          ├──< article_tags >── tags
  │          │
  └──────< comments >──┘
```

| Tabla | Columnas principales |
|---|---|
| `users` | `user_id`, `name`, `email` (único), `password`, `created_date` |
| `categories` | `category_id`, `name`, `url`, `description` |
| `tags` | `tag_id`, `name`, `url` |
| `articles` | `article_id`, `user_id`, `category_id`, `title`, `url`, `text` (CLOB), `created_date`, `views` |
| `comments` | `comment_id`, `user_id`, `article_id`, `text`, `url`, `created_date` |
| `article_tags` | `article_id`, `tag_id` (relación muchos a muchos) |

Los identificadores se generan con secuencias de Oracle y las llaves foráneas usan `ON DELETE CASCADE` donde corresponde (por ejemplo, al borrar un artículo se eliminan sus comentarios y sus relaciones con tags).

### Procedimientos y funciones almacenadas

Definidos en [`DB/proc_fun.sql`](DB/proc_fun.sql):

| Objeto | Descripción |
|---|---|
| `generate_url` | Convierte un texto en una URL amigable (minúsculas, sin acentos ni símbolos, con guiones). |
| `register_user` | Registra un usuario y valida que el correo no exista. |
| `login_user` | Autentica y devuelve el `user_id` (o `-1` si las credenciales son inválidas). |
| `create_category`, `create_tag` | Crean categorías y tags con URL única. |
| `create_article`, `update_article`, `delete_article` | CRUD de artículos con verificación de propiedad y asignación de tags. |
| `add_comment`, `update_comment`, `delete_comment` | CRUD de comentarios con verificación de propiedad. |
| `get_articles` | Lista artículos con filtros opcionales mediante SQL dinámico y `SYS_REFCURSOR`; agrega tags con `LISTAGG`. |
| `get_article_details` | Devuelve el artículo y sus comentarios, e incrementa el contador de vistas. |
| `get_all_categories`, `get_all_tags` | Catálogos para los filtros. |
| `get_user_articles`, `get_user_comments` | Actividad de un usuario. |

## Estructura del proyecto

```
├── DB/
│   ├── tablas.sql          # Secuencias y tablas
│   └── proc_fun.sql        # Procedimientos, funciones y datos iniciales
├── app/
│   ├── app.py              # Punto de entrada y rutas principales
│   ├── config.py           # Configuración de la aplicación
│   ├── database.py         # Conexión a Oracle y funciones auxiliares
│   ├── models.py           # Modelos y lógica de acceso a datos
│   ├── auth.py             # Registro e inicio de sesión
│   ├── routes/
│   │   ├── articles.py     # CRUD de artículos
│   │   └── comments.py     # CRUD de comentarios
│   └── templates/          # Plantillas HTML (base, index, login, register, article, ...)
├── Proyecto 1a. Evaluación.pdf
└── Proyecto 1a. Evaluación.docx
```

## Cómo ejecutarlo

### Requisitos

- Python 3.10 o superior
- Oracle Database (por ejemplo, Oracle Database Free) con un usuario con permisos para crear tablas, secuencias y procedimientos

### Pasos

1. Clona el repositorio:
   ```bash
   git clone https://github.com/CourRam/Proyecto-1-Bases-de-Datos-Av.git
   cd Proyecto-1-Bases-de-Datos-Av/app
   ```
2. Crea y activa un entorno virtual:
   ```bash
   python -m venv venv
   venv\Scripts\activate          # Windows
   source venv/bin/activate       # Linux / macOS
   ```
3. Instala las dependencias:
   ```bash
   pip install -r requirements.txt
   ```
4. Crea un archivo `.env` con tus datos de conexión:
   ```env
   ORACLE_USER=tu_usuario
   ORACLE_PASSWORD=tu_contraseña
   ORACLE_DSN=localhost:1521/FREEPDB1
   SECRET_KEY=tu_clave_secreta
   ```
5. Ejecuta en Oracle, en este orden, los scripts de `DB/`:
   1. `tablas.sql` (crea secuencias y tablas)
   2. `proc_fun.sql` (crea los procedimientos y carga 4 categorías y 7 tags de ejemplo)
6. Inicia la aplicación:
   ```bash
   python app.py
   ```
7. Abre `http://127.0.0.1:5000`.

> `tablas.sql` comienza con `DROP TABLE`, por lo que borra los datos existentes. Úsalo solo en una base de pruebas.

## Capturas de pantalla

<!-- Agrega aquí capturas de la página principal, el detalle de un artículo y el formulario de creación.
     Guárdalas en una carpeta docs/ y enlázalas, por ejemplo: ![Página principal](docs/inicio.png) -->

## Documentación

Reporte del proyecto con arquitectura y pruebas de funcionamiento: [`Proyecto 1a. Evaluación.pdf`](Proyecto%201a.%20Evaluaci%C3%B3n.pdf)

## Autor

**Joseph Daniel Ramírez Torres** · [GitHub](https://github.com/CourRam)
