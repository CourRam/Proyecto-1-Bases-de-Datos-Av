-- Insertar categorías de ejemplo
INSERT INTO categories (category_id, name, url, description) VALUES (seq_category_id.NEXTVAL, 'Technology', 'technology', 'Tech news and tutorials');
INSERT INTO categories (category_id, name, url, description) VALUES (seq_category_id.NEXTVAL, 'Programming', 'programming', 'Programming languages and best practices');
INSERT INTO categories (category_id, name, url, description) VALUES (seq_category_id.NEXTVAL, 'Lifestyle', 'lifestyle', 'Daily life and personal development');

-- Insertar tags de ejemplo
INSERT INTO tags (tag_id, name, url) VALUES (seq_tag_id.NEXTVAL, 'Python', 'python');
INSERT INTO tags (tag_id, name, url) VALUES (seq_tag_id.NEXTVAL, 'Flask', 'flask');
INSERT INTO tags (tag_id, name, url) VALUES (seq_tag_id.NEXTVAL, 'Oracle', 'oracle');
INSERT INTO tags (tag_id, name, url) VALUES (seq_tag_id.NEXTVAL, 'Tutorial', 'tutorial');

COMMIT;

-- =====================================================
-- VERIFICACIÓN
-- =====================================================
SELECT 'Database created successfully' as status FROM dual;