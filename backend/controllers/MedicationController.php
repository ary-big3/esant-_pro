<?php
/**
 * Contrôleur Médicaments
 * E-Santé - Plateforme Nationale de Santé Numérique
 * Gestion de la liste des médicaments disponibles pour les prescriptions
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';

class MedicationController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Obtenir la liste de tous les médicaments actifs
     * Optionnel: filtrer par catégorie
     */
    public function getAllMedications() {
        try {
            $user = AuthMiddleware::verifyAuth();

            $category = isset($_GET['category']) ? $_GET['category'] : null;
            $search = isset($_GET['search']) ? $_GET['search'] : null;
            $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
            $offset = ($page - 1) * $limit;

            $query = 'SELECT * FROM medication WHERE is_active = 1';
            $params = [];
            $types = '';

            if ($category) {
                $query .= ' AND category = ?';
                $params[] = $category;
                $types .= 's';
            }

            if ($search) {
                $query .= ' AND (medication_name LIKE ? OR generic_name LIKE ? OR description LIKE ?)';
                $searchTerm = '%' . $search . '%';
                $params[] = $searchTerm;
                $params[] = $searchTerm;
                $params[] = $searchTerm;
                $types .= 'sss';
            }

            // Compter le total
            $countQuery = str_replace('SELECT *', 'SELECT COUNT(*) as total', $query);
            $countStmt = $this->db->prepare($countQuery);
            if (!empty($params)) {
                $countStmt->bind_param($types, ...$params);
            }
            $countStmt->execute();
            $countResult = $countStmt->get_result();
            $total = $countResult->fetch_assoc()['total'];
            $countStmt->close();

            // Récupérer les médicaments
            $query .= ' ORDER BY category, medication_name ASC LIMIT ? OFFSET ?';
            $params[] = $limit;
            $params[] = $offset;
            $types .= 'ii';

            $stmt = $this->db->prepare($query);
            if (!empty($params)) {
                $stmt->bind_param($types, ...$params);
            }
            $stmt->execute();
            $result = $stmt->get_result();
            $medications = [];

            while ($row = $result->fetch_assoc()) {
                $medications[] = $row;
            }
            $stmt->close();

            Response::success([
                'medications' => $medications,
                'total' => $total,
                'page' => $page,
                'limit' => $limit,
                'pages' => ceil($total / $limit)
            ], 'Médicaments récupérés avec succès');

        } catch (Exception $e) {
            error_log('Get Medications Error: ' . $e->getMessage());
            Response::error('Erreur lors de la récupération des médicaments', HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les catégories de médicaments
     */
    public function getMedicationCategories() {
        try {
            $user = AuthMiddleware::verifyAuth();

            $stmt = $this->db->prepare(
                'SELECT DISTINCT category FROM medication WHERE is_active = 1 ORDER BY category ASC'
            );
            $stmt->execute();
            $result = $stmt->get_result();
            $categories = [];

            while ($row = $result->fetch_assoc()) {
                $categories[] = $row['category'];
            }
            $stmt->close();

            Response::success([
                'categories' => $categories
            ], 'Catégories récupérées avec succès');

        } catch (Exception $e) {
            error_log('Get Categories Error: ' . $e->getMessage());
            Response::error('Erreur lors de la récupération des catégories', HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir un médicament par ID
     */
    public function getMedicationById($medicationId) {
        try {
            $user = AuthMiddleware::verifyAuth();

            $stmt = $this->db->prepare('SELECT * FROM medication WHERE medication_id = ? AND is_active = 1');
            $stmt->bind_param('i', $medicationId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Médicament non trouvé');
            }

            $medication = $result->fetch_assoc();
            $stmt->close();

            Response::success($medication, 'Médicament récupéré avec succès');

        } catch (Exception $e) {
            error_log('Get Medication Error: ' . $e->getMessage());
            Response::error('Erreur lors de la récupération du médicament', HTTP_SERVER_ERROR);
        }
    }

    /**
     * Créer un nouveau médicament (admin seulement)
     */
    public function create() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_ADMIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['medication_name'] ?? null, 'medication_name');
            $validator->validateRequired($input['dosage'] ?? null, 'dosage');
            $validator->validateRequired($input['category'] ?? null, 'category');

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', HTTP_BAD_REQUEST, $validator->getErrors());
            }

            $medicationName = $input['medication_name'];
            $genericName = $input['generic_name'] ?? null;
            $dosage = $input['dosage'];
            $dosageUnit = $input['dosage_unit'] ?? 'mg';
            $frequency = $input['frequency'] ?? '1x/jour';
            $defaultDuration = $input['default_duration'] ?? 7;
            $routeOfAdministration = $input['route_of_administration'] ?? 'oral';
            $category = $input['category'];
            $isActive = isset($input['is_active']) ? (int)$input['is_active'] : 1;
            $description = $input['description'] ?? null;

            $stmt = $this->db->prepare(
                'INSERT INTO medication (medication_name, generic_name, dosage, dosage_unit, frequency, default_duration, route_of_administration, category, is_active, description)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->bind_param(
                'sssssissis',
                $medicationName, $genericName, $dosage, $dosageUnit, $frequency,
                $defaultDuration, $routeOfAdministration, $category, $isActive, $description
            );

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la création du médicament');
            }

            $medicationId = $this->db->insert_id;
            $stmt->close();

            Response::created([
                'medication_id' => $medicationId,
                'medication_name' => $medicationName
            ], 'Médicament créé avec succès');

        } catch (Exception $e) {
            error_log('Create Medication Error: ' . $e->getMessage());
            Response::error('Erreur lors de la création: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Mettre à jour un médicament (admin seulement)
     */
    public function update($medicationId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_ADMIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $updates = [];
            $params = [];
            $types = '';

            if (isset($input['medication_name'])) {
                $updates[] = 'medication_name = ?';
                $params[] = $input['medication_name'];
                $types .= 's';
            }
            if (isset($input['generic_name'])) {
                $updates[] = 'generic_name = ?';
                $params[] = $input['generic_name'];
                $types .= 's';
            }
            if (isset($input['dosage'])) {
                $updates[] = 'dosage = ?';
                $params[] = $input['dosage'];
                $types .= 's';
            }
            if (isset($input['dosage_unit'])) {
                $updates[] = 'dosage_unit = ?';
                $params[] = $input['dosage_unit'];
                $types .= 's';
            }
            if (isset($input['frequency'])) {
                $updates[] = 'frequency = ?';
                $params[] = $input['frequency'];
                $types .= 's';
            }
            if (isset($input['default_duration'])) {
                $updates[] = 'default_duration = ?';
                $params[] = $input['default_duration'];
                $types .= 'i';
            }
            if (isset($input['route_of_administration'])) {
                $updates[] = 'route_of_administration = ?';
                $params[] = $input['route_of_administration'];
                $types .= 's';
            }
            if (isset($input['category'])) {
                $updates[] = 'category = ?';
                $params[] = $input['category'];
                $types .= 's';
            }
            if (isset($input['is_active'])) {
                $updates[] = 'is_active = ?';
                $params[] = (int)$input['is_active'];
                $types .= 'i';
            }
            if (isset($input['description'])) {
                $updates[] = 'description = ?';
                $params[] = $input['description'];
                $types .= 's';
            }

            if (empty($updates)) {
                Response::badRequest('Aucune données à mettre à jour');
            }

            $params[] = $medicationId;
            $types .= 'i';

            $query = 'UPDATE medication SET ' . implode(', ', $updates) . ' WHERE medication_id = ?';
            $stmt = $this->db->prepare($query);
            $stmt->bind_param($types, ...$params);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour du médicament');
            }

            $stmt->close();

            Response::success([
                'medication_id' => $medicationId
            ], 'Médicament mis à jour avec succès');

        } catch (Exception $e) {
            error_log('Update Medication Error: ' . $e->getMessage());
            Response::error('Erreur lors de la mise à jour: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les médicaments par catégorie
     */
    public function getMedicationsByCategory($category) {
        try {
            $user = AuthMiddleware::verifyAuth();

            $stmt = $this->db->prepare(
                'SELECT * FROM medication WHERE category = ? AND is_active = 1 ORDER BY medication_name ASC'
            );
            $stmt->bind_param('s', $category);
            $stmt->execute();
            $result = $stmt->get_result();
            $medications = [];

            while ($row = $result->fetch_assoc()) {
                $medications[] = $row;
            }
            $stmt->close();

            Response::success([
                'category' => $category,
                'medications' => $medications,
                'count' => count($medications)
            ], 'Médicaments récupérés avec succès');

        } catch (Exception $e) {
            error_log('Get Medications By Category Error: ' . $e->getMessage());
            Response::error('Erreur lors de la récupération des médicaments', HTTP_SERVER_ERROR);
        }
    }
}
?>
