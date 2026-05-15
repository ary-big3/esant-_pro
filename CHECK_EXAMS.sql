-- Vérifier les examens prescrits
USE esante_db;

SELECT 'Examens prescrits (derniers):' as status;
SELECT e.exam_id, e.exam_type, e.patient_id, e.doctor_id, e.laboratory_id, e.speciality_id, 
       s.name as speciality_name, l.name as laboratory_name, p.first_name as patient_name,
       e.exam_status, e.urgency_level, e.exam_date, e.created_at
FROM exams e
LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
LEFT JOIN laboratories l ON e.laboratory_id = l.laboratory_id
LEFT JOIN patients p ON e.patient_id = p.patient_id
ORDER BY e.created_at DESC
LIMIT 10;

SELECT 'Total examens:' as status;
SELECT COUNT(*) as total_exams FROM exams;

SELECT 'Examens par laboratoire:' as status;
SELECT l.laboratory_id, l.name, COUNT(e.exam_id) as exam_count
FROM laboratories l
LEFT JOIN exams e ON l.laboratory_id = e.laboratory_id
GROUP BY l.laboratory_id, l.name;
