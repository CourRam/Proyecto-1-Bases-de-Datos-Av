-- Función para generar URL 
CREATE OR REPLACE FUNCTION generate_url(p_text IN VARCHAR2) RETURN VARCHAR2 IS
    v_url VARCHAR2(200);
BEGIN
    v_url := LOWER(p_text);
    
    -- Reemplazar caracteres especiales y espacios
    -- Mantener solo letras, números, y espacios, el resto se elimina
    v_url := REGEXP_REPLACE(v_url, '[^a-z0-9áéíóúüñ\s-]', '');
    
    -- Reemplazar vocales con acentos por sus equivalentes sin acento
    v_url := REPLACE(v_url, 'á', 'a');
    v_url := REPLACE(v_url, 'é', 'e');
    v_url := REPLACE(v_url, 'í', 'i');
    v_url := REPLACE(v_url, 'ó', 'o');
    v_url := REPLACE(v_url, 'ú', 'u');
    v_url := REPLACE(v_url, 'ü', 'u');
    v_url := REPLACE(v_url, 'ñ', 'n');
    
    -- Reemplazar espacios por guiones
    v_url := REGEXP_REPLACE(v_url, '\s+', '-');
    
    -- Eliminar guiones múltiples
    v_url := REGEXP_REPLACE(v_url, '-+', '-');
    
    -- Eliminar guiones al inicio o final
    v_url := TRIM(BOTH '-' FROM v_url);
    
    -- Si después de todo queda vacío, poner un valor por defecto
    IF v_url IS NULL OR LENGTH(v_url) = 0 THEN
        v_url := 'post-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISS');
    END IF;
    
    RETURN v_url;
END generate_url;
/


CREATE OR REPLACE PROCEDURE register_user(
    p_name IN users.name%TYPE,
    p_email IN users.email%TYPE,
    p_password IN users.password%TYPE,
    p_user_id OUT users.user_id%TYPE,
    p_success OUT NUMBER,
    p_message OUT VARCHAR2
) IS
    v_email_count NUMBER;
BEGIN
    
    SELECT COUNT(*) INTO v_email_count FROM users WHERE email = p_email;
    
    IF v_email_count > 0 THEN
        p_success := 0;
        p_message := 'Email already registered';
        RETURN;
    END IF;
    
    -- Insertar nuevo usuario
    p_user_id := seq_user_id.NEXTVAL;
    INSERT INTO users (user_id, name, email, password, created_date)
    VALUES (p_user_id, p_name, p_email, p_password, SYSDATE);
    
    COMMIT;
    p_success := 1;
    p_message := 'User registered successfully';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error: ' || SQLERRM;
END register_user;
/


CREATE OR REPLACE FUNCTION login_user(
    p_email IN users.email%TYPE,
    p_password IN users.password%TYPE
) RETURN NUMBER IS
    v_user_id NUMBER;
BEGIN
    BEGIN
        SELECT user_id INTO v_user_id
        FROM users
        WHERE email = p_email AND password = p_password;
        
        RETURN v_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN -1;  
    END;
END login_user;
/


CREATE OR REPLACE PROCEDURE create_category(
    p_name IN categories.name%TYPE,
    p_description IN categories.description%TYPE DEFAULT NULL,
    p_category_id OUT categories.category_id%TYPE,
    p_success OUT NUMBER,
    p_message OUT VARCHAR2
) IS
    v_url categories.url%TYPE;
    v_url_count NUMBER;
BEGIN
    -- Generar URL a partir del nombre
    v_url := generate_url(p_name);
    
    -- Verificar si la URL ya existe
    SELECT COUNT(*) INTO v_url_count FROM categories WHERE url = v_url;
    
    IF v_url_count > 0 THEN
        -- Si existe, agregar un sufijo numérico
        v_url := v_url || '-' || TO_CHAR(seq_category_id.NEXTVAL);
    END IF;
    
    -- Insertar categoría
    p_category_id := seq_category_id.NEXTVAL;
    INSERT INTO categories (category_id, name, url, description)
    VALUES (p_category_id, p_name, v_url, p_description);
    
    COMMIT;
    p_success := 1;
    p_message := 'Category created successfully. URL: /category/' || v_url;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error creating category: ' || SQLERRM;
