-- =====================================================
-- TESTER LA PRESCRIPTION ET LA RÉCUPÉRATION DES EXAMENS
-- =====================================================

USE esante_db;

-- 1. Vérifier que l'examen a été créé
SELECT '=== EXAMENS APRÈS PRESCRIPTION ===' as status;
SELECT e.exam_id, e.patient_id, e.exam_type, e.speciality_id, e.laboratory_id, 
       e.exam_status, e.created_at,
       s.name as speciality_name, l.name as lab_name
FROM exams e
LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
LEFT JOIN laboratories l ON e.laboratory_id = l.laboratory_id
ORDER BY e.created_at DESC
LIMIT 5;

-- 2. Vérifier les notifications envoyées
SELECT '=== NOTIFICATIONS PATIENT ===' as status;
SELECT n.notification_id, n.user_id, n.notification_type, n.title, n.message, 
       n.created_at, n.related_exam_id
FROM notifications n
WHERE n.notification_type = 'exam_requested'
ORDER BY n.created_at DESC
LIMIT 5;

-- 3. Simuler l'envoi de résultats par le labo (créer un document)
SELECT '=== CRÉER UN DOCUMENT POUR LES RÉSULTATS ===' as status;

-- Récupérer un examen complété ou en attente
SET @exam_id = (SELECT exam_id FROM exams LIMIT 1);
SET @patient_id = (SELECT patient_id FROM exams WHERE exam_id = @exam_id);
SET @user_id = (SELECT user_id FROM users WHERE role = 'labo' LIMIT 1);

-- Créer un document de résultats d'examen
INSERT INTO medical_documents (
    patient_id, 
    document_type, 
    document_title, 
    document_description, 
    file_path, 
    uploaded_by,
    related_exam_id,
    is_available_for_download
) VALUES (
    @patient_id,
    'examen',
    CONCAT('Résultats examen - ', (SELECT exam_type FROM exams WHERE exam_id = @exam_id)),
    'Résultats d\'examen médical',
    CONCAT('/documents/exam_', @exam_id, '.pdf'),
    @user_id,
    @exam_id,
    TRUE
);

SELECT '=== DOCUMENTS CRÉÉS ===' as status;
SELECT d.document_id, d.patient_id, d.document_type, d.document_title, 
       d.uploaded_by, d.upload_date, d.related_exam_id
FROM medical_documents d
ORDER BY d.upload_date DESC
LIMIT 5;
