-- =====================================================
-- ASSIGNER LES SPÉCIALITÉS AUX LABORATOIRES
-- E-Santé - Plateforme Nationale de Santé Numérique
-- =====================================================

USE esante_db;

-- Vérifier les laboratoires existants
SELECT 'Laboratoires existants:' as status;
SELECT laboratory_id, name FROM laboratories LIMIT 10;

-- Vérifier les spécialités
SELECT 'Spécialités existantes (top 5):' as status;
SELECT speciality_id, name FROM specialities LIMIT 5;

-- Si un laboratoire existe, assigner des spécialités
SET @lab_id = (SELECT laboratory_id FROM laboratories LIMIT 1);

-- Afficher le laboratoire assigné
SELECT 'Laboratoire pour assignation:' as status;
SELECT laboratory_id, name FROM laboratories WHERE laboratory_id = @lab_id;

-- Assigner les spécialités biologiques au premier laboratoire trouvé
UPDATE specialities SET laboratory_assignment = @lab_id 
WHERE name IN ('Biologie médicale', 'Biochimie', 'Hématologie', 'Microbiologie', 'Génétique')
  AND @lab_id IS NOT NULL;

-- Afficher les spécialités avec laboratoire assigné
SELECT 'Spécialités avec laboratoire assigné:' as status;
SELECT s.speciality_id, s.name as speciality_name, s.laboratory_assignment, l.name as laboratory_name 
FROM specialities s
LEFT JOIN laboratories l ON s.laboratory_assignment = l.laboratory_id
WHERE s.laboratory_assignment IS NOT NULL
ORDER BY s.name;

