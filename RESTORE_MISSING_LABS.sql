-- =====================================================
-- RESTAURER LES LABORATOIRES MANQUANTS
-- =====================================================

USE esante_db;

-- Récupérer les IDs des utilisateurs existants ou les créer
SET @user_id_biologie = (SELECT user_id FROM users WHERE email = 'lab_biologie@esante.com');
SET @user_id_radiologie = (SELECT user_id FROM users WHERE email = 'lab_radiologie@esante.com');

-- Si les utilisateurs n'existent pas, les créer
INSERT IGNORE INTO users (email, password_hash, full_name, phone, role, is_active) VALUES
('lab_biologie@esante.com', SHA2('password123', 256), 'Laboratoire Biologie', '+33123456789', 'labo', TRUE),
('lab_radiologie@esante.com', SHA2('password123', 256), 'Laboratoire Radiologie', '+33123456790', 'labo', TRUE);

-- Recalculer les IDs
SET @user_id_biologie = (SELECT user_id FROM users WHERE email = 'lab_biologie@esante.com');
SET @user_id_radiologie = (SELECT user_id FROM users WHERE email = 'lab_radiologie@esante.com');

-- Créer les laboratoires manquants avec les bons IDs
INSERT IGNORE INTO laboratories (laboratory_id, user_id, name, phone, email, address, city, postal_code, responsible_person, specialities_covered, is_active) VALUES
(2, @user_id_biologie, 'Laboratoire Central de Biologie Médicale', '+33123456789', 'lab_biologie@esante.com', '123 Rue de la Santé', 'Alger', '16000', 'Dr. Ahmed Saidani', 'Biologie médicale,Biochimie,Hématologie,Microbiologie,Génétique', TRUE),
(3, @user_id_radiologie, 'Centre de Radiologie et Imagerie Médicale', '+33123456790', 'lab_radiologie@esante.com', '456 Avenue du Progrès', 'Alger', '16000', 'Dr. Fatima Benali', 'Radiologie / Imagerie médicale', TRUE);

-- Vérifier les laboratoires restaurés
SELECT '=== LABORATOIRES RESTAURÉS ===' as status;
SELECT laboratory_id, user_id, name, email, is_active FROM laboratories ORDER BY laboratory_id;

-- Vérifier les assignations après restauration
SELECT '=== ASSIGNATIONS SPÉCIALITÉS-LABORATOIRES ===' as status;
SELECT s.speciality_id, s.name, s.laboratory_assignment, l.name as lab_name 
FROM specialities s
LEFT JOIN laboratories l ON s.laboratory_assignment = l.laboratory_id
WHERE s.laboratory_assignment IS NOT NULL
ORDER BY s.laboratory_assignment, s.name;
