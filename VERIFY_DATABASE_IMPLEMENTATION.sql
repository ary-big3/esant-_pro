-- =====================================================
-- VÉRIFICATION EN BASE DE DONNÉES
-- Système de Demandes d'Accès aux Dossiers Patients
-- =====================================================

-- =====================================================
-- 1. VÉrifier que les demandes d'accès existent
-- =====================================================
SELECT 
  ar.request_id,
  ar.patient_id,
  p.first_name as patient_name,
  ar.doctor_id,
  d.first_name as doctor_name,
  ar.reason_for_access,
  ar.permission_type,
  ar.status,
  ar.requested_at,
  ar.responded_at,
  ar.response_reason
FROM access_requests ar
LEFT JOIN patients p ON ar.patient_id = p.patient_id
LEFT JOIN doctors d ON ar.doctor_id = d.doctor_id
ORDER BY ar.request_id DESC
LIMIT 20;

-- =====================================================
-- 2. Vérifier les permissions d'accès accordées
-- =====================================================
SELECT 
  ap.permission_id,
  ap.patient_id,
  p.first_name as patient_name,
  ap.authorized_user_id,
  u.full_name as doctor_name,
  ap.permission_type,
  ap.granted_date,
  ap.expiry_date,
  ap.is_revoked,
  ap.revoked_date
FROM access_permissions ap
LEFT JOIN patients p ON ap.patient_id = p.patient_id
LEFT JOIN users u ON ap.authorized_user_id = u.user_id
ORDER BY ap.permission_id DESC
LIMIT 20;

-- =====================================================
-- 3. Vérifier les logs d'accès
-- =====================================================
SELECT 
  al.log_id,
  u.full_name as user_who_accessed,
  u.role,
  al.accessed_patient_id,
  p.first_name as patient_name,
  al.action_type,
  al.resource_type,
  al.access_status,
  al.ip_address,
  al.user_agent,
  al.access_timestamp
FROM access_logs al
LEFT JOIN users u ON al.user_id = u.user_id
LEFT JOIN patients p ON al.accessed_patient_id = p.patient_id
WHERE al.accessed_patient_id IS NOT NULL
ORDER BY al.access_timestamp DESC
LIMIT 30;

-- =====================================================
-- 4. Vérifier les notifications d'accès
-- =====================================================
SELECT 
  n.notification_id,
  u.full_name as recipient,
  n.notification_type,
  n.title,
  n.message,
  n.is_read,
  n.read_at,
  n.created_at
FROM notifications n
LEFT JOIN users u ON n.user_id = u.user_id
WHERE n.notification_type IN ('access_request', 'access_approved', 'access_rejected')
ORDER BY n.notification_id DESC
LIMIT 20;

-- =====================================================
-- 5. Résumé statistique par patient
-- =====================================================
SELECT 
  p.patient_id,
  CONCAT(p.first_name, ' ', p.last_name) as patient_name,
  COUNT(CASE WHEN ar.status = 'pending' THEN 1 END) as pending_requests,
  COUNT(CASE WHEN ar.status = 'approved' THEN 1 END) as approved_requests,
  COUNT(CASE WHEN ar.status = 'rejected' THEN 1 END) as rejected_requests,
  COUNT(ap.permission_id) as active_permissions,
  COUNT(CASE WHEN ap.is_revoked = TRUE THEN 1 END) as revoked_permissions
FROM patients p
LEFT JOIN access_requests ar ON p.patient_id = ar.patient_id
LEFT JOIN access_permissions ap ON p.patient_id = ap.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY p.patient_id;

-- =====================================================
-- 6. Résumé statistique par médecin
-- =====================================================
SELECT 
  d.doctor_id,
  CONCAT(d.first_name, ' ', d.last_name) as doctor_name,
  COUNT(CASE WHEN ar.status = 'pending' THEN 1 END) as pending_requests,
  COUNT(CASE WHEN ar.status = 'approved' THEN 1 END) as approved_requests,
  COUNT(CASE WHEN ar.status = 'rejected' THEN 1 END) as rejected_requests,
  COUNT(ap.permission_id) as active_permissions
FROM doctors d
LEFT JOIN access_requests ar ON d.doctor_id = ar.doctor_id
LEFT JOIN access_permissions ap ON ap.authorized_user_id = d.user_id
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY d.doctor_id;

