-- =====================================================
-- DIAGNOSTIC: Vérifier l'état des données vitales
-- =====================================================

-- 1. Vérifier les utilisateurs infirmiers
SELECT '=== USERS (Rôle: Infirmière) ===' as '';
SELECT user_id, email, full_name, role FROM users WHERE role = 'infirmiere';

-- 2. Vérifier les infirmières en base
SELECT '=== NURSES ===' as '';
SELECT nurse_id, user_id, first_name, last_name FROM nurses;

-- 3. Vérifier les patients
SELECT '=== PATIENTS ===' as '';
SELECT patient_id, user_id, first_name, last_name FROM patients LIMIT 5;

-- 4. Vérifier les vitales enregistrées
SELECT '=== VITAL_SIGNS (Tous les enregistrements) ===' as '';
SELECT 
    vs.vital_sign_id,
    vs.patient_id,
    vs.nurse_id,
    vs.temperature_celsius as temp,
    vs.systolic_pressure as TA_sys,
    vs.measurement_date,
    p.first_name as patient_name,
    n.first_name as nurse_name,
    u_nurse.full_name as nurse_full_name
FROM vital_signs vs
LEFT JOIN patients p ON vs.patient_id = p.patient_id
LEFT JOIN nurses n ON vs.nurse_id = n.nurse_id
LEFT JOIN users u_nurse ON n.user_id = u_nurse.user_id
ORDER BY vs.measurement_date DESC;

-- 5. Compter les vitales par patient
SELECT '=== COUNT VITALES PAR PATIENT ===' as '';
SELECT 
    patient_id, 
    COUNT(*) as total_vitals,
    MAX(measurement_date) as derniere_vitale
FROM vital_signs
GROUP BY patient_id;

-- 6. Vérifier les contraintes FK
SELECT '=== STRUCTURE TABLE vital_signs ===' as '';
SHOW CREATE TABLE vital_signs\G

-- 7. Vérifier les vitales d'un patient spécifique (remplacer par ID réel)
SELECT '=== VITALES POUR PATIENT ID=1 (EXEMPLE) ===' as '';
SELECT 
    vital_sign_id,
    patient_id,
    nurse_id,
    temperature_celsius,
    systolic_pressure,
    diastolic_pressure,
    pulse_bpm,
    respiratory_rate,
    oxygen_saturation,
    weight_kg,
    height_cm,
    measurement_date,
    notes
FROM vital_signs
WHERE patient_id = 1
ORDER BY measurement_date DESC
LIMIT 20;

-- =====================================================
-- INSTRUCTIONS
-- =====================================================
-- 1. Exécutez ce script dans phpMyAdmin
-- 2. Notez les résultats du query 4 (VITAL_SIGNS)
-- 3. Vérifiez que nurse_id ne soit pas NULL
-- 4. Vérifiez que patient_id corresponde à un patient existant
-- 5. Envoyez les résultats pour diagnostic
-- =====================================================