END create_category;
/


CREATE OR REPLACE PROCEDURE create_tag(
    p_name IN tags.name%TYPE,
    p_tag_id OUT tags.tag_id%TYPE,
    p_success OUT NUMBER,
    p_message OUT VARCHAR2
) IS
    v_url tags.url%TYPE;
    v_url_count NUMBER;
BEGIN
    -- Generar URL a partir del nombre
    v_url := generate_url(p_name);
    
    -- Verificar si la URL ya existe
    SELECT COUNT(*) INTO v_url_count FROM tags WHERE url = v_url;
    
    IF v_url_count > 0 THEN
        -- Si existe, agregar un sufijo numérico
        v_url := v_url || '-' || TO_CHAR(seq_tag_id.NEXTVAL);
    END IF;
    
    -- Insertar tag
    p_tag_id := seq_tag_id.NEXTVAL;
    INSERT INTO tags (tag_id, name, url)
    VALUES (p_tag_id, p_name, v_url);
    
    COMMIT;
    p_success := 1;
    p_message := 'Tag created successfully. URL: /tag/' || v_url;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error creating tag: ' || SQLERRM;
END create_tag;
/


CREATE OR REPLACE PROCEDURE create_article(
    p_user_id IN articles.user_id%TYPE,
    p_category_id IN articles.category_id%TYPE,
    p_title IN articles.title%TYPE,
    p_text IN articles.text%TYPE,
    p_tag_ids IN VARCHAR2, 
    p_article_id OUT articles.article_id%TYPE,
    p_success OUT NUMBER,
    p_message OUT VARCHAR2
) IS
    v_url articles.url%TYPE;
    v_url_count NUMBER;
    v_tag_id NUMBER;
    v_start_pos NUMBER := 1;
    v_end_pos NUMBER;
    v_tag_list VARCHAR2(1000) := p_tag_ids || ',';
    v_category_name categories.name%TYPE;
BEGIN
    -- Verificar que la categoría existe
    BEGIN
        SELECT name INTO v_category_name FROM categories WHERE category_id = p_category_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_success := 0;
            p_message := 'Category does not exist';
            RETURN;
    END;
    
    -- Generar URL a partir del título
    v_url := generate_url(p_title);
    
    -- Verificar si la URL ya existe
    SELECT COUNT(*) INTO v_url_count FROM articles WHERE url = v_url;
    
    IF v_url_count > 0 THEN
        -- Si existe, agregar timestamp
        v_url := v_url || '-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISS');
    END IF;
    
    -- Insertar artículo
    p_article_id := seq_article_id.NEXTVAL;
    INSERT INTO articles (article_id, user_id, category_id, title, url, text, created_date, views)
    VALUES (p_article_id, p_user_id, p_category_id, p_title, v_url, p_text, SYSDATE, 0);
    
    
    IF p_tag_ids IS NOT NULL AND LENGTH(TRIM(p_tag_ids)) > 0 THEN
        LOOP
            v_end_pos := INSTR(v_tag_list, ',', v_start_pos);
            EXIT WHEN v_end_pos = 0;
            
            v_tag_id := TO_NUMBER(SUBSTR(v_tag_list, v_start_pos, v_end_pos - v_start_pos));
            
            -- Verificar que el tag existe
            BEGIN
                INSERT INTO article_tags (article_id, tag_id)
                VALUES (p_article_id, v_tag_id);
            EXCEPTION
                WHEN OTHERS THEN
                    NULL; 
            END;
            
            v_start_pos := v_end_pos + 1;
        END LOOP;
    END IF;
    
    COMMIT;
    p_success := 1;
    p_message := 'Article created successfully. URL: /article/' || v_url;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error creating article: ' || SQLERRM;
END create_article;
/


