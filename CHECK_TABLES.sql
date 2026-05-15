-- =====================================================
-- SCRIPT DE VÉRIFICATION DES TABLES
-- Vérifier que toutes les tables nécessaires existent
-- =====================================================

-- Vérifier les colonnes de access_requests
DESCRIBE access_requests;

-- Vérifier les colonnes de access_permissions
DESCRIBE access_permissions;

-- Vérifier les colonnes de access_logs
DESCRIBE access_logs;

-- Vérifier les colonnes de notifications
DESCRIBE notifications;

-- Vérifier les données existantes
SELECT * FROM access_requests ORDER BY request_id DESC LIMIT 5;
SELECT * FROM access_permissions ORDER BY permission_id DESC LIMIT 5;
SELECT * FROM access_logs ORDER BY log_id DESC LIMIT 5;
SELECT * FROM notifications WHERE notification_type IN ('access_request', 'access_approved', 'access_rejected') ORDER BY notification_id DESC LIMIT 5;
