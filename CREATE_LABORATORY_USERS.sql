-- =====================================================
-- CRÉER DES UTILISATEURS LABORATOIRES
-- E-Santé - Plateforme Nationale de Santé Numérique
-- =====================================================

USE esante_db;

-- Vérifier les utilisateurs laboratoires existants
SELECT 'Utilisateurs avec role laboratoire:' as status;
SELECT user_id, email, full_name, role FROM users WHERE role = 'laboratoire';

-- Vérifier les laboratoires sans user_id
SELECT 'Laboratoires sans utilisateur:' as status;
SELECT laboratory_id, name, user_id FROM laboratories;

-- Créer des utilisateurs pour chaque laboratoire
-- 1. Laboratoire Central de Biologie Médicale
INSERT INTO users (email, password_hash, full_name, phone, role, is_active, last_login)
SELECT 'biologie@esante.fr', SHA2('biologie123', 256), 'Laboratoire Central de Biologie Médicale', '+33123456789', 'laboratoire', TRUE, NOW()
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'biologie@esante.fr');

-- 2. Centre de Radiologie et Imagerie Médicale
INSERT INTO users (email, password_hash, full_name, phone, role, is_active, last_login)
SELECT 'radiologie@esante.fr', SHA2('radiologie123', 256), 'Centre de Radiologie et Imagerie Médicale', '+33123456790', 'laboratoire', TRUE, NOW()
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'radiologie@esante.fr');

-- 3. Laboratoire d'Anatomopathologie
INSERT INTO users (email, password_hash, full_name, phone, role, is_active, last_login)
SELECT 'anatomopath@esante.fr', SHA2('anatomopath123', 256), 'Laboratoire d\'Anatomopathologie', '+33123456791', 'laboratoire', TRUE, NOW()
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'anatomopath@esante.fr');

-- Lier les utilisateurs aux laboratoires
UPDATE laboratories SET user_id = (SELECT user_id FROM users WHERE email = 'biologie@esante.fr' LIMIT 1) WHERE name LIKE '%Biologie%' AND user_id IS NULL;
UPDATE laboratories SET user_id = (SELECT user_id FROM users WHERE email = 'radiologie@esante.fr' LIMIT 1) WHERE name LIKE '%Radiologie%' AND user_id IS NULL;
UPDATE laboratories SET user_id = (SELECT user_id FROM users WHERE email = 'anatomopath@esante.fr' LIMIT 1) WHERE name LIKE '%Anatomopath%' AND user_id IS NULL;

-- Afficher les résultats
SELECT 'Laboratoires après association:' as status;
SELECT l.laboratory_id, l.name, l.user_id, u.email, u.full_name 
FROM laboratories l
LEFT JOIN users u ON l.user_id = u.user_id
ORDER BY l.laboratory_id;

SELECT 'Utilisateurs laboratoires créés:' as status;
SELECT user_id, email, full_name, role FROM users WHERE role = 'laboratoire';
