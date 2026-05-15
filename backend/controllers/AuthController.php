<?php
/**
 * Contrôleur d'authentification
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/JWT.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class AuthController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Inscrire un nouvel utilisateur (Inscription Patient)
     */
    public function register() {
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['email'] ?? null, 'email');
            $validator->validateRequired($input['password'] ?? null, 'password');
            $validator->validateRequired($input['full_name'] ?? null, 'full_name');
            $validator->validateRequired($input['phone'] ?? null, 'phone');
            $validator->validateRequired($input['role'] ?? null, 'role');
            $validator->validateEmail($input['email'] ?? null);
            $validator->validatePassword($input['password'] ?? null);
            $validator->validatePhone($input['phone'] ?? null);
            $validator->validateEnum($input['role'] ?? null, [ROLE_PATIENT, ROLE_MEDECIN, ROLE_INFIRMIERE, ROLE_LABORATOIRE, ROLE_ADMIN], 'role');

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

            // Créer l'utilisateur
            $passwordHash = password_hash($input['password'], PASSWORD_BCRYPT);
            $role = $input['role'];
            $isActive = true;
            $createdAt = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare(
                'INSERT INTO users (email, password_hash, full_name, phone, role, is_active, created_at) 
                 VALUES (?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('sssssis', $input['email'], $passwordHash, $input['full_name'], $input['phone'], $role, $isActive, $createdAt);
            
            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la création de l\'utilisateur');
            }

            $userId = $this->db->insert_id;
            $stmt->close();

            // Si c'est un patient, créer le profil patient
            if ($role === ROLE_PATIENT) {
                $this->createPatientProfile($userId, $input);
            }

            // Générer le JWT
            $token = JWT::encode([
                'user_id' => $userId,
                'email' => $input['email'],
                'role' => $role,
                'full_name' => $input['full_name']
            ]);

            Response::created([
                'user_id' => $userId,
                'email' => $input['email'],
                'full_name' => $input['full_name'],
                'role' => $role,
                'token' => $token
            ], 'Inscription réussie');

        } catch (Exception $e) {
            error_log('Registration Error: ' . $e->getMessage());
            Response::error('Erreur lors de l\'inscription: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Connexion utilisateur
     */
    public function login() {
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['email'] ?? null, 'email');
            $validator->validateRequired($input['password'] ?? null, 'password');
            $validator->validateEmail($input['email'] ?? null);

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', HTTP_BAD_REQUEST, $validator->getErrors());
            }

            // Récupérer l'utilisateur
            $stmt = $this->db->prepare('SELECT user_id, email, password_hash, full_name, role, is_active FROM users WHERE email = ?');
            $stmt->bind_param('s', $input['email']);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::unauthorized('Email ou mot de passe incorrect');
            }

            $user = $result->fetch_assoc();
            $stmt->close();

            // Vérifier le mot de passe
            if (!password_verify($input['password'], $user['password_hash'])) {
                Response::unauthorized('Email ou mot de passe incorrect');
            }

            // Vérifier que l'utilisateur est actif
            if (!$user['is_active']) {
                Response::forbidden('Compte désactivé');
            }

            // Mettre à jour la dernière connexion
            $lastLogin = date('Y-m-d H:i:s');
            $stmt = $this->db->prepare('UPDATE users SET last_login = ? WHERE user_id = ?');
            $stmt->bind_param('si', $lastLogin, $user['user_id']);
            $stmt->execute();
            $stmt->close();

            // Générer le JWT
            $token = JWT::encode([
                'user_id' => $user['user_id'],
                'email' => $user['email'],
                'role' => $user['role'],
                'full_name' => $user['full_name']
            ]);

            // Récupérer les données supplémentaires selon le rôle
            $additionalData = $this->getAdditionalLoginData($user['user_id'], $user['role']);

            Response::success([
                'user_id' => $user['user_id'],
                'email' => $user['email'],
                'full_name' => $user['full_name'],
                'role' => $user['role'],
                'token' => $token,
                'additional_data' => $additionalData
            ], 'Connexion réussie');

        } catch (Exception $e) {
            error_log('Login Error: ' . $e->getMessage());
            Response::error('Erreur lors de la connexion', HTTP_SERVER_ERROR);
        }
    }

    /**
     * Créer un profil patient
     */
    private function createPatientProfile($userId, $input) {
        try {
            // Extraire first_name et last_name
            $firstName = $input['first_name'] ?? null;
            $lastName = $input['last_name'] ?? null;
            
            if (!$firstName || !$lastName) {
                $fullName = $input['full_name'] ?? '';
                $nameParts = explode(' ', trim($fullName), 2);
                if (!$firstName) {
                    $firstName = $nameParts[0] ?? '';
                }
                if (!$lastName) {
                    $lastName = $nameParts[1] ?? $nameParts[0];
                }
            }
            
            $dateOfBirth = $input['date_of_birth'] ?? null;
            $gender = $input['gender'] ?? 'M';
            $phone = $input['phone'] ?? null;
            $email = $input['email'] ?? null;
            $address = $input['address'] ?? null;
            $bloodGroup = $input['blood_group'] ?? $input['groupe_sanguin'] ?? null;
            $isChild = isset($input['is_child']) && $input['is_child'] ? 1 : 0;
            $parentId = null;

            // Si c'est un compte enfant, résoudre le parent_id
            if ($isChild && !empty($input['parent_identifier'])) {
                $parentIdentifier = $input['parent_identifier'];
                // Chercher par patient_id ou par user_id
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
                'INSERT INTO patients (user_id, first_name, last_name, date_of_birth, gender, phone, email, address, blood_group, is_child, parent_id) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            
            $stmt->bind_param('isssssissii', $userId, $firstName, $lastName, $dateOfBirth, $gender, $phone, $email, $address, $bloodGroup, $isChild, $parentId);
            
            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la création du profil patient');
            }
            $stmt->close();
        } catch (Exception $e) {
            error_log('Patient Profile Creation Error: ' . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Récupérer les données supplémentaires de connexion selon le rôle
     */
    private function getAdditionalLoginData($userId, $role) {
        try {
            if ($role === ROLE_PATIENT) {
                $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ? LIMIT 1');
                $stmt->bind_param('i', $userId);
                $stmt->execute();
                $result = $stmt->get_result();
                $patient = $result->fetch_assoc();
                $stmt->close();

                return [
                    'patient_id' => $patient['patient_id'] ?? null
                ];
            } elseif ($role === ROLE_MEDECIN) {
                $stmt = $this->db->prepare('SELECT doctor_id, hospital_id FROM doctors WHERE user_id = ? LIMIT 1');
                $stmt->bind_param('i', $userId);
                $stmt->execute();
                $result = $stmt->get_result();
                $doctor = $result->fetch_assoc();
                $stmt->close();

                return [
                    'doctor_id' => $doctor['doctor_id'] ?? null,
                    'hospital_id' => $doctor['hospital_id'] ?? null
                ];
            } elseif ($role === ROLE_INFIRMIERE) {
                $stmt = $this->db->prepare('SELECT nurse_id, hospital_id FROM nurses WHERE user_id = ? LIMIT 1');
                $stmt->bind_param('i', $userId);
                $stmt->execute();
                $result = $stmt->get_result();
                $nurse = $result->fetch_assoc();
                $stmt->close();

                return [
                    'nurse_id' => $nurse['nurse_id'] ?? null,
                    'hospital_id' => $nurse['hospital_id'] ?? null
                ];
            } elseif ($role === ROLE_LABORATOIRE) {
                $stmt = $this->db->prepare('SELECT laboratory_id FROM laboratories WHERE user_id = ? LIMIT 1');
                $stmt->bind_param('i', $userId);
                $stmt->execute();
                $result = $stmt->get_result();
                $lab = $result->fetch_assoc();
                $stmt->close();

                return [
                    'laboratory_id' => $lab['laboratory_id'] ?? null
                ];
            }

            return [];
        } catch (Exception $e) {
            error_log('Error getting additional login data: ' . $e->getMessage());
            return [];
        }
    }

    /**
     * Rafraîchir le token
     */
    public function refreshToken() {
        try {
            $user = AuthMiddleware::verifyAuth();
            
            $token = JWT::encode([
                'user_id' => $user['user_id'],
                'email' => $user['email'],
                'role' => $user['role'],
                'full_name' => $user['full_name']
            ]);

            Response::success([
                'token' => $token
            ], 'Token rafraîchi');

        } catch (Exception $e) {
            Response::unauthorized($e->getMessage());
        }
    }

    /**
     * Vérifier le token
     */
    public function verifyToken() {
        try {
            $user = AuthMiddleware::verifyAuth();
            Response::success($user, 'Token valide');
        } catch (Exception $e) {
            Response::unauthorized($e->getMessage());
        }
    }
}
?>