CREATE OR REPLACE PROCEDURE update_article(
    p_article_id IN articles.article_id%TYPE,
    p_user_id IN articles.user_id%TYPE, -- Para verificar propiedad
    p_category_id IN articles.category_id%TYPE,
    p_title IN articles.title%TYPE,
    p_text IN articles.text%TYPE,
    p_tag_ids IN VARCHAR2,
    p_success OUT NUMBER,
    p_message OUT VARCHAR2
) IS
    v_owner_id articles.user_id%TYPE;
    v_url articles.url%TYPE;
    v_old_url articles.url%TYPE;
    v_url_count NUMBER;
    v_tag_id NUMBER;
    v_start_pos NUMBER := 1;
    v_end_pos NUMBER;
    v_tag_list VARCHAR2(1000) := p_tag_ids || ',';
BEGIN
    -- Verificar que el artículo existe y obtener propietario y URL actual
    BEGIN
        SELECT user_id, url INTO v_owner_id, v_old_url
        FROM articles WHERE article_id = p_article_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_success := 0;
            p_message := 'Article not found';
            RETURN;
    END;
    
    -- Verificar que el usuario sea el propietario
    IF v_owner_id != p_user_id THEN
        p_success := 0;
        p_message := 'You can only update your own articles';
        RETURN;
    END IF;
    
    -- Generar nueva URL a partir del título
    v_url := generate_url(p_title);
    
    -- Si la nueva URL es diferente a la anterior, verificar que no exista
    IF v_url != v_old_url THEN
        SELECT COUNT(*) INTO v_url_count FROM articles WHERE url = v_url;
        IF v_url_count > 0 THEN
            -- Si existe, agregar timestamp
            v_url := v_url || '-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISS');
        END IF;
    ELSE
        -- Si es la misma, mantener la URL original
        v_url := v_old_url;
    END IF;
    
    -- Actualizar artículo
    UPDATE articles
    SET category_id = p_category_id,
        title = p_title,
        url = v_url,
        text = p_text
    WHERE article_id = p_article_id;
    
   
    DELETE FROM article_tags WHERE article_id = p_article_id;
    
    IF p_tag_ids IS NOT NULL AND LENGTH(TRIM(p_tag_ids)) > 0 THEN
        LOOP
            v_end_pos := INSTR(v_tag_list, ',', v_start_pos);
            EXIT WHEN v_end_pos = 0;
            
            v_tag_id := TO_NUMBER(SUBSTR(v_tag_list, v_start_pos, v_end_pos - v_start_pos));
            
            BEGIN
                INSERT INTO article_tags (article_id, tag_id)
                VALUES (p_article_id, v_tag_id);
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
            
            v_start_pos := v_end_pos + 1;
        END LOOP;
    END IF;
    
    COMMIT;
    p_success := 1;
    p_message := 'Article updated successfully. URL: /article/' || v_url;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error updating article: ' || SQLERRM;
END update_article;
/

-- Procedimiento para eliminar artículo
CREATE OR REPLACE PROCEDURE delete_article(
    p_article_id IN articles.article_id%TYPE,
    p_user_id IN articles.user_id%TYPE,
    p_success OUT NUMBER,
    p_message OUT VARCHAR2
) IS
    v_owner_id articles.user_id%TYPE;
BEGIN
    -- Verificar que el artículo existe y obtener propietario
    BEGIN
        SELECT user_id INTO v_owner_id FROM articles WHERE article_id = p_article_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_success := 0;
            p_message := 'Article not found';
            RETURN;
    END;
    
    -- Verificar propiedad
    IF v_owner_id != p_user_id THEN
        p_success := 0;
        p_message := 'You can only delete your own articles';
        RETURN;
    END IF;
    
    
    DELETE FROM articles WHERE article_id = p_article_id;
    
    COMMIT;
    p_success := 1;
    p_message := 'Article deleted successfully';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error deleting article: ' || SQLERRM;
END delete_article;
/


CREATE OR REPLACE PROCEDURE add_comment(
    p_user_id IN comments.user_id%TYPE,
    p_article_id IN comments.article_id%TYPE,
    p_text IN comments.text%TYPE,
    p_comment_id OUT comments.comment_id%TYPE,
    p_success OUT NUMBER,
    p_message OUT VARCHAR2
) IS
    v_url comments.url%TYPE;
    v_article_exists NUMBER;
