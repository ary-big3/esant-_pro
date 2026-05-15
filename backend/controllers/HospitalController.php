<?php
/**
 * Contrôleur Hôpital
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class HospitalController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Récupérer les informations principales de l'hôpital
     */
    public function getMainHospitalInfo() {
        try {
            // Récupérer le premier hôpital actif (hôpital principal)
            $stmt = $this->db->prepare(
                'SELECT hospital_id, name, address, city, postal_code, phone, email, website, 
                        established_date, total_beds, emergency_contact, director_name
                 FROM hospitals 
                 WHERE is_active = TRUE
                 LIMIT 1'
            );
            
            if (!$stmt->execute()) {
                Response::error('Erreur lors de la récupération', 500);
            }

            $result = $stmt->get_result();
            
            if ($result->num_rows === 0) {
                Response::notFound('Aucun hôpital trouvé');
            }

            $hospital = $result->fetch_assoc();
            $stmt->close();

            Response::ok($hospital, 'Informations de l\'hôpital récupérées');

        } catch (Exception $e) {
            error_log('Get Hospital Info Error: ' . $e->getMessage());
            Response::error($e->getMessage(), 500);
        }
    }

    /**
     * Récupérer les informations d'un hôpital spécifique
     */
    public function getHospitalById($hospitalId) {
        try {
            $stmt = $this->db->prepare(
                'SELECT hospital_id, name, address, city, postal_code, phone, email, website,
                        established_date, total_beds, emergency_contact, director_name
                 FROM hospitals 
                 WHERE hospital_id = ? AND is_active = TRUE'
            );
            $stmt->bind_param('i', $hospitalId);
            
            if (!$stmt->execute()) {
                Response::error('Erreur lors de la récupération', 500);
            }

            $result = $stmt->get_result();
            
            if ($result->num_rows === 0) {
                Response::notFound('Hôpital non trouvé');
            }

            $hospital = $result->fetch_assoc();
            $stmt->close();

            Response::ok($hospital, 'Informations de l\'hôpital récupérées');

        } catch (Exception $e) {
            error_log('Get Hospital By ID Error: ' . $e->getMessage());
            Response::error($e->getMessage(), 500);
        }
    }

    /**
     * Récupérer tous les hôpitaux actifs
     */
    public function getAllHospitals($page = 1, $limit = 20) {
        try {
            $offset = ($page - 1) * $limit;

            // Compter le total
            $countStmt = $this->db->prepare('SELECT COUNT(*) as total FROM hospitals WHERE is_active = TRUE');
            $countStmt->execute();
            $countResult = $countStmt->get_result();
            $total = $countResult->fetch_assoc()['total'];
            $countStmt->close();

            // Récupérer les hôpitaux
            $stmt = $this->db->prepare(
                'SELECT hospital_id, name, address, city, postal_code, phone, email, website,
                        established_date, total_beds, emergency_contact, director_name
                 FROM hospitals 
                 WHERE is_active = TRUE
                 ORDER BY name ASC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('ii', $limit, $offset);
            
            if (!$stmt->execute()) {
                Response::error('Erreur lors de la récupération', 500);
            }

            $result = $stmt->get_result();
            $hospitals = [];
            
            while ($row = $result->fetch_assoc()) {
                $hospitals[] = $row;
            }
            $stmt->close();

            Response::paginated($hospitals, $total, $page, $limit, 'Hôpitaux récupérés');

        } catch (Exception $e) {
            error_log('Get All Hospitals Error: ' . $e->getMessage());
            Response::error($e->getMessage(), 500);
        }
    }

    /**
     * Récupérer l'hôpital du médecin connecté
     */
    public function getDoctorHospital() {
        try {
            $user = AuthMiddleware::verifyAuth();

            // Récupérer le doctor_id
            $stmt = $this->db->prepare('SELECT doctor_id, hospital_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Médecin non trouvé');
            }

            $doctor = $result->fetch_assoc();
            $hospitalId = $doctor['hospital_id'];
            $stmt->close();

            if (!$hospitalId) {
                Response::notFound('Aucun hôpital associé');
            }

            // Récupérer les infos de l'hôpital
            $stmt = $this->db->prepare(
                'SELECT hospital_id, name, address, city, postal_code, phone, email, website,
                        established_date, total_beds, emergency_contact, director_name
                 FROM hospitals 
                 WHERE hospital_id = ? AND is_active = TRUE'
            );
            $stmt->bind_param('i', $hospitalId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Hôpital non trouvé');
            }

            $hospital = $result->fetch_assoc();
            $stmt->close();

            Response::ok($hospital, 'Informations de l\'hôpital du médecin récupérées');

        } catch (Exception $e) {
            error_log('Get Doctor Hospital Error: ' . $e->getMessage());
            Response::error($e->getMessage(), 500);
        }
    }
}
?>