-- =====================================================
-- 7. Vérifier les demandes en attente (IMPORTANT)
-- =====================================================
SELECT 
  ar.request_id,
  CONCAT(p.first_name, ' ', p.last_name) as patient,
  CONCAT(d.first_name, ' ', d.last_name) as doctor,
  ar.reason_for_access,
  ar.requested_at,
  TIMESTAMPDIFF(HOUR, ar.requested_at, NOW()) as hours_pending
FROM access_requests ar
JOIN patients p ON ar.patient_id = p.patient_id
JOIN doctors d ON ar.doctor_id = d.doctor_id
WHERE ar.status = 'pending'
ORDER BY ar.requested_at DESC;

-- =====================================================
-- 8. Vérifier les permissions expirées
-- =====================================================
SELECT 
  ap.permission_id,
  CONCAT(p.first_name, ' ', p.last_name) as patient,
  CONCAT(u.full_name) as authorized_user,
  ap.expiry_date,
  DATEDIFF(ap.expiry_date, NOW()) as days_remaining,
  CASE 
    WHEN ap.expiry_date < NOW() THEN 'EXPIRÉ'
    WHEN ap.expiry_date < DATE_ADD(NOW(), INTERVAL 7 DAY) THEN 'EXPIRE BIENTÔT'
    ELSE 'ACTIF'
  END as status
FROM access_permissions ap
LEFT JOIN patients p ON ap.patient_id = p.patient_id
LEFT JOIN users u ON ap.authorized_user_id = u.user_id
WHERE ap.is_revoked = FALSE
ORDER BY ap.expiry_date ASC;

-- =====================================================
-- 9. Vérifier les accès non autorisés (tentatives bloquées)
-- =====================================================
SELECT 
  COUNT(*) as denied_attempts,
  u.full_name as user,
  u.role,
  al.ip_address,
  MIN(al.access_timestamp) as first_attempt,
  MAX(al.access_timestamp) as last_attempt
FROM access_logs al
LEFT JOIN users u ON al.user_id = u.user_id
WHERE al.access_status = 'denied'
GROUP BY al.user_id, u.full_name, u.role, al.ip_address
ORDER BY denied_attempts DESC;

-- =====================================================
-- 10. Audit trail complet pour un patient spécifique
-- =====================================================
-- Remplacer 1 par l'ID du patient
SELECT 
  ar.request_id,
  'DEMANDE' as action_type,
  CONCAT(d.first_name, ' ', d.last_name) as initiated_by,
  ar.reason_for_access as details,
  ar.status as result,
  ar.requested_at as timestamp
FROM access_requests ar
LEFT JOIN doctors d ON ar.doctor_id = d.doctor_id
WHERE ar.patient_id = 1
UNION ALL
SELECT 
  al.log_id,
  al.action_type,
  u.full_name,
  CONCAT('Resource: ', al.resource_type),
  al.access_status,
  al.access_timestamp
FROM access_logs al
LEFT JOIN users u ON al.user_id = u.user_id
WHERE al.accessed_patient_id = 1
UNION ALL
SELECT 
  n.notification_id,
  n.notification_type,
  u.full_name,
  n.message,
  CASE WHEN n.is_read THEN 'LU' ELSE 'NON LU' END,
  n.created_at
FROM notifications n
LEFT JOIN users u ON n.user_id = u.user_id
WHERE n.related_patient_id = 1
ORDER BY timestamp DESC;

-- =====================================================
-- 11. Vérification de l'intégrité des données
-- =====================================================

-- Vérifier s'il y a des demandes approuvées sans permission
SELECT ar.request_id, ar.patient_id, ar.doctor_id
FROM access_requests ar
WHERE ar.status = 'approved'
AND NOT EXISTS (
  SELECT 1 FROM access_permissions ap 
  WHERE ap.patient_id = ar.patient_id 
  AND ap.authorized_user_id = ar.requester_user_id
);

-- =====================================================
-- NOTES IMPORTANTES
-- =====================================================
/*
- Toutes les demandes doivent être en `access_requests`
- Toutes les permissions accordées doivent être en `access_permissions`
- Tous les accès doivent être loggés en `access_logs`
- Toutes les notifications doivent être en `notifications`

Chaque demande approuvée DOIT créer une ligne dans access_permissions
Chaque accès au dossier DOIT être enregistré en access_logs

ZÉRO données fictives - Tout doit être présent en BD !
*/
