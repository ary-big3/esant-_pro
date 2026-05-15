-- =====================================================
-- FIX: Corriger l'architecture nurse_id
-- =====================================================
-- Le problème: vital_signs.nurse_id référence users.user_id
-- Mais on essaie d'insérer nurses.nurse_id (incompatibilité ❌)
-- 
-- La solution: Changer vital_signs.nurse_id pour référencer nurses.nurse_id
-- =====================================================

-- 1. Supprimer les contraintes existantes
ALTER TABLE vital_signs DROP FOREIGN KEY vital_signs_ibfk_2;

-- 2. Modifier la colonne nurse_id pour référencer nurses.nurse_id
ALTER TABLE vital_signs 
    MODIFY nurse_id INT NULL COMMENT 'Référence à nurses.nurse_id (pas users.user_id)';

-- 3. Ajouter la contrainte FK correcte
ALTER TABLE vital_signs 
    ADD CONSTRAINT vital_signs_ibfk_2 FOREIGN KEY (nurse_id) REFERENCES nurses(nurse_id) ON DELETE SET NULL;

-- 4. Vérifier la structure
DESCRIBE vital_signs;

-- 5. Données de test (si nécessaire)
-- Insérer un utilisateur infirmière
INSERT INTO users (email, password_hash, full_name, phone, role, is_active) 
VALUES ('nurse.test@esante.com', SHA2('password123', 256), 'Infirmière Test', '0612345678', 'infirmiere', TRUE)
ON DUPLICATE KEY UPDATE user_id = LAST_INSERT_ID(user_id);

-- Récupérer le user_id inséré
SET @user_id = LAST_INSERT_ID();

-- Insérer l'enregistrement infirmière
INSERT INTO nurses (user_id, first_name, last_name, phone, email, nursing_license, department, is_available)
VALUES (@user_id, 'Test', 'Infirmière', '0612345678', 'nurse.test@esante.com', 'LICENSE123', 'Urgences', TRUE)
ON DUPLICATE KEY UPDATE nurse_id = LAST_INSERT_ID(nurse_id);

-- Afficher les résultats
SELECT 'Users créés:' as '';
SELECT user_id, email, full_name, role FROM users WHERE role = 'infirmiere' LIMIT 5;

SELECT 'Nurses créés:' as '';
SELECT nurse_id, user_id, first_name, last_name FROM nurses LIMIT 5;

SELECT 'Structure vital_signs (après fix):' as '';
SHOW CREATE TABLE vital_signs\G
