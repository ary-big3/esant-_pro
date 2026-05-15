-- =====================================================
-- ASSIGNER TOUS LES LABORATOIRES AUX SPÉCIALITÉS
-- E-Santé - Plateforme Nationale de Santé Numérique
-- =====================================================

USE esante_db;

-- Récupérer les IDs des laboratoires
SET @lab_biologie = (SELECT laboratory_id FROM laboratories WHERE name LIKE '%Biologie%' LIMIT 1);
SET @lab_radiologie = (SELECT laboratory_id FROM laboratories WHERE name LIKE '%Radiologie%' LIMIT 1);
SET @lab_anatomopath = (SELECT laboratory_id FROM laboratories WHERE name LIKE '%Anatomopath%' LIMIT 1);

SELECT 'Laboratoires:' as status;
SELECT @lab_biologie as lab_biologie, @lab_radiologie as lab_radiologie, @lab_anatomopath as lab_anatomopath;

-- Assigner les spécialités biologiques
UPDATE specialities SET laboratory_assignment = @lab_biologie 
WHERE name IN ('Biologie médicale', 'Biochimie', 'Hématologie', 'Microbiologie', 'Génétique', 'Virologie', 'Parasitologie', 'Bactériologie', 'Sérologie');

-- Assigner les spécialités radiologiques
UPDATE specialities SET laboratory_assignment = @lab_radiologie 
WHERE name IN ('Radiologie / Imagerie médicale', 'Radiologie', 'Imagerie', 'Scanner', 'IRM', 'Échographie', 'Fluoroscopie');

-- Assigner les spécialités d'anatomopathologie
UPDATE specialities SET laboratory_assignment = @lab_anatomopath 
WHERE name IN ('Anatomopathologie', 'Anatomo-pathologie', 'Pathologie', 'Cytologie', 'Histologie');

-- Afficher les résultats
SELECT 'Spécialités assignées au laboratoire:' as status;
SELECT s.speciality_id, s.name as speciality_name, l.laboratory_id, l.name as laboratory_name
FROM specialities s
LEFT JOIN laboratories l ON s.laboratory_assignment = l.laboratory_id
WHERE s.laboratory_assignment IS NOT NULL
ORDER BY l.name, s.name;

SELECT 'Spécialités sans laboratoire assigné:' as status;
SELECT speciality_id, name 
FROM specialities 
WHERE laboratory_assignment IS NULL 
ORDER BY name;

-- Mettre à jour les examens existants avec le laboratory_id correct
UPDATE exams e
SET e.laboratory_id = (
    SELECT s.laboratory_assignment 
    FROM specialities s 
    WHERE s.speciality_id = e.speciality_id 
    LIMIT 1
)
WHERE e.laboratory_id IS NULL AND e.speciality_id IN (
    SELECT speciality_id FROM specialities WHERE laboratory_assignment IS NOT NULL
);

SELECT 'Examens mis à jour:' as status;
SELECT e.exam_id, e.exam_type, s.name as speciality_name, l.name as laboratory_name, e.exam_status
FROM exams e
LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
LEFT JOIN laboratories l ON e.laboratory_id = l.laboratory_id
ORDER BY e.created_at DESC;
