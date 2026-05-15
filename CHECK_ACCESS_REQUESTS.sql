-- =====================================================
-- Vérification de la table access_requests
-- =====================================================

-- 1. Voir TOUTES les demandes d'accès
SELECT 
    ar.request_id,
    ar.patient_id,
    p.first_name as patient_first_name,
    p.last_name as patient_last_name,
    ar.doctor_id,
    d.first_name as doctor_first_name,
    d.last_name as doctor_last_name,
    ar.requester_user_id,
    u.full_name as requester_name,
    ar.reason_for_access,
    ar.permission_type,
    ar.status,
    ar.requested_at,
    ar.responded_at,
    ar.response_reason
FROM access_requests ar
LEFT JOIN patients p ON ar.patient_id = p.patient_id
LEFT JOIN doctors d ON ar.doctor_id = d.doctor_id
LEFT JOIN users u ON ar.requester_user_id = u.user_id
ORDER BY ar.requested_at DESC;

-- 2. Compter le nombre de demandes par statut
SELECT status, COUNT(*) as count FROM access_requests GROUP BY status;

-- 3. Vérifier s'il y a des demandes en attente
SELECT * FROM access_requests WHERE status = 'pending' ORDER BY requested_at DESC;

-- 4. Voir les permissions créées suite aux approbations
SELECT 
    ap.permission_id,
    ap.patient_id,
    p.first_name as patient_name,
    ap.authorized_user_id,
    u.full_name as authorized_name,
    ap.permission_type,
    ap.granted_date,
    ap.expiry_date,
    ap.is_revoked
FROM access_permissions ap
LEFT JOIN patients p ON ap.patient_id = p.patient_id
LEFT JOIN users u ON ap.authorized_user_id = u.user_id
ORDER BY ap.granted_date DESC;

-- 5. Vérifier la structure de la table
DESCRIBE access_requests;
DESCRIBE access_permissions;