BEGIN
    -- Verificar que el artículo existe
    SELECT COUNT(*) INTO v_article_exists FROM articles WHERE article_id = p_article_id;
    
    IF v_article_exists = 0 THEN
        p_success := 0;
        p_message := 'Article not found';
        RETURN;
    END IF;
    
    -- Crear comentario
    p_comment_id := seq_comment_id.NEXTVAL;
    v_url := 'comment/' || p_comment_id;
    
    INSERT INTO comments (comment_id, user_id, article_id, text, url, created_date)
    VALUES (p_comment_id, p_user_id, p_article_id, p_text, v_url, SYSDATE);
    
    COMMIT;
    p_success := 1;
    p_message := 'Comment added successfully. URL: /' || v_url;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error adding comment: ' || SQLERRM;
END add_comment;
/

-- Procedimiento para actualizar comentario
CREATE OR REPLACE PROCEDURE update_comment(
    p_comment_id IN comments.comment_id%TYPE,
    p_user_id IN comments.user_id%TYPE,
    p_text IN comments.text%TYPE,
    p_success OUT NUMBER,
    p_message OUT VARCHAR2
) IS
    v_owner_id comments.user_id%TYPE;
BEGIN
    -- Verificar propiedad
    BEGIN
        SELECT user_id INTO v_owner_id FROM comments WHERE comment_id = p_comment_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_success := 0;
            p_message := 'Comment not found';
            RETURN;
    END;
    
    IF v_owner_id != p_user_id THEN
        p_success := 0;
        p_message := 'You can only update your own comments';
        RETURN;
    END IF;
    
    -- Actualizar comentario
    UPDATE comments SET text = p_text WHERE comment_id = p_comment_id;
    
    COMMIT;
    p_success := 1;
    p_message := 'Comment updated successfully';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error updating comment: ' || SQLERRM;
END update_comment;
/

-- Procedimiento para eliminar comentario
CREATE OR REPLACE PROCEDURE delete_comment(
    p_comment_id IN comments.comment_id%TYPE,
    p_user_id IN comments.user_id%TYPE,
    p_success OUT NUMBER,
    p_message OUT VARCHAR2
) IS
    v_owner_id comments.user_id%TYPE;
BEGIN
    -- Verificar propiedad
    BEGIN
        SELECT user_id INTO v_owner_id FROM comments WHERE comment_id = p_comment_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_success := 0;
            p_message := 'Comment not found';
            RETURN;
    END;
    
    IF v_owner_id != p_user_id THEN
        p_success := 0;
        p_message := 'You can only delete your own comments';
        RETURN;
    END IF;
    
    -- Eliminar comentario
    DELETE FROM comments WHERE comment_id = p_comment_id;
    
    COMMIT;
    p_success := 1;
    p_message := 'Comment deleted successfully';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_success := 0;
        p_message := 'Error deleting comment: ' || SQLERRM;
END delete_comment;
/

-- Procedimiento para obtener artículos con filtros
CREATE OR REPLACE PROCEDURE get_articles(
    p_category_url IN VARCHAR2 DEFAULT NULL,
    p_tag_url IN VARCHAR2 DEFAULT NULL,
    p_search_term IN VARCHAR2 DEFAULT NULL,
    p_user_id IN NUMBER DEFAULT NULL,
    p_results OUT SYS_REFCURSOR
) IS
    v_sql VARCHAR2(4000);
