<?php
/**
 * Contrôleur Allergies
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class AllergyController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Obtenir les allergies d'un patient
     */
    public function getPatientAllergies($patientId) {
        try {
            $user = AuthMiddleware::verifyAuth();

            $stmt = $this->db->prepare(
                'SELECT * FROM allergies WHERE patient_id = ? ORDER BY created_at DESC'
            );
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();

            $allergies = [];
            while ($row = $result->fetch_assoc()) {
                $allergies[] = $row;
            }
            $stmt->close();

            Response::success($allergies, 'Allergies récupérées');

        } catch (Exception $e) {
            error_log('Get Allergies Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Ajouter une allergie
     */
    public function add() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $patientId = $input['patient_id'] ?? null;
            $allergyName = $input['allergy_name'] ?? null;
            $severity = $input['severity'] ?? 'Modérée';
            $description = $input['description'] ?? null;
            $reaction = $input['reaction'] ?? null;
            $diagnosedDate = $input['diagnosed_date'] ?? date('Y-m-d');

            // Validation basique
            if (empty($patientId) || empty($allergyName)) {
                return Response::badRequest('ID patient et nom allergie requis');
            }

            $stmt = $this->db->prepare(
                'INSERT INTO allergies (patient_id, allergy_name, severity, description, reaction, diagnosed_date, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, NOW())'
            );
            $stmt->bind_param('isssss', $patientId, $allergyName, $severity, $description, $reaction, $diagnosedDate);

            if (!$stmt->execute()) {
                Response::error($stmt->error, HTTP_SERVER_ERROR);
            }

            $allergyId = $stmt->insert_id;
            $stmt->close();

            Response::success([
                'allergy_id' => $allergyId,
                'patient_id' => $patientId,
                'allergy_name' => $allergyName,
                'severity' => $severity,
                'description' => $description,
                'reaction' => $reaction,
                'diagnosed_date' => $diagnosedDate,
            ], 'Allergie ajoutée');

        } catch (Exception $e) {
            error_log('Add Allergy Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }
}
