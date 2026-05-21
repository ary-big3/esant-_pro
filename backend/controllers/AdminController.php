<?php
/**
 * Contrôleur Administrateur
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class AdminController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Obtenir le profil admin
     */
    public function getProfile() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_ADMIN, $user['role']);

            $stmt = $this->db->prepare(
                'SELECT u.*, COUNT(DISTINCT p.user_id) as total_patients, COUNT(DISTINCT d.user_id) as total_doctors, COUNT(DISTINCT n.user_id) as total_nurses, COUNT(DISTINCT l.user_id) as total_laboratories
                 FROM users u
                 LEFT JOIN patients p ON 1=1
                 LEFT JOIN doctors d ON 1=1
                 LEFT JOIN nurses n ON 1=1
                 LEFT JOIN laboratories l ON 1=1
                 WHERE u.user_id = ?
                 GROUP BY u.user_id'
            );
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Profil admin non trouvé');
            }

            $profile = $result->fetch_assoc();
            $stmt->close();

            Response::success($profile, 'Profil administrateur récupéré');

        } catch (Exception $e) {
            error_log('Get Admin Profile Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les statistiques du système
     */
    public function getSystemStatistics() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_ADMIN, $user['role']);

            $statistics = [];

            // Utilisateurs
            $stmt = $this->db->query('SELECT COUNT(*) as total FROM users');
            $statistics['total_users'] = $stmt->fetch_assoc()['total'];

            $stmt = $this->db->query('SELECT COUNT(*) as total FROM users WHERE role = "' . ROLE_PATIENT . '"');
            $statistics['total_patients'] = $stmt->fetch_assoc()['total'];

            $stmt = $this->db->query('SELECT COUNT(*) as total FROM users WHERE role = "' . ROLE_MEDECIN . '"');
            $statistics['total_doctors'] = $stmt->fetch_assoc()['total'];

            $stmt = $this->db->query('SELECT COUNT(*) as total FROM users WHERE role = "' . ROLE_INFIRMIERE . '"');
            $statistics['total_nurses'] = $stmt->fetch_assoc()['total'];

            $stmt = $this->db->query('SELECT COUNT(*) as total FROM users WHERE role = "' . ROLE_LABORATOIRE . '"');
            $statistics['total_laboratories'] = $stmt->fetch_assoc()['total'];

            // Consultations
            $stmt = $this->db->query('SELECT COUNT(*) as total FROM consultations');
            $statistics['total_consultations'] = $stmt->fetch_assoc()['total'];

            // Rendez-vous
            $stmt = $this->db->query('SELECT COUNT(*) as total FROM appointments WHERE appointment_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)');
            $statistics['appointments_last_30_days'] = $stmt->fetch_assoc()['total'];

            // Ordonnances
            $stmt = $this->db->query('SELECT COUNT(*) as total FROM prescriptions WHERE status = "' . PRESCRIPTION_ACTIVE . '"');
            $statistics['active_prescriptions'] = $stmt->fetch_assoc()['total'];

            // Examens
            $stmt = $this->db->query('SELECT COUNT(*) as total FROM exams WHERE exam_status = "' . EXAM_STATUS_IN_PROGRESS . '"');
            $statistics['exams_in_progress'] = $stmt->fetch_assoc()['total'];

            // Timestamp
            $statistics['timestamp'] = date('Y-m-d H:i:s');

            Response::success($statistics, 'Statistiques système');

        } catch (Exception $e) {
            error_log('Get System Statistics Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir la liste des utilisateurs
     */
    public function getUsers($page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_ADMIN, $user['role']);

            $offset = ($page - 1) * $limit;

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM users');
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les utilisateurs
            $stmt = $this->db->prepare(
                'SELECT user_id, email, full_name, phone, role, is_active, created_at, last_login
                 FROM users
                 ORDER BY created_at DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('ii', $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $users = [];
            while ($row = $result->fetch_assoc()) {
                $users[] = $row;
            }
            $stmt->close();

            Response::paginated($users, $total, $page, $limit, 'Utilisateurs récupérés');

        } catch (Exception $e) {
            error_log('Get Users Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Créer un utilisateur (médecin, infirmière, enfant/patient)
     */
    public function createUser() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_ADMIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['email'] ?? null, 'email');
            $validator->validateRequired($input['full_name'] ?? null, 'full_name');
            $validator->validateRequired($input['role'] ?? null, 'role');
            $validator->validateEmail($input['email'] ?? null);
            $validator->validateEnum($input['role'] ?? null, [ROLE_PATIENT, ROLE_MEDECIN, ROLE_INFIRMIERE, ROLE_LABORATOIRE], 'role');

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', HTTP_BAD_REQUEST, $validator->getErrors());
            }

            // Vérifier si l'email existe déjà
            $stmt = $this->db->prepare('SELECT user_id FROM users WHERE email = ?');
            $stmt->bind_param('s', $input['email']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                Response::conflict('Cet email est déjà utilisé');
            }
            $stmt->close();

            // Mot de passe par défaut ou fourni
            $password = $input['password'] ?? 'Esante2026!';
            $passwordHash = password_hash($password, PASSWORD_BCRYPT);
            $role = $input['role'];
            $phone = $input['phone'] ?? '0000000000';
            $isActive = true;
            $createdAt = date('Y-m-d H:i:s');

            $specialty = $input['specialty'] ?? $input['specialite'] ?? null;

            $stmt = $this->db->prepare(
                'INSERT INTO users (email, password_hash, full_name, phone, role, is_active, created_at) 
                 VALUES (?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('sssssis', $input['email'], $passwordHash, $input['full_name'], $phone, $role, $isActive, $createdAt);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la création de l\'utilisateur');
            }
            $userId = $this->db->insert_id;
            $stmt->close();

            // Créer les profils spécifiques selon le rôle
            if ($role === ROLE_PATIENT) {
                $this->createPatientProfileFromAdmin($userId, $input);
            } elseif ($role === ROLE_MEDECIN) {
                $this->createDoctorProfile($userId, $input);
            } elseif ($role === ROLE_INFIRMIERE) {
                $this->createNurseProfile($userId, $input);
            } elseif ($role === ROLE_LABORATOIRE) {
                $this->createLaboratoryProfile($userId, $input);
            }

            Response::created([
                'user_id' => $userId,
                'email' => $input['email'],
                'full_name' => $input['full_name'],
                'role' => $role,
            ], 'Utilisateur créé avec succès');

        } catch (Exception $e) {
            error_log('Admin Create User Error: ' . $e->getMessage());
            Response::error('Erreur lors de la création: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Créer un profil patient (depuis l'admin)
     */
    private function createPatientProfileFromAdmin($userId, $input) {
        $fullName = $input['full_name'] ?? '';
        $nameParts = explode(' ', trim($fullName), 2);
        $firstName = $nameParts[0] ?? '';
        $lastName = $nameParts[1] ?? $nameParts[0];
        $isChild = isset($input['is_child']) && $input['is_child'] ? 1 : 0;
        $dateOfBirth = !empty($input['date_of_birth']) ? $input['date_of_birth'] : ($isChild ? date('Y-m-d') : '2000-01-01');
        $gender = !empty($input['gender']) ? $input['gender'] : 'M';
        $phone = $input['phone'] ?? null;
        $email = $input['email'] ?? null;
        $bloodGroup = $input['blood_group'] ?? null;
        $parentId = null;

        // Résoudre parent_id pour les comptes enfants
        if ($isChild && !empty($input['parent_identifier'])) {
            $parentIdentifier = $input['parent_identifier'];
            $stmtParent = $this->db->prepare(
                'SELECT patient_id FROM patients WHERE patient_id = ? OR user_id = ? LIMIT 1'
            );
            $stmtParent->bind_param('is', $parentIdentifier, $parentIdentifier);
            $stmtParent->execute();
            $parentResult = $stmtParent->get_result();
            if ($parentRow = $parentResult->fetch_assoc()) {
                $parentId = $parentRow['patient_id'];
            }
            $stmtParent->close();
        }

        $stmt = $this->db->prepare(
            'INSERT INTO patients (user_id, first_name, last_name, date_of_birth, gender, phone, email, blood_group, is_child, parent_id) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->bind_param('isssssssii', $userId, $firstName, $lastName, $dateOfBirth, $gender, $phone, $email, $bloodGroup, $isChild, $parentId);
        $stmt->execute();
        $stmt->close();
    }

    /**
     * Créer un profil médecin (depuis l'admin)
     */
    private function createDoctorProfile($userId, $input) {
        $fullName = $input['full_name'] ?? '';
        $nameParts = explode(' ', trim($fullName), 2);
        $firstName = $nameParts[0] ?? '';
        $lastName = $nameParts[1] ?? $nameParts[0];
        $phone = $input['phone'] ?? null;
        $email = $input['email'] ?? null;
        $hospitalId = $input['hospital_id'] ?? null;
        $speciality = $input['specialty'] ?? $input['specialite'] ?? 'Généraliste';
        $medicalLicense = 'LIC-' . strtoupper(uniqid());

        $stmt = $this->db->prepare(
            'INSERT INTO doctors (user_id, first_name, last_name, phone, email, medical_license, speciality, hospital_id) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->bind_param('issssssi', $userId, $firstName, $lastName, $phone, $email, $medicalLicense, $speciality, $hospitalId);
        $stmt->execute();
        $stmt->close();
    }

    /**
     * Créer un profil infirmière (depuis l'admin)
     */
    private function createNurseProfile($userId, $input) {
        $fullName = $input['full_name'] ?? '';
        $nameParts = explode(' ', trim($fullName), 2);
        $firstName = $nameParts[0] ?? '';
        $lastName = $nameParts[1] ?? $nameParts[0];
        $phone = $input['phone'] ?? null;
        $email = $input['email'] ?? null;
        $hospitalId = $input['hospital_id'] ?? null;
        $nursingLicense = 'INF-' . strtoupper(uniqid());

        $stmt = $this->db->prepare(
            'INSERT INTO nurses (user_id, first_name, last_name, phone, email, nursing_license, hospital_id) 
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->bind_param('isssssi', $userId, $firstName, $lastName, $phone, $email, $nursingLicense, $hospitalId);
        $stmt->execute();
        $stmt->close();
    }

    /**
     * Créer un profil laboratoire (depuis l'admin)
     */
    private function createLaboratoryProfile($userId, $input) {
        $fullName = $input['full_name'] ?? '';
        $labName = $input['lab_name'] ?? $fullName;
        $phone = $input['phone'] ?? null;
        $email = $input['email'] ?? null;
        $address = $input['address'] ?? null;
        $city = $input['city'] ?? null;
        $responsiblePerson = $fullName;
        $isActive = true;

        $stmt = $this->db->prepare(
            'INSERT INTO laboratories (user_id, name, phone, email, address, city, responsible_person, is_active) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->bind_param('issssssi', $userId, $labName, $phone, $email, $address, $city, $responsiblePerson, $isActive);
        $stmt->execute();
        $stmt->close();
    }

    /**
     * Désactiver un utilisateur
     */
    public function deactivateUser($userId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_ADMIN, $user['role']);

            // Empêcher de désactiver l'admin lui-même
            if ($userId == $user['user_id']) {
                Response::badRequest('Vous ne pouvez pas vous désactiver vous-même');
            }

            $isActive = false;
            $updatedAt = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare('UPDATE users SET is_active = ?, updated_at = ? WHERE user_id = ?');
            $stmt->bind_param('bsi', $isActive, $updatedAt, $userId);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }
            $stmt->close();

            Response::success(null, 'Utilisateur désactivé');

        } catch (Exception $e) {
            error_log('Deactivate User Error: ' . $e->getMessage());
            Response::error('Erreur lors de la désactivation: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Réactiver un utilisateur
     */
    public function activateUser($userId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_ADMIN, $user['role']);

            $isActive = true;
            $updatedAt = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare('UPDATE users SET is_active = ?, updated_at = ? WHERE user_id = ?');
            $stmt->bind_param('bsi', $isActive, $updatedAt, $userId);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }
            $stmt->close();

            Response::success(null, 'Utilisateur réactivé');

        } catch (Exception $e) {
            error_log('Activate User Error: ' . $e->getMessage());
            Response::error('Erreur lors de la réactivation: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les logs du système
     */
    public function getSystemLogs($page = 1, $limit = 50) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_ADMIN, $user['role']);

            $logFile = __DIR__ . '/../logs/error.log';

            if (!file_exists($logFile)) {
                Response::notFound('Fichier log non trouvé');
            }

            $lines = file($logFile, FILE_IGNORE_NEW_LINES);
            $total = count($lines);
            $offset = ($page - 1) * $limit;

            // Récupérer les lignes pour la page actuelle
            $pageLogs = array_slice($lines, -($offset + $limit), $limit);
            $pageLogs = array_reverse($pageLogs);

            Response::paginated($pageLogs, $total, $page, $limit, 'Logs système récupérés');

        } catch (Exception $e) {
            error_log('Get System Logs Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les activités utilisateur
     */
    public function getUserActivities($page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_ADMIN, $user['role']);

            $offset = ($page - 1) * $limit;

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM audit_logs');
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les activités
            $stmt = $this->db->prepare(
                'SELECT a.*, u.full_name, u.email
                 FROM audit_logs a
                 LEFT JOIN users u ON a.user_id = u.user_id
                 ORDER BY a.created_at DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('ii', $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $activities = [];
            while ($row = $result->fetch_assoc()) {
                $activities[] = $row;
            }
            $stmt->close();

            Response::paginated($activities, $total, $page, $limit, 'Activités récupérées');

        } catch (Exception $e) {
            error_log('Get User Activities Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir toutes les spécialités disponibles
     */
    public function getAllSpecialities() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_ADMIN, $user['role']);

            $stmt = $this->db->prepare('SELECT speciality_id, name as speciality_name FROM specialities WHERE is_active = 1 ORDER BY name ASC');
            $stmt->execute();
            $result = $stmt->get_result();

            $specialities = [];
            while ($row = $result->fetch_assoc()) {
                $specialities[] = $row;
            }
            $stmt->close();

            Response::success($specialities, 'Spécialités récupérées');

        } catch (Exception $e) {
            error_log('Get Specialities Error: ' . $e->getMessage());
            Response::error('Erreur lors de la récupération: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }
}
?>