BEGIN
    v_sql := 'SELECT a.article_id, a.title, a.url, a.created_date, u.name as author, '
          || 'c.name as category, c.url as category_url, a.views, '
          || '(SELECT COUNT(*) FROM comments com WHERE com.article_id = a.article_id) as comment_count, '
          || 'LISTAGG(t.name, '', '') WITHIN GROUP (ORDER BY t.name) as tags '
          || 'FROM articles a '
          || 'JOIN users u ON a.user_id = u.user_id '
          || 'JOIN categories c ON a.category_id = c.category_id '
          || 'LEFT JOIN article_tags at ON a.article_id = at.article_id '
          || 'LEFT JOIN tags t ON at.tag_id = t.tag_id '
          || 'WHERE 1=1 ';
    
    IF p_category_url IS NOT NULL THEN
        v_sql := v_sql || 'AND c.url = :cat_url ';
    END IF;
    
    IF p_tag_url IS NOT NULL THEN
        v_sql := v_sql || 'AND a.article_id IN (SELECT article_id FROM article_tags at2 JOIN tags t2 ON at2.tag_id = t2.tag_id WHERE t2.url = :tag_url) ';
    END IF;
    
    IF p_search_term IS NOT NULL THEN
        v_sql := v_sql || 'AND (LOWER(a.title) LIKE ''%'' || LOWER(:search) || ''%'' OR LOWER(a.text) LIKE ''%'' || LOWER(:search) || ''%'') ';
    END IF;
    
    IF p_user_id IS NOT NULL THEN
        v_sql := v_sql || 'AND a.user_id = :user_id ';
    END IF;
    
    v_sql := v_sql || 'GROUP BY a.article_id, a.title, a.url, a.created_date, u.name, c.name, c.url, a.views '
                   || 'ORDER BY a.created_date DESC';
    
    -- Abrir cursor con los parámetros correspondientes
    IF p_category_url IS NOT NULL AND p_tag_url IS NOT NULL AND p_search_term IS NOT NULL AND p_user_id IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_category_url, p_tag_url, p_search_term, p_user_id;
    ELSIF p_category_url IS NOT NULL AND p_tag_url IS NOT NULL AND p_search_term IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_category_url, p_tag_url, p_search_term;
    ELSIF p_category_url IS NOT NULL AND p_tag_url IS NOT NULL AND p_user_id IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_category_url, p_tag_url, p_user_id;
    ELSIF p_category_url IS NOT NULL AND p_search_term IS NOT NULL AND p_user_id IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_category_url, p_search_term, p_user_id;
    ELSIF p_tag_url IS NOT NULL AND p_search_term IS NOT NULL AND p_user_id IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_tag_url, p_search_term, p_user_id;
    ELSIF p_category_url IS NOT NULL AND p_tag_url IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_category_url, p_tag_url;
    ELSIF p_category_url IS NOT NULL AND p_search_term IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_category_url, p_search_term;
    ELSIF p_category_url IS NOT NULL AND p_user_id IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_category_url, p_user_id;
    ELSIF p_tag_url IS NOT NULL AND p_search_term IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_tag_url, p_search_term;
    ELSIF p_tag_url IS NOT NULL AND p_user_id IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_tag_url, p_user_id;
    ELSIF p_search_term IS NOT NULL AND p_user_id IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_search_term, p_user_id;
    ELSIF p_category_url IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_category_url;
    ELSIF p_tag_url IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_tag_url;
    ELSIF p_search_term IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_search_term;
    ELSIF p_user_id IS NOT NULL THEN
        OPEN p_results FOR v_sql USING p_user_id;
    ELSE
        OPEN p_results FOR v_sql;
    END IF;
END get_articles;
/


CREATE OR REPLACE PROCEDURE get_article_details(
    p_article_url IN articles.url%TYPE,
    p_article_cursor OUT SYS_REFCURSOR,
    p_comments_cursor OUT SYS_REFCURSOR
) IS
    v_article_id articles.article_id%TYPE;
