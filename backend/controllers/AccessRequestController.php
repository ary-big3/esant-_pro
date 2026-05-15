<?php
/**
 * Contrôleur Demandes d'Accès
 * E-Santé - Gestion des demandes d'accès au dossier médical
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class AccessRequestController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Créer une demande d'accès au dossier du patient
     */
    public function requestAccess() {
        try {
            $user = AuthMiddleware::verifyAuth();
            // Vérifier que c'est un médecin
            if ($user['role'] !== ROLE_MEDECIN) {
                Response::forbidden('Seuls les médecins peuvent demander l\'accès');
            }

            $input = json_decode(file_get_contents('php://input'), true);

            $validator = new Validator();
            $validator->validateRequired($input['patient_id'] ?? null, 'patient_id');
            $validator->validateRequired($input['reason_for_access'] ?? $input['reason'] ?? null, 'reason_for_access');

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', $validator->getErrors());
            }

            $patientId = $input['patient_id'];
            $reasonForAccess = $input['reason_for_access'] ?? $input['reason'];
            $permissionType = $input['permission_type'] ?? 'view_only';

            // Récupérer le doctor_id du médecin
            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Médecin non trouvé');
            }
            $doctorId = $result->fetch_assoc()['doctor_id'];
            $stmt->close();

            // Vérifier que le patient existe
            $stmt = $this->db->prepare('SELECT patient_id, user_id FROM patients WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Patient non trouvé');
            }
            $patientData = $result->fetch_assoc();
            $patientUserId = $patientData['user_id'];
            $stmt->close();

            // Vérifier s'il n'existe pas déjà une demande en attente
            $stmt = $this->db->prepare(
                'SELECT request_id FROM access_requests 
                 WHERE patient_id = ? AND doctor_id = ? AND status = "pending"'
            );
            $stmt->bind_param('ii', $patientId, $doctorId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                Response::badRequest('Une demande d\'accès est déjà en attente pour ce patient');
            }
            $stmt->close();

            // Créer la demande d'accès
            $stmt = $this->db->prepare(
                'INSERT INTO access_requests (patient_id, doctor_id, requester_user_id, reason_for_access, permission_type, status)
                 VALUES (?, ?, ?, ?, ?, "pending")'
            );
            $stmt->bind_param('iiiss', $patientId, $doctorId, $user['user_id'], $reasonForAccess, $permissionType);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la création de la demande');
            }

            $requestId = $this->db->insert_id;
            $stmt->close();

            // Créer une notification pour le patient
            $doctorName = $this->getDoctorName($doctorId);
            $this->createNotification(
                $patientUserId,
                'access_request',
                'Demande d\'accès au dossier',
                'Dr. ' . $doctorName . ' demande l\'accès à votre dossier médical: ' . $reasonForAccess,
                $requestId
            );

            Response::created([
                'request_id' => $requestId,
                'status' => 'pending'
            ], 'Demande d\'accès envoyée au patient');

        } catch (Exception $e) {
            error_log('Access Request Error: ' . $e->getMessage());
            Response::error('Erreur lors de la création de la demande: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les demandes d'accès en attente pour le patient connecté
     */
    public function getMyAccessRequests($page = 1, $limit = 20) {
        try {
            $user = AuthMiddleware::verifyAuth();

            // Récupérer le patient_id si c'est un patient
            if ($user['role'] !== ROLE_PATIENT) {
                Response::forbidden('Seuls les patients peuvent voir leurs demandes');
            }

            $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Profil patient non trouvé');
            }
            $patientId = $result->fetch_assoc()['patient_id'];
            $stmt->close();

            $offset = ($page - 1) * $limit;

            // Compter le total
            $stmt = $this->db->prepare(
                'SELECT COUNT(*) as total FROM access_requests WHERE patient_id = ?'
            );
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les demandes avec les infos du médecin
            $stmt = $this->db->prepare(
                'SELECT ar.request_id, ar.patient_id, ar.reason_for_access, ar.permission_type, 
                         ar.status, ar.requested_at, ar.responded_at, ar.response_reason,
                         d.doctor_id, d.first_name, d.last_name, s.name as speciality_name
                 FROM access_requests ar
                 INNER JOIN doctors d ON ar.doctor_id = d.doctor_id
                 LEFT JOIN specialities s ON d.default_speciality_id = s.speciality_id
                 WHERE ar.patient_id = ?
                 ORDER BY ar.requested_at DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();
            
            $requests = [];
            while ($row = $result->fetch_assoc()) {
                $requests[] = [
                    'request_id' => $row['request_id'],
                    'doctor_id' => $row['doctor_id'],
                    'doctor_name' => $row['first_name'] . ' ' . $row['last_name'],
                    'speciality' => $row['speciality_name'],
                    'reason' => $row['reason_for_access'],
                    'permission_type' => $row['permission_type'],
                    'status' => $row['status'],
                    'requested_at' => $row['requested_at'],
                    'responded_at' => $row['responded_at'],
                    'response_reason' => $row['response_reason']
                ];
            }
            $stmt->close();

            Response::success([
                'requests' => $requests,
                'pagination' => [
                    'current_page' => $page,
                    'total_items' => $total,
                    'per_page' => $limit,
                    'total_pages' => ceil($total / $limit)
                ]
            ], 'Demandes d\'accès récupérées');

        } catch (Exception $e) {
            error_log('Get Access Requests Error: ' . $e->getMessage());
            Response::error('Erreur: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Approuver une demande d'accès (patient)
     */
    public function approveAccessRequest($requestId) {
        try {
            $user = AuthMiddleware::verifyAuth();

            if ($user['role'] !== ROLE_PATIENT) {
                Response::forbidden('Seuls les patients peuvent approuver les demandes');
            }

            // Vérifier que le patient est propriétaire de cette demande
            $stmt = $this->db->prepare(
                'SELECT ar.request_id, ar.patient_id, ar.doctor_id, ar.requester_user_id
                 FROM access_requests ar
                 INNER JOIN patients p ON ar.patient_id = p.patient_id
                 WHERE ar.request_id = ? AND p.user_id = ?'
            );
            $stmt->bind_param('ii', $requestId, $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Demande non trouvée ou non autorisée');
            }
            $requestData = $result->fetch_assoc();
            $patientId = $requestData['patient_id'];
            $doctorUserId = $requestData['requester_user_id'];
            $stmt->close();

            // Marquer la demande comme approuvée
            $approvedAt = date('Y-m-d H:i:s');
            $stmt = $this->db->prepare(
                'UPDATE access_requests SET status = "approved", responded_at = ? WHERE request_id = ?'
            );
            $stmt->bind_param('si', $approvedAt, $requestId);
            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de l\'approbation');
            }
            $stmt->close();

            // Créer une permission d'accès dans la table access_permissions
            $stmt = $this->db->prepare(
                'SELECT permission_type FROM access_requests WHERE request_id = ?'
            );
            $stmt->bind_param('i', $requestId);
            $stmt->execute();
            $result = $stmt->get_result();
            $permissionType = $result->fetch_assoc()['permission_type'];
            $stmt->close();

            $expiryDate = date('Y-m-d H:i:s', strtotime('+1 year'));
            $stmt = $this->db->prepare(
                'INSERT INTO access_permissions (patient_id, authorized_user_id, permission_type, granted_by, expiry_date)
                 VALUES (?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('iisss', $patientId, $doctorUserId, $permissionType, $user['user_id'], $expiryDate);
            $stmt->execute();
            $stmt->close();

            // Créer une notification pour le médecin
            $doctorName = $this->getDoctorName($requestData['doctor_id']);
            $this->createNotification(
                $doctorUserId,
                'access_approved',
                'Accès autorisé ✅',
                'Le patient a autorisé votre accès à son dossier médical',
                $requestId
            );

            // Journaliser l'accès accordé dans access_logs
            $this->logAccess($doctorUserId, $patientId, 'view', 'patient_record', null, 'success');

            Response::success([], 'Demande approuvée avec succès');

        } catch (Exception $e) {
            error_log('Approve Access Request Error: ' . $e->getMessage());
            Response::error('Erreur: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Vérifier si un médecin a accès au dossier d'un patient
     */
    public function checkAccess($patientId, $doctorUserId) {
        try {
            $stmt = $this->db->prepare(
                'SELECT ap.permission_id, ap.permission_type, ap.expiry_date
                 FROM access_permissions ap
                 WHERE ap.patient_id = ? AND ap.authorized_user_id = ? 
                 AND ap.is_revoked = FALSE 
                 AND (ap.expiry_date IS NULL OR ap.expiry_date > NOW())'
            );
            $stmt->bind_param('ii', $patientId, $doctorUserId);
            $stmt->execute();
            $result = $stmt->get_result();
            $stmt->close();
            
            return $result->num_rows > 0 ? $result->fetch_assoc() : null;
        } catch (Exception $e) {
            error_log('Check Access Error: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Journaliser un accès au dossier patient
     */
    private function logAccess($userId, $patientId, $actionType, $resourceType, $resourceId = null, $status = 'success') {
        try {
            $ipAddress = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
            $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
            $timestamp = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare(
                'INSERT INTO access_logs (user_id, accessed_patient_id, action_type, resource_type, resource_id, access_status, ip_address, user_agent, access_timestamp)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            
            $stmt->bind_param(
                'iisssisss',
                $userId,
                $patientId,
                $actionType,
                $resourceType,
                $resourceId,
                $status,
                $ipAddress,
                $userAgent,
                $timestamp
            );
            
            $stmt->execute();
            $stmt->close();
        } catch (Exception $e) {
            error_log('Log Access Error: ' . $e->getMessage());
        }
    }

    /**
     * Rejeter une demande d'accès (patient)
     */
    public function rejectAccessRequest($requestId) {
        try {
            $user = AuthMiddleware::verifyAuth();

            if ($user['role'] !== ROLE_PATIENT) {
                Response::forbidden('Seuls les patients peuvent rejeter les demandes');
            }

            $input = json_decode(file_get_contents('php://input'), true);
            $rejectionReason = $input['reason'] ?? null;

            // Vérifier que le patient est propriétaire de cette demande
            $stmt = $this->db->prepare(
                'SELECT ar.request_id, ar.patient_id, ar.doctor_id, ar.requester_user_id
                 FROM access_requests ar
                 INNER JOIN patients p ON ar.patient_id = p.patient_id
                 WHERE ar.request_id = ? AND p.user_id = ?'
            );
            $stmt->bind_param('ii', $requestId, $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Demande non trouvée ou non autorisée');
            }
            $requestData = $result->fetch_assoc();
            $doctorUserId = $requestData['requester_user_id'];
            $stmt->close();

            // Marquer la demande comme rejetée
            $responseTime = date('Y-m-d H:i:s');
            $stmt = $this->db->prepare(
                'UPDATE access_requests SET status = "rejected", responded_at = ?, response_reason = ? WHERE request_id = ?'
            );
            $stmt->bind_param('ssi', $responseTime, $rejectionReason, $requestId);
            if (!$stmt->execute()) {
                throw new Exception('Erreur lors du rejet');
            }
            $stmt->close();

            // Créer une notification pour le médecin
            $this->createNotification(
                $doctorUserId,
                'access_rejected',
                'Demande refusée',
                'Le patient a refusé votre demande d\'accès au dossier: ' . ($rejectionReason ?? 'Aucune raison fournie'),
                $requestId
            );

            Response::success([], 'Demande rejetée');

        } catch (Exception $e) {
            error_log('Reject Access Request Error: ' . $e->getMessage());
            Response::error('Erreur: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Récupérer le nom du docteur
     */
    private function getDoctorName($doctorId) {
        $stmt = $this->db->prepare('SELECT first_name, last_name FROM doctors WHERE doctor_id = ?');
        $stmt->bind_param('i', $doctorId);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows > 0) {
            $doctor = $result->fetch_assoc();
            $stmt->close();
            return $doctor['first_name'] . ' ' . $doctor['last_name'];
        }
        $stmt->close();
        return 'Médecin';
    }

    /**
     * Créer une notification
     */
    private function createNotification($userId, $type, $title, $message, $requestId = null) {
        try {
            error_log('🔔 [CreateNotification] Création notification pour user_id=' . $userId . ', type=' . $type);
            error_log('🔔 [CreateNotification] Title: ' . $title);
            error_log('🔔 [CreateNotification] Message: ' . $message);
            
            $createdAt = date('Y-m-d H:i:s');
            $stmt = $this->db->prepare(
                'INSERT INTO notifications (user_id, notification_type, title, message, created_at)
                 VALUES (?, ?, ?, ?, ?)'
            );
            
            if (!$stmt) {
                error_log('❌ [CreateNotification] Erreur prepare: ' . $this->db->error);
                return false;
            }
            
            $stmt->bind_param('issss', $userId, $type, $title, $message, $createdAt);
            
            if (!$stmt->execute()) {
                error_log('❌ [CreateNotification] Erreur execute: ' . $stmt->error);
                $stmt->close();
                return false;
            }
            
            error_log('✅ [CreateNotification] Notification créée avec succès');
            $stmt->close();
            return true;
        } catch (Exception $e) {
            error_log('❌ [CreateNotification] Exception: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Vérifier si l'utilisateur courant a accès au dossier d'un patient
     */
    public function hasAccess($patientId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            
            // Les patients ont accès à leur propre dossier
            $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ? AND patient_id = ?');
            $stmt->bind_param('ii', $user['user_id'], $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                $stmt->close();
                Response::success(['has_access' => true, 'reason' => 'own_record'], 'Vous avez accès à votre propre dossier');
            }
            $stmt->close();

            // Vérifier les permissions d'accès valides (non révoquées et non expirées)
            $stmt = $this->db->prepare(
                'SELECT ap.permission_id, ap.permission_type, ap.expiry_date
                 FROM access_permissions ap
                 WHERE ap.patient_id = ? AND ap.authorized_user_id = ? 
                 AND ap.is_revoked = FALSE 
                 AND (ap.expiry_date IS NULL OR ap.expiry_date > NOW())'
            );
            $stmt->bind_param('ii', $patientId, $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $permission = $result->fetch_assoc();
                $stmt->close();
                
                // Journaliser l'accès réussi
                $this->logAccess($user['user_id'], $patientId, 'view', 'patient_record', null, 'success');
                
                Response::success([
                    'has_access' => true,
                    'reason' => 'granted_permission',
                    'permission_type' => $permission['permission_type'],
                    'expiry_date' => $permission['expiry_date']
                ], 'Vous avez accès à ce dossier');
            }
            $stmt->close();

            // Journaliser la tentative d'accès refusée
            $this->logAccess($user['user_id'], $patientId, 'view', 'patient_record', null, 'denied');
            Response::forbidden('Vous n\'avez pas accès à ce dossier');

        } catch (Exception $e) {
            error_log('Has Access Error: ' . $e->getMessage());
            Response::error('Erreur: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }
}
