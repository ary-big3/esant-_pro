<?php
/**
 * Contrôleur Infirmière
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class NurseController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Obtenir le profil de l'infirmière
     */
    public function getProfile() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_INFIRMIERE, $user['role']);

            $stmt = $this->db->prepare(
                'SELECT n.*, u.email, u.full_name, u.phone, u.last_login, h.name as hospital_name
                 FROM nurses n
                 JOIN users u ON n.user_id = u.user_id
                 LEFT JOIN hospitals h ON n.hospital_id = h.hospital_id
                 WHERE n.user_id = ?'
            );
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Profil infirmière non trouvé');
            }

            $nurse = $result->fetch_assoc();
            $stmt->close();

            Response::success($nurse, 'Profil infirmière récupéré');

        } catch (Exception $e) {
            error_log('Get Nurse Profile Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Enregistrer les signes vitaux d'un patient
     */
    public function recordVitals() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_INFIRMIERE, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['patient_id'] ?? null, 'patient_id');

            if ($validator->hasErrors()) {
                Response::error($validator->getErrors(), HTTP_BAD_REQUEST);
            }

            // Récupérer le nurse_id
            $stmt = $this->db->prepare('SELECT nurse_id FROM nurses WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Infirmière non trouvée');
            }
            $nurseId = $result->fetch_assoc()['nurse_id'];
            $stmt->close();

            // Enregistrer les signes vitaux
            $patientId = $input['patient_id'];
            $temperature = $input['temperature_celsius'] ?? null;
            $systolic = $input['systolic_pressure'] ?? null;
            $diastolic = $input['diastolic_pressure'] ?? null;
            $pulse = $input['pulse_bpm'] ?? null;
            $respiratoryRate = $input['respiratory_rate'] ?? null;
            $oxygenSat = $input['oxygen_saturation'] ?? null;
            $weight = $input['weight_kg'] ?? null;
            $height = $input['height_cm'] ?? null;
            $status = $input['status'] ?? RESULT_NORMAL;
            $notes = $input['notes'] ?? null;
            $now = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare(
                'INSERT INTO vital_signs (patient_id, nurse_id, measurement_date, temperature_celsius, systolic_pressure, diastolic_pressure, pulse_bpm, respiratory_rate, oxygen_saturation, weight_kg, height_cm, status, notes, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('iisddiiidddsss', $patientId, $nurseId, $now, $temperature, $systolic, $diastolic, $pulse, $respiratoryRate, $oxygenSat, $weight, $height, $status, $notes, $now);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de l\'enregistrement');
            }

            $vitalSignId = $this->db->insert_id;
            $stmt->close();

            Response::created([
                'vital_sign_id' => $vitalSignId,
                'status' => $status
            ], 'Signes vitaux enregistrés avec succès');

        } catch (Exception $e) {
            error_log('Record Vitals Error: ' . $e->getMessage());
            Response::error('Erreur lors de l\'enregistrement: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les signes vitaux d'un patient
     */
    public function getVitals($patientId, $page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyPatientAccess($user['user_id'], $patientId, $user['role']);

            $offset = ($page - 1) * $limit;

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM vital_signs WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les signes vitaux
            $stmt = $this->db->prepare(
                'SELECT v.*, n.first_name as nurse_first_name, n.last_name as nurse_last_name
                 FROM vital_signs v
                 LEFT JOIN nurses n ON v.nurse_id = n.nurse_id
                 WHERE v.patient_id = ?
                 ORDER BY v.measurement_date DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $vitals = [];
            while ($row = $result->fetch_assoc()) {
                $vitals[] = $row;
            }
            $stmt->close();

            Response::paginated($vitals, $total, $page, $limit, 'Signes vitaux récupérés');

        } catch (Exception $e) {
            error_log('Get Vitals Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Mettre à jour les signes vitaux d'un patient
     */
    public function updateVitals($vitalId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_INFIRMIERE, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            // Vérifier que la mesure appartient à l'infirmière
            $stmt = $this->db->prepare(
                'SELECT v.* FROM vital_signs v
                 JOIN nurses n ON v.nurse_id = n.nurse_id
                 WHERE v.vital_sign_id = ? AND n.user_id = ?'
            );
            $stmt->bind_param('ii', $vitalId, $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Vous n\'avez pas accès à cette mesure');
            }
            $stmt->close();

            // Mettre à jour les signes vitaux
            $temperature = $input['temperature_celsius'] ?? null;
            $systolic = $input['systolic_pressure'] ?? null;
            $diastolic = $input['diastolic_pressure'] ?? null;
            $pulse = $input['pulse_bpm'] ?? null;
            $respiratoryRate = $input['respiratory_rate'] ?? null;
            $oxygenSat = $input['oxygen_saturation'] ?? null;
            $weight = $input['weight_kg'] ?? null;
            $height = $input['height_cm'] ?? null;
            $status = $input['status'] ?? RESULT_NORMAL;
            $notes = $input['notes'] ?? null;
            $now = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare(
                'UPDATE vital_signs 
                 SET temperature_celsius = ?, systolic_pressure = ?, diastolic_pressure = ?, 
                     pulse_bpm = ?, respiratory_rate = ?, oxygen_saturation = ?, 
                     weight_kg = ?, height_cm = ?, status = ?, notes = ?, updated_at = ?
                 WHERE vital_sign_id = ?'
            );
            $stmt->bind_param('ddiiiiddsssi', $temperature, $systolic, $diastolic, $pulse, 
                            $respiratoryRate, $oxygenSat, $weight, $height, $status, $notes, $now, $vitalId);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }

            $stmt->close();

            Response::success([
                'vital_sign_id' => $vitalId,
                'status' => $status
            ], 'Signes vitaux mis à jour avec succès');

        } catch (Exception $e) {
            error_log('Update Vitals Error: ' . $e->getMessage());
            Response::error('Erreur lors de la mise à jour: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Supprimer les signes vitaux d'un patient
     */
    public function deleteVitals($vitalId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_INFIRMIERE, $user['role']);

            // Vérifier que la mesure appartient à l'infirmière
            $stmt = $this->db->prepare(
                'SELECT v.* FROM vital_signs v
                 JOIN nurses n ON v.nurse_id = n.nurse_id
                 WHERE v.vital_sign_id = ? AND n.user_id = ?'
            );
            $stmt->bind_param('ii', $vitalId, $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Vous n\'avez pas accès à cette mesure');
            }
            $stmt->close();

            // Supprimer la mesure
            $stmt = $this->db->prepare('DELETE FROM vital_signs WHERE vital_sign_id = ?');
            $stmt->bind_param('i', $vitalId);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la suppression');
            }

            $stmt->close();

            Response::success(['vital_sign_id' => $vitalId], 'Signes vitaux supprimés avec succès');

        } catch (Exception $e) {
            error_log('Delete Vitals Error: ' . $e->getMessage());
            Response::error('Erreur lors de la suppression: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Récupérer les derniers signes vitaux d'un patient
     */
    public function getLatestVitals($patientId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyPatientAccess($user['user_id'], $patientId, $user['role']);

            // Récupérer la dernière mesure
            $stmt = $this->db->prepare(
                'SELECT v.*, n.first_name as nurse_first_name, n.last_name as nurse_last_name
                 FROM vital_signs v
                 LEFT JOIN nurses n ON v.nurse_id = n.nurse_id
                 WHERE v.patient_id = ?
                 ORDER BY v.measurement_date DESC
                 LIMIT 1'
            );
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::success(null, 'Aucunes constantes vitales trouvées');
            } else {
                $vitals = $result->fetch_assoc();
                Response::success($vitals, 'Dernières constantes vitales');
            }

            $stmt->close();

        } catch (Exception $e) {
            error_log('Get Latest Vitals Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }
}
?>
