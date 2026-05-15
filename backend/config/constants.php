<?php
/**
 * Constantes de l'application
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

// Configuration de l'API
define('API_VERSION', '1.0.0');
define('API_BASE_URL', 'http://localhost/esante/backend/public');
define('FRONTEND_BASE_URL', '*'); // Permet tous les origines en développement

// Configuration JWT
define('JWT_SECRET_KEY', 'esante_jwt_secret_key_2026_v1_super_secure');
define('JWT_ALGORITHM', 'HS256');
define('JWT_EXPIRY', 86400); // 24 heures en secondes

// Rôles utilisateurs
define('ROLE_PATIENT', 'patient');
define('ROLE_MEDECIN', 'medecin');
define('ROLE_INFIRMIERE', 'infirmiere');
define('ROLE_LABORATOIRE', 'laboratoire');
define('ROLE_ADMIN', 'admin');
define('ROLE_MINISTERE', 'ministere');

// Permissions d'accès
define('PERMISSION_VIEW_ONLY', 'view_only');
define('PERMISSION_VIEW_DOWNLOAD', 'view_and_download');
define('PERMISSION_FULL_ACCESS', 'full_access');

// Statuts
define('STATUS_ACTIVE', 'active');
define('STATUS_INACTIVE', 'inactive');
define('STATUS_PENDING', 'pending');
define('STATUS_COMPLETED', 'completed');
define('STATUS_CANCELLED', 'cancelled');

// Statuts de consultation
define('CONSULTATION_COMPLETED', 'completed');
define('CONSULTATION_PENDING', 'pending');
define('CONSULTATION_CANCELLED', 'cancelled');

// Statuts d'examen
define('EXAM_STATUS_PENDING', 'pending');
define('EXAM_STATUS_IN_PROGRESS', 'in_progress');
define('EXAM_STATUS_COMPLETED', 'completed');
define('EXAM_STATUS_CANCELLED', 'cancelled');

// Types de résultats
define('RESULT_NORMAL', 'normal');
define('RESULT_ABNORMAL', 'abnormal');
define('RESULT_TO_VERIFY', 'to_verify');

// Niveaux d'urgence
define('URGENCY_NORMAL', 'normal');
define('URGENCY_URGENT', 'urgent');
define('URGENCY_VERY_URGENT', 'tres_urgent');

// Statuts de prescription
define('PRESCRIPTION_ACTIVE', 'active');
define('PRESCRIPTION_EXPIRED', 'expired');
define('PRESCRIPTION_COMPLETED', 'completed');
define('PRESCRIPTION_CANCELLED', 'cancelled');

// Types de documents
define('DOCUMENT_PRESCRIPTION', 'prescription');
define('DOCUMENT_EXAM', 'examen');
define('DOCUMENT_MEDICAL_REPORT', 'rapport_medical');
define('DOCUMENT_IMAGING', 'imagerie');
define('DOCUMENT_ANALYSIS', 'analyse');
define('DOCUMENT_OTHER', 'autre');

// Limites par défaut
define('DEFAULT_PAGE_SIZE', 20);
define('MAX_PAGE_SIZE', 100);
define('DEFAULT_TIMEOUT', 300);

// Expressions régulières
define('EMAIL_REGEX', '/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/');
define('PHONE_REGEX', '/^[+]?[0-9]{7,15}$/');
define('PASSWORD_MIN_LENGTH', 8);

// Messages de réponse
define('MSG_SUCCESS', 'Opération réussie');
define('MSG_ERROR', 'Une erreur s\'est produite');
define('MSG_UNAUTHORIZED', 'Non autorisé');
define('MSG_FORBIDDEN', 'Accès interdit');
define('MSG_NOT_FOUND', 'Ressource non trouvée');
define('MSG_INVALID_INPUT', 'Données invalides');
define('MSG_CONFLICT', 'Conflit de ressource');

// Codes HTTP
define('HTTP_OK', 200);
define('HTTP_CREATED', 201);
define('HTTP_BAD_REQUEST', 400);
define('HTTP_UNAUTHORIZED', 401);
define('HTTP_FORBIDDEN', 403);
define('HTTP_NOT_FOUND', 404);
define('HTTP_CONFLICT', 409);
define('HTTP_SERVER_ERROR', 500);
?>
