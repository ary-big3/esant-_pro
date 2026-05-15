-- =====================================================
-- NETTOYER LES DOUBLONS DE SPÉCIALITÉS
-- E-Santé - Plateforme Nationale de Santé Numérique
-- =====================================================

USE esante_db;

-- Récupérer les laboratoires
SET @lab_biologie = (SELECT laboratory_id FROM laboratories WHERE name LIKE '%Biologie%' LIMIT 1);
SET @lab_radiologie = (SELECT laboratory_id FROM laboratories WHERE name LIKE '%Radiologie%' LIMIT 1);
SET @lab_anatomopath = (SELECT laboratory_id FROM laboratories WHERE name LIKE '%Anatomopath%' LIMIT 1);

-- Assigner les laboratoires à TOUTES les spécialités (y compris les anciens IDs)
UPDATE specialities SET laboratory_assignment = @lab_biologie 
WHERE name IN (
    'Biologie médicale', 'Biochimie', 'Hématologie', 'Microbiologie', 'Génétique'
);

UPDATE specialities SET laboratory_assignment = @lab_radiologie 
WHERE name IN (
    'Radiologie / Imagerie médicale', 'Radiologie', 'Imagerie'
);

UPDATE specialities SET laboratory_assignment = @lab_anatomopath 
WHERE name IN (
    'Anatomopathologie', 'Oncologie'
);

-- Afficher toutes les spécialités avec laboratoires assignés
SELECT 'Toutes les spécialités assignées:' as status;
SELECT s.speciality_id, s.name as speciality_name, s.laboratory_assignment, l.name as laboratory_name
FROM specialities s
LEFT JOIN laboratories l ON s.laboratory_assignment = l.laboratory_id
WHERE s.laboratory_assignment IS NOT NULL
ORDER BY l.name, s.name;

-- Mettre à jour les examens avec les bons laboratoires
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

SELECT 'EXAMENS FINAUX:' as status;
SELECT 
    e.exam_id, 
    e.exam_type, 
    s.speciality_id,
    s.name as speciality_name, 
    e.laboratory_id,
    l.name as laboratory_name, 
    e.exam_status,
    p.first_name as patient
FROM exams e
LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
LEFT JOIN laboratories l ON e.laboratory_id = l.laboratory_id
LEFT JOIN patients p ON e.patient_id = p.patient_id
ORDER BY e.exam_id DESC;
