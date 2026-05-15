-- =====================================================
-- VÉRIFIER ET CORRIGER LES LABORATOIRES
-- =====================================================

USE esante_db;

-- 1. Vérifier les laboratoires existants
SELECT '=== LABORATOIRES ACTUELS ===' as status;
SELECT laboratory_id, user_id, name, email, is_active FROM laboratories;

-- 2. Vérifier les spécialités et leurs assignations
SELECT '=== SPÉCIALITÉS ET ASSIGNATIONS ===' as status;
SELECT s.speciality_id, s.name, s.laboratory_assignment, l.name as lab_name 
FROM specialities s
LEFT JOIN laboratories l ON s.laboratory_assignment = l.laboratory_id
ORDER BY s.name;

-- 3. Vérifier les exams récents avec leurs laboratory_id
SELECT '=== EXAMENS RÉCENTS ===' as status;
SELECT e.exam_id, e.patient_id, e.exam_type, e.speciality_id, e.laboratory_id, 
       s.name as speciality_name, l.name as lab_name
FROM exams e
LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
LEFT JOIN laboratories l ON e.laboratory_id = l.laboratory_id
ORDER BY e.created_at DESC
LIMIT 10;

-- 4. Vérifier la contrainte de clé étrangère
SELECT '=== VÉRIFIER LES VIOLATIONS DE CLÉS ÉTRANGÈRES ===' as status;
SELECT 'Examens avec laboratory_id qui n\'existe pas:' as check_type;
SELECT e.exam_id, e.laboratory_id FROM exams e
WHERE e.laboratory_id IS NOT NULL 
AND e.laboratory_id NOT IN (SELECT laboratory_id FROM laboratories);

-- 5. Si des problèmes, fixer les examens orphelins
-- (Remplacer les laboratory_id invalides par NULL)
UPDATE exams 
SET laboratory_id = NULL
WHERE laboratory_id IS NOT NULL 
AND laboratory_id NOT IN (SELECT laboratory_id FROM laboratories);

SELECT '=== CORRECTION APPLIQUÉE ===' as status;
SELECT CONCAT('Examens fixés: ', ROW_COUNT()) as result;
