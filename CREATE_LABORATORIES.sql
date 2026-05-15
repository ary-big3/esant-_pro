-- =====================================================
-- CRÉER LES LABORATOIRES DE BASE
-- E-Santé - Plateforme Nationale de Santé Numérique
-- =====================================================

USE esante_db;

-- Créer les utilisateurs pour les laboratoires
INSERT INTO users (email, password_hash, full_name, phone, role, is_active) VALUES
('lab_biologie@esante.com', SHA2('password123', 256), 'Laboratoire Biologie', '+33123456789', 'labo', TRUE),
('lab_radiologie@esante.com', SHA2('password123', 256), 'Laboratoire Radiologie', '+33123456790', 'labo', TRUE),
('lab_anatomie@esante.com', SHA2('password123', 256), 'Laboratoire Anatomopathologie', '+33123456791', 'labo', TRUE);

-- Récupérer les IDs des utilisateurs
SET @user_id_biologie = (SELECT MAX(user_id) FROM users WHERE email = 'lab_biologie@esante.com');
SET @user_id_radiologie = (SELECT MAX(user_id) FROM users WHERE email = 'lab_radiologie@esante.com');
SET @user_id_anatomie = (SELECT MAX(user_id) FROM users WHERE email = 'lab_anatomie@esante.com');

-- Créer les laboratoires
INSERT INTO laboratories (user_id, name, phone, email, address, city, postal_code, responsible_person, specialities_covered, is_active) VALUES
(@user_id_biologie, 'Laboratoire Central de Biologie Médicale', '+33123456789', 'lab_biologie@esante.com', '123 Rue de la Santé', 'Alger', '16000', 'Dr. Ahmed Saidani', 'Biologie médicale,Biochimie,Hématologie,Microbiologie,Génétique', TRUE),
(@user_id_radiologie, 'Centre de Radiologie et Imagerie Médicale', '+33123456790', 'lab_radiologie@esante.com', '456 Avenue du Progrès', 'Alger', '16000', 'Dr. Fatima Benali', 'Radiologie / Imagerie médicale', TRUE),
(@user_id_anatomie, 'Laboratoire d\'Anatomopathologie', '+33123456791', 'lab_anatomie@esante.com', '789 Boulevard de la Science', 'Alger', '16000', 'Dr. Karim Medjahed', 'Anatomopathologie,Oncologie', TRUE);

-- Vérifier les laboratoires créés
SELECT 'Laboratoires créés:' as status;
SELECT laboratory_id, name, email, is_active FROM laboratories;

-- Assigner les spécialités aux laboratoires
SET @lab_id_bio = (SELECT laboratory_id FROM laboratories WHERE name LIKE '%Biologie%' LIMIT 1);
SET @lab_id_radio = (SELECT laboratory_id FROM laboratories WHERE name LIKE '%Radiologie%' LIMIT 1);
SET @lab_id_anat = (SELECT laboratory_id FROM laboratories WHERE name LIKE '%Anatomopathologie%' LIMIT 1);

-- Afficher les IDs assignés
SELECT 'IDs de laboratoires assignés:' as status;
SELECT @lab_id_bio as bio_id, @lab_id_radio as radio_id, @lab_id_anat as anat_id;

-- Assigner les spécialités biologiques
UPDATE specialities SET laboratory_assignment = @lab_id_bio 
WHERE name IN ('Biologie médicale', 'Biochimie', 'Hématologie', 'Microbiologie', 'Génétique')
  AND @lab_id_bio IS NOT NULL;

-- Assigner les spécialités radiologiques
UPDATE specialities SET laboratory_assignment = @lab_id_radio 
WHERE name IN ('Radiologie / Imagerie médicale')
  AND @lab_id_radio IS NOT NULL;

-- Assigner les spécialités anatomopathologiques
UPDATE specialities SET laboratory_assignment = @lab_id_anat 
WHERE name IN ('Anatomopathologie', 'Oncologie')
  AND @lab_id_anat IS NOT NULL;

-- Afficher les associations finales
SELECT 'Associations spécialités-laboratoires:' as status;
SELECT s.speciality_id, s.name as speciality_name, s.laboratory_assignment, l.name as laboratory_name 
FROM specialities s
LEFT JOIN laboratories l ON s.laboratory_assignment = l.laboratory_id
WHERE s.laboratory_assignment IS NOT NULL
ORDER BY l.name, s.name;