BEGIN
    -- Obtener ID del artículo y actualizar vistas
    BEGIN
        SELECT article_id INTO v_article_id FROM articles WHERE url = p_article_url;
        
        -- Actualizar vistas
        UPDATE articles SET views = views + 1 WHERE article_id = v_article_id;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si no existe el artículo, abrir cursores vacíos y retornar
            OPEN p_article_cursor FOR SELECT NULL FROM dual WHERE 1=0;
            OPEN p_comments_cursor FOR SELECT NULL FROM dual WHERE 1=0;
            RETURN;
    END;
    
    -- Información del artículo con tags
    OPEN p_article_cursor FOR
        SELECT a.article_id, a.title, a.text, a.created_date, a.views,
               u.name as author, u.user_id as author_id,
               c.name as category, c.url as category_url, c.category_id,
               LISTAGG(t.name, ', ') WITHIN GROUP (ORDER BY t.name) as tags,
               LISTAGG(t.tag_id, ',') WITHIN GROUP (ORDER BY t.name) as tag_ids
        FROM articles a
        JOIN users u ON a.user_id = u.user_id
        JOIN categories c ON a.category_id = c.category_id
        LEFT JOIN article_tags at ON a.article_id = at.article_id
        LEFT JOIN tags t ON at.tag_id = t.tag_id
        WHERE a.article_id = v_article_id
        GROUP BY a.article_id, a.title, a.text, a.created_date, a.views, 
                 u.name, u.user_id, c.name, c.url, c.category_id;
    
    -- Comentarios del artículo con información del usuario
    OPEN p_comments_cursor FOR
        SELECT c.comment_id, c.text, c.created_date, c.url,
               u.name as commenter, u.user_id as commenter_id
        FROM comments c
        JOIN users u ON c.user_id = u.user_id
        WHERE c.article_id = v_article_id
        ORDER BY c.created_date DESC;
        
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END get_article_details;
/

-- Procedimiento para obtener todas las categorías
CREATE OR REPLACE PROCEDURE get_all_categories(
    p_results OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_results FOR
        SELECT category_id, name, url, description
        FROM categories
        ORDER BY name;
END get_all_categories;
/

-- Procedimiento para obtener todos los tags
CREATE OR REPLACE PROCEDURE get_all_tags(
    p_results OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_results FOR
        SELECT tag_id, name, url
        FROM tags
        ORDER BY name;
END get_all_tags;
/

-- Procedimiento para obtener artículos de un usuario específico
CREATE OR REPLACE PROCEDURE get_user_articles(
    p_user_id IN articles.user_id%TYPE,
    p_results OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_results FOR
        SELECT a.article_id, a.title, a.url, a.created_date, a.views,
               c.name as category,
               (SELECT COUNT(*) FROM comments com WHERE com.article_id = a.article_id) as comment_count
        FROM articles a
        JOIN categories c ON a.category_id = c.category_id
        WHERE a.user_id = p_user_id
        ORDER BY a.created_date DESC;
END get_user_articles;
/

-- Procedimiento para obtener comentarios de un usuario específico
CREATE OR REPLACE PROCEDURE get_user_comments(
    p_user_id IN comments.user_id%TYPE,
    p_results OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_results FOR
        SELECT c.comment_id, c.text, c.created_date, c.url,
               a.title as article_title, a.url as article_url
        FROM comments c
        JOIN articles a ON c.article_id = a.article_id
        WHERE c.user_id = p_user_id
        ORDER BY c.created_date DESC;
END get_user_comments;
/



DECLARE
    v_cat_id NUMBER;
    v_success NUMBER;
    v_msg VARCHAR2(500);
BEGIN
    create_category('Technology', 'Tech news, gadgets, and innovations', v_cat_id, v_success, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
    
    create_category('Programming', 'Coding tutorials and best practices', v_cat_id, v_success, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
    
    create_category('Lifestyle', 'Daily life, health, and personal development', v_cat_id, v_success, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
    
    create_category('Travel', 'Travel guides and experiences', v_cat_id, v_success, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
    
    COMMIT;
END;
/

DECLARE
    v_tag_id NUMBER;
    v_success NUMBER;
    v_msg VARCHAR2(500);
BEGIN
    create_tag('Python', v_tag_id, v_success, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
    
    create_tag('JavaScript', v_tag_id, v_success, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
    
    create_tag('Flask', v_tag_id, v_success, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
    
    create_tag('React', v_tag_id, v_success, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
    
    create_tag('Database', v_tag_id, v_success, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
    
    create_tag('Oracle', v_tag_id, v_success, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
    
    create_tag('Tutorial', v_tag_id, v_success, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
    
    COMMIT;
END;
/
