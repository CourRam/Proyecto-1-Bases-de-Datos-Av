DROP TABLE article_tags;
DROP TABLE comments;
DROP TABLE articles;
DROP TABLE tags;
DROP TABLE categories;
DROP TABLE users;

DROP SEQUENCE seq_user_id;
DROP SEQUENCE seq_article_id;
DROP SEQUENCE seq_comment_id;
DROP SEQUENCE seq_tag_id;
DROP SEQUENCE seq_category_id;


CREATE SEQUENCE seq_user_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_article_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_comment_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_tag_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_category_id START WITH 1 INCREMENT BY 1;


-- Tabla de usuarios
CREATE TABLE users (
    user_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    password VARCHAR2(100) NOT NULL,
    created_date DATE DEFAULT SYSDATE
);

-- Tabla de categorías
CREATE TABLE categories (
    category_id NUMBER PRIMARY KEY,
    name VARCHAR2(50) UNIQUE NOT NULL,
    url VARCHAR2(100) UNIQUE NOT NULL,
    description VARCHAR2(500)
);

-- Tabla de etiquetas
CREATE TABLE tags (
    tag_id NUMBER PRIMARY KEY,
    name VARCHAR2(50) UNIQUE NOT NULL,
    url VARCHAR2(100) UNIQUE NOT NULL
);

-- Tabla de artículos 
CREATE TABLE articles (
    article_id NUMBER PRIMARY KEY,
    user_id NUMBER NOT NULL,
    category_id NUMBER NOT NULL,
    title VARCHAR2(200) NOT NULL,
    url VARCHAR2(200) UNIQUE NOT NULL,
    text CLOB NOT NULL,
    created_date DATE DEFAULT SYSDATE,  
    views NUMBER DEFAULT 0,
    CONSTRAINT fk_articles_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_articles_category FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Tabla de comentarios 
CREATE TABLE comments (
    comment_id NUMBER PRIMARY KEY,
    user_id NUMBER NOT NULL,
    article_id NUMBER NOT NULL,
    text VARCHAR2(2000) NOT NULL,
    url VARCHAR2(200) UNIQUE,
    created_date DATE DEFAULT SYSDATE,  
    CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_comments_article FOREIGN KEY (article_id) REFERENCES articles(article_id) ON DELETE CASCADE
);

-- Tabla intermedia para artículos y tags
CREATE TABLE article_tags (
    article_id NUMBER,
    tag_id NUMBER,
    PRIMARY KEY (article_id, tag_id),
    CONSTRAINT fk_articletags_article FOREIGN KEY (article_id) REFERENCES articles(article_id) ON DELETE CASCADE,
    CONSTRAINT fk_articletags_tag FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
);


CREATE INDEX idx_articles_date ON articles(created_date DESC);
CREATE INDEX idx_articles_user ON articles(user_id);
CREATE INDEX idx_articles_category ON articles(category_id);
CREATE INDEX idx_comments_article ON comments(article_id);
CREATE INDEX idx_comments_user ON comments(user_id);


SELECT 'Tablas creadas exitosamente' as estado FROM dual;

-- Mostrar las tablas creadas
SELECT table_name FROM user_tables WHERE table_name IN ('USERS', 'CATEGORIES', 'TAGS', 'ARTICLES', 'COMMENTS', 'ARTICLE_TAGS');