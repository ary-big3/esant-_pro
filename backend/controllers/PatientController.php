<?php
/**
 * Contrôleur Patient
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class PatientController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Obtenir le profil du patient courant
     */
    public function getProfile() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);

            $stmt = $this->db->prepare(
                'SELECT p.*, u.email, u.full_name, u.phone, u.last_login
                 FROM patients p
                 JOIN users u ON p.user_id = u.user_id
                 WHERE p.user_id = ?'
            );
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Profil patient non trouvé');
            }

            $patient = $result->fetch_assoc();
            $stmt->close();

            Response::success($patient, 'Profil récupéré');

        } catch (Exception $e) {
            error_log('Get Profile Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir le profil d'un patient spécifique (accès médecin/infirmière)
     */
    public function getPatientProfile($patientId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            
            // Vérifier les permissions
            if ($user['role'] === ROLE_PATIENT) {
                // Les patients peuvent voir leur propre profil ou celui de leurs enfants
                $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
                $stmt->bind_param('i', $user['user_id']);
                $stmt->execute();
                $result = $stmt->get_result();
                $ownPatientId = $result->num_rows > 0 ? $result->fetch_assoc()['patient_id'] : null;
                $stmt->close();

                if ($ownPatientId != $patientId) {
                    // Vérifier si c'est un enfant du parent
                    $stmt = $this->db->prepare(
                        'SELECT patient_id FROM patients WHERE patient_id = ? AND parent_id = ?'
                    );
                    $stmt->bind_param('ii', $patientId, $ownPatientId);
                    $stmt->execute();
                    $result = $stmt->get_result();
                    if ($result->num_rows === 0) {
                        Response::forbidden('Accès à ce profil non autorisé');
                    }
                    $stmt->close();
                }
            } else {
                // Les médecins/infirmières peuvent accéder
                AuthMiddleware::verifyPatientAccess($user['user_id'], $patientId, $user['role']);
            }

            $stmt = $this->db->prepare(
                'SELECT p.*, u.email, u.full_name, u.phone
                 FROM patients p
                 JOIN users u ON p.user_id = u.user_id
                 WHERE p.patient_id = ?'
            );
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Patient non trouvé');
            }

            $patient = $result->fetch_assoc();
            $stmt->close();

            Response::success($patient, 'Profil patient récupéré');

        } catch (Exception $e) {
            error_log('Get Patient Profile Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Mettre à jour le profil du patient
     */
    public function updateProfile() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            if (isset($input['email'])) {
                $validator->validateEmail($input['email']);
            }
            if (isset($input['phone'])) {
                $validator->validatePhone($input['phone']);
            }
            if (isset($input['date_of_birth'])) {
                $validator->validateNotFuture($input['date_of_birth']);
            }
            if (isset($input['gender'])) {
                $validator->validateGender($input['gender']);
            }

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', $validator->getErrors());
            }

            // Vérifier que l'email n'existe pas ailleurs
            if (isset($input['email'])) {
                $stmt = $this->db->prepare('SELECT user_id FROM users WHERE email = ? AND user_id != ?');
                $stmt->bind_param('si', $input['email'], $user['user_id']);
                $stmt->execute();
                if ($stmt->get_result()->num_rows > 0) {
                    Response::conflict('Cet email est déjà utilisé');
                }
                $stmt->close();
            }

            // Construire la requête UPDATE
            $fields = [];
            $params = [];
            $types = '';

            if (isset($input['first_name'])) {
                $fields[] = 'first_name = ?';
                $params[] = $input['first_name'];
                $types .= 's';
            }
            if (isset($input['last_name'])) {
                $fields[] = 'last_name = ?';
                $params[] = $input['last_name'];
                $types .= 's';
            }
            if (isset($input['date_of_birth'])) {
                $fields[] = 'date_of_birth = ?';
                $params[] = $input['date_of_birth'];
                $types .= 's';
            }
            if (isset($input['gender'])) {
                $fields[] = 'gender = ?';
                $params[] = $input['gender'];
                $types .= 's';
            }
            if (isset($input['phone'])) {
                $fields[] = 'phone = ?';
                $params[] = $input['phone'];
                $types .= 's';
            }
            if (isset($input['address'])) {
                $fields[] = 'address = ?';
                $params[] = $input['address'];
                $types .= 's';
            }
            if (isset($input['blood_group'])) {
                $fields[] = 'blood_group = ?';
                $params[] = $input['blood_group'];
                $types .= 's';
            }

            if (empty($fields)) {
                Response::badRequest('Aucune donnée à mettre à jour');
            }

            $params[] = $user['user_id'];
            $types .= 'i';

            $query = 'UPDATE patients SET ' . implode(', ', $fields) . ' WHERE user_id = ?';
            $stmt = $this->db->prepare($query);
            $stmt->bind_param($types, ...$params);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }
            $stmt->close();

            // Si email mis à jour, mettre à jour aussi dans la table users
            if (isset($input['email'])) {
                $stmt = $this->db->prepare('UPDATE users SET email = ? WHERE user_id = ?');
                $stmt->bind_param('si', $input['email'], $user['user_id']);
                $stmt->execute();
                $stmt->close();
            }

            Response::success(null, 'Profil mis à jour avec succès');

        } catch (Exception $e) {
            error_log('Update Profile Error: ' . $e->getMessage());
            Response::error('Erreur lors de la mise à jour: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir la liste des enfants du patient
     */
    public function getChildren() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);

            $stmt = $this->db->prepare(
                'SELECT patient_id, first_name, last_name, date_of_birth, gender, blood_group
                 FROM patients
                 WHERE parent_id = (SELECT patient_id FROM patients WHERE user_id = ?)
                 ORDER BY date_of_birth DESC'
            );
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();

            $children = [];
            while ($row = $result->fetch_assoc()) {
                $children[] = $row;
            }
            $stmt->close();

            Response::success($children, 'Liste des enfants récupérée');

        } catch (Exception $e) {
            error_log('Get Children Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les infos NFC du patient
     */
    public function getNFCCard($patientId = null) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);

            // Si patientId est fourni (enfant), vérifier l'accès
            if ($patientId !== null) {
                $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
                $stmt->bind_param('i', $user['user_id']);
                $stmt->execute();
                $result = $stmt->get_result();
                $ownPatientId = $result->num_rows > 0 ? $result->fetch_assoc()['patient_id'] : null;
                $stmt->close();

                // Vérifier que c'est un enfant du parent
                if ($ownPatientId != $patientId) {
                    $stmt = $this->db->prepare(
                        'SELECT patient_id FROM patients WHERE patient_id = ? AND parent_id = ?'
                    );
                    $stmt->bind_param('ii', $patientId, $ownPatientId);
                    $stmt->execute();
                    $result = $stmt->get_result();
                    if ($result->num_rows === 0) {
                        Response::forbidden('Accès non autorisé');
                    }
                    $stmt->close();
                }

                $searchUserId = null;
                // Récupérer le user_id du patient enfant
                $stmt = $this->db->prepare('SELECT user_id FROM patients WHERE patient_id = ?');
                $stmt->bind_param('i', $patientId);
                $stmt->execute();
                $childResult = $stmt->get_result();
                if ($childRow = $childResult->fetch_assoc()) {
                    $searchUserId = $childRow['user_id'];
                }
                $stmt->close();
            } else {
                $searchUserId = $user['user_id'];
            }

            $stmt = $this->db->prepare(
                'SELECT p.patient_id, u.full_name, p.blood_group, u.is_active
                 FROM patients p
                 JOIN users u ON p.user_id = u.user_id
                 WHERE p.user_id = ?'
            );
            $stmt->bind_param('i', $searchUserId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Données NFC non trouvées');
            }

            $nfcData = $result->fetch_assoc();
            $stmt->close();

            // Formater l'ID patient
            $nfcData['nfc_card_id'] = 'PAT-' . str_pad($nfcData['patient_id'], 4, '0', STR_PAD_LEFT);
            $nfcData['verified'] = $nfcData['is_active'] ? 'Compte vérifié' : 'Compte non vérifié';

            Response::success($nfcData, 'Carte NFC récupérée');

        } catch (Exception $e) {
            error_log('Get NFC Card Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Basculer vers un compte enfant
     */
    public function switchToChild($childPatientId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);

            // Vérifier que c'est bien un enfant du parent
            $stmt = $this->db->prepare(
                'SELECT c.patient_id FROM patients c
                 JOIN patients p ON c.parent_id = p.patient_id
                 WHERE p.user_id = ? AND c.patient_id = ?'
            );
            $stmt->bind_param('ii', $user['user_id'], $childPatientId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::forbidden('Cet enfant n\'existe pas ou n\'est pas autorisé');
            }
            $stmt->close();

            // Récupérer les données du compte enfant
            $stmt = $this->db->prepare(
                'SELECT c.patient_id, u.full_name, u.email, u.role
                 FROM patients c
                 JOIN users u ON c.user_id = u.user_id
                 WHERE c.patient_id = ?'
            );
            $stmt->bind_param('i', $childPatientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $child = $result->fetch_assoc();
            $stmt->close();

            // Générer un nouveau token pour le compte enfant
            $token = JWT::encode([
                'user_id' => $child['user_id'] ?? $user['user_id'],
                'patient_id' => $childPatientId,
                'is_child_account' => true,
                'parent_id' => $user['user_id']
            ]);

            Response::success([
                'token' => $token,
                'patient_id' => $childPatientId,
                'is_child_account' => true,
                'parent_id' => $user['user_id']
            ], 'Basculement vers compte enfant réussi');

        } catch (Exception $e) {
            error_log('Switch to Child Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Retourner au compte parent depuis un compte enfant
     */
    public function returnToParent() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);

            // Vérifier que c'est un compte enfant
            if (!isset($user['is_child_account']) || !$user['is_child_account']) {
                Response::badRequest('Ce n\'est pas un compte enfant');
            }

            $parentId = $user['parent_id'] ?? null;
            if (!$parentId) {
                Response::badRequest('Parent non trouvé');
            }

            // Récupérer les données du parent
            $stmt = $this->db->prepare(
                'SELECT u.user_id, u.email, u.full_name, p.patient_id
                 FROM patients p
                 JOIN users u ON p.user_id = u.user_id
                 WHERE u.user_id = ?'
            );
            $stmt->bind_param('i', $parentId);
            $stmt->execute();
            $result = $stmt->get_result();
            $parent = $result->fetch_assoc();
            $stmt->close();

            // Générer un nouveau token pour le compte parent
            $token = JWT::encode([
                'user_id' => $parent['user_id'],
                'email' => $parent['email'],
                'role' => ROLE_PATIENT,
                'full_name' => $parent['full_name']
            ]);

            Response::success([
                'token' => $token,
                'patient_id' => $parent['patient_id'],
                'is_child_account' => false
            ], 'Retour au compte parent réussi');

        } catch (Exception $e) {
            error_log('Return to Parent Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les demandes d'accès en attente
     */
    public function getPendingRequests($page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);

            // Récupérer le patient_id
            $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Patient non trouvé');
            }
            $patientId = $result->fetch_assoc()['patient_id'];
            $stmt->close();

            // Limiter la limite
            $limit = min(intval($limit), MAX_PAGE_SIZE);
            $offset = (intval($page) - 1) * $limit;

            // Compter le total des demandes en attente
            $stmt = $this->db->prepare(
                'SELECT COUNT(*) as total FROM access_requests 
                 WHERE patient_id = ? AND status = "pending"'
            );
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $total = $stmt->get_result()->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les demandes d'accès en attente
            $stmt = $this->db->prepare(
                'SELECT ar.request_id, ar.reason_for_access as reason, ar.requested_at, ar.permission_type,
                        d.doctor_id, d.first_name, d.last_name, u.full_name, u.email, u.phone, 
                        h.name as hospital_name, ds.speciality_id, s.name as speciality_name
                 FROM access_requests ar
                 INNER JOIN doctors d ON ar.doctor_id = d.doctor_id
                 INNER JOIN users u ON d.user_id = u.user_id
                 LEFT JOIN hospitals h ON d.hospital_id = h.hospital_id
                 LEFT JOIN doctor_specialities ds ON d.doctor_id = ds.doctor_id AND ds.is_primary = TRUE
                 LEFT JOIN specialities s ON ds.speciality_id = s.speciality_id
                 WHERE ar.patient_id = ? AND ar.status = "pending"
                 ORDER BY ar.requested_at DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $requests = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
            $stmt->close();

            Response::success(
                $requests,
                'Demandes récupérées',
                ['page' => intval($page), 'limit' => $limit, 'total' => $total]
            );

        } catch (Exception $e) {
            error_log('Get Pending Requests Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Approuver une demande d'accès
     */
    public function approveAccessRequest($requestId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);

            // Récupérer le patient_id
            $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            $patientId = $result->fetch_assoc()['patient_id'];
            $stmt->close();

            $requestIdInt = intval($requestId);

            // Vérifier que la demande existe et appartient au patient
            $stmt = $this->db->prepare(
                'SELECT ar.request_id, ar.doctor_id, ar.status, ar.requester_user_id, ar.permission_type
                 FROM access_requests ar
                 WHERE ar.request_id = ? AND ar.patient_id = ?'
            );
            $stmt->bind_param('ii', $requestIdInt, $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                $stmt->close();
                Response::notFound('Demande non trouvée');
            }
            $request = $result->fetch_assoc();
            $stmt->close();

            if ($request['status'] !== 'pending') {
                Response::conflict('Cette demande n\'est pas en attente');
            }

            // Approuver la demande dans access_requests
            $approvedAt = date('Y-m-d H:i:s');
            $stmt = $this->db->prepare(
                'UPDATE access_requests 
                 SET status = "approved", responded_at = ?
                 WHERE request_id = ?'
            );
            $stmt->bind_param('si', $approvedAt, $requestIdInt);

            $stmt->execute();
            $stmt->close();

            // Créer une permission d'accès
            $permissionType = $request['permission_type'] ?? 'view_only';
            $expiryDate = date('Y-m-d H:i:s', strtotime('+1 year'));
            $stmt = $this->db->prepare(
                'INSERT INTO access_permissions (patient_id, authorized_user_id, permission_type, granted_by, expiry_date)
                 VALUES (?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('iisss', $patientId, $request['requester_user_id'], $permissionType, $user['user_id'], $expiryDate);
            $stmt->execute();
            $stmt->close();

            // Créer une notification pour le médecin
            $stmt = $this->db->prepare('SELECT user_id FROM doctors WHERE doctor_id = ?');
            $stmt->bind_param('i', $request['doctor_id']);
            $stmt->execute();
            $doctorUserId = $stmt->get_result()->fetch_assoc()['user_id'];
            $stmt->close();

            // Récupérer le nom du patient
            $stmt = $this->db->prepare('SELECT full_name FROM users WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $patientName = $stmt->get_result()->fetch_assoc()['full_name'];
            $stmt->close();

            $notificationTitle = "✅ Accès dossier approuvé";
            $notificationMessage = "$patientName a approuvé votre demande d'accès à son dossier médical.";
            $notificationType = 'access_approved';

            $stmt = $this->db->prepare(
                'INSERT INTO notifications (user_id, notification_type, title, message, related_patient_id, is_read, created_at)
                 VALUES (?, ?, ?, ?, ?, FALSE, NOW())'
            );
            $stmt->bind_param('isssi', $doctorUserId, $notificationType, $notificationTitle, $notificationMessage, $patientId);
            $stmt->execute();
            $stmt->close();

            Response::success(['request_id' => $requestIdInt], 'Demande approuvée avec succès - Accès accordé au médecin');

        } catch (Exception $e) {
            error_log('Approve Access Request Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Rejeter une demande d'accès
     */
    public function rejectAccessRequest($requestId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);

            // Récupérer le patient_id
            $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            $patientId = $result->fetch_assoc()['patient_id'];
            $stmt->close();

            $requestIdInt = intval($requestId);
            $input = json_decode(file_get_contents('php://input'), true);
            $rejectionReason = $input['reason'] ?? null;

            // Vérifier que la demande existe et appartient au patient
            $stmt = $this->db->prepare(
                'SELECT ar.request_id, ar.doctor_id, ar.status, ar.requester_user_id
                 FROM access_requests ar
                 WHERE ar.request_id = ? AND ar.patient_id = ?'
            );
            $stmt->bind_param('ii', $requestIdInt, $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                $stmt->close();
                Response::notFound('Demande non trouvée');
            }
            $request = $result->fetch_assoc();
            $stmt->close();

            if ($request['status'] !== 'pending') {
                Response::conflict('Cette demande n\'est pas en attente');
            }

            // Rejeter la demande
            $responseTime = date('Y-m-d H:i:s');
            $stmt = $this->db->prepare(
                'UPDATE access_requests 
                 SET status = "rejected", responded_at = ?, response_reason = ?
                 WHERE request_id = ?'
            );
            $stmt->bind_param('ssi', $responseTime, $rejectionReason, $requestIdInt);
            $stmt->execute();
            $stmt->close();

            // Créer une notification pour le médecin
            $stmt = $this->db->prepare('SELECT user_id FROM doctors WHERE doctor_id = ?');
            $stmt->bind_param('i', $request['doctor_id']);
            $stmt->execute();
            $doctorUserId = $stmt->get_result()->fetch_assoc()['user_id'];
            $stmt->close();

            // Récupérer le nom du patient
            $stmt = $this->db->prepare('SELECT full_name FROM users WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $patientName = $stmt->get_result()->fetch_assoc()['full_name'];
            $stmt->close();

            $notificationTitle = "❌ Demande d'accès refusée";
            $notificationMessage = "$patientName a refusé votre demande d'accès à son dossier médical." . ($rejectionReason ? " Raison: $rejectionReason" : "");
            $notificationType = 'access_rejected';

            $stmt = $this->db->prepare(
                'INSERT INTO notifications (user_id, notification_type, title, message, related_patient_id, is_read, created_at)
                 VALUES (?, ?, ?, ?, ?, FALSE, NOW())'
            );
            $stmt->bind_param('isssi', $doctorUserId, $notificationType, $notificationTitle, $notificationMessage, $patientId);
            $stmt->execute();
            $stmt->close();

            Response::success(['request_id' => $requestIdInt], 'Demande rejetée');

        } catch (Exception $e) {
            error_log('Reject Access Request Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Récupérer les accès consentis et révoqués du patient
     */
    public function getConsentedAccess() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);

            // Récupérer le patient_id
            $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Patient non trouvé');
            }
            $patientId = $result->fetch_assoc()['patient_id'];
            $stmt->close();

            // Récupérer les accès autorisés (permissions actives non révoquées)
            $stmt = $this->db->prepare(
                'SELECT 
                    ap.permission_id,
                    ap.authorized_user_id,
                    u.full_name as doctor_name,
                    ap.permission_type,
                    ap.granted_date,
                    ap.expiry_date,
                    d.speciality
                 FROM access_permissions ap
                 JOIN users u ON ap.authorized_user_id = u.user_id
                 LEFT JOIN doctors d ON d.user_id = u.user_id
                 WHERE ap.patient_id = ? 
                 AND ap.is_revoked = FALSE
                 AND (ap.expiry_date IS NULL OR ap.expiry_date > NOW())
                 ORDER BY ap.granted_date DESC'
            );
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            $accesAutorises = [];
            while ($row = $result->fetch_assoc()) {
                $accesAutorises[] = $row;
            }
            $stmt->close();

            // Récupérer les accès révoqués
            $stmt = $this->db->prepare(
                'SELECT 
                    ap.permission_id,
                    ap.authorized_user_id,
                    u.full_name as doctor_name,
                    ap.permission_type,
                    ap.revoked_date
                 FROM access_permissions ap
                 JOIN users u ON ap.authorized_user_id = u.user_id
                 WHERE ap.patient_id = ? AND ap.is_revoked = TRUE
                 ORDER BY ap.revoked_date DESC'
            );
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            $accesRevokes = [];
            while ($row = $result->fetch_assoc()) {
                $accesRevokes[] = $row;
            }
            $stmt->close();

            Response::success([
                'accesAutorises' => $accesAutorises,
                'accesRevokes' => $accesRevokes
            ], 'Consentements récupérés');

        } catch (Exception $e) {
            error_log('Get Consented Access Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }
}
?>
