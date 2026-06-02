<?php
/**
 * Contrôleur Dossier Médical
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class MedicalDossierController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Normaliser l'URL publique d'un fichier à partir de son chemin en base
     */
    private function normalizeFileUrl($filePath) {
        $filePath = trim(str_replace('\\', '/', (string) $filePath));
        if ($filePath === '') {
            return '';
        }

        if (preg_match('/^https?:\/\//i', $filePath)) {
            return $filePath;
        }

        if (strpos($filePath, '/esante/backend/public') === 0 || strpos($filePath, '/backend/public') === 0) {
            return $filePath;
        }

        if (strpos($filePath, '/documents/') === 0 || strpos($filePath, '/uploads/') === 0) {
            return '/esante/backend/public' . $filePath;
        }

        $pos = stripos($filePath, '/backend/public');
        if ($pos !== false) {
            return substr($filePath, $pos);
        }

        $pos = stripos($filePath, 'backend/public');
        if ($pos !== false) {
            return '/' . substr($filePath, $pos);
        }

        return '/esante/backend/public/uploads/documents/' . basename($filePath);
    }

    /**
     * Obtenir le résumé du dossier médical
     */
    public function getSummary($patientId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyPatientAccess($user['user_id'], $patientId, $user['role']);

            // Récupérer les infos du patient
            $stmt = $this->db->prepare(
                'SELECT p.*, mh.medical_conditions, mh.family_history, mh.chronic_diseases, mh.known_allergies
                 FROM patients p
                 LEFT JOIN medical_history mh ON p.patient_id = mh.patient_id
                 WHERE p.patient_id = ?'
            );
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Patient non trouvé');
            }

            $data = $result->fetch_assoc();
            $stmt->close();

            // Formater les données
            $summary = [
                'patient_id' => $data['patient_id'],
                'full_name' => $data['first_name'] . ' ' . $data['last_name'],
                'date_of_birth' => $data['date_of_birth'],
                'gender' => $data['gender'],
                'blood_group' => $data['blood_group'],
                'social_security_number' => $data['social_security_number'],
                'medical_conditions' => $data['medical_conditions'] ? explode(',', $data['medical_conditions']) : [],
                'family_history' => $data['family_history'],
                'chronic_diseases' => $data['chronic_diseases'] ? json_decode($data['chronic_diseases'], true) : [],
                'known_allergies' => $data['known_allergies'] ? json_decode($data['known_allergies'], true) : []
            ];

            Response::success($summary, 'Résumé du dossier médical récupéré');

        } catch (Exception $e) {
            error_log('Get Medical Dossier Summary Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Mettre à jour les antécédents médicaux
     */
    public function updateMedicalHistory() {
        try {
            $user = AuthMiddleware::verifyAuth();
            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $patientId = $input['patient_id'] ?? null;
            if (!$patientId) {
                Response::badRequest('ID patient manquant');
            }

            AuthMiddleware::verifyPatientAccess($user['user_id'], $patientId, $user['role']);

            $validator = new Validator();
            if (!empty($input['blood_group']) && $input['blood_group'] !== 'N/A') {
                $validator->validateBloodGroup($input['blood_group']);
            }

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', HTTP_BAD_REQUEST, $validator->getErrors());
            }

            // Préparer les données
            $medicalConditions = $input['medical_conditions'] ?? '';
            $familyHistory = $input['family_history'] ?? '';
            $bloodGroup = !empty($input['blood_group']) ? $input['blood_group'] : null;
            $chronicDiseases = json_encode($input['chronic_diseases'] ?? []);
            $allergies = json_encode($input['known_allergies'] ?? []);
            $updatedBy = $user['user_id'];
            $now = date('Y-m-d H:i:s');

            // Vérifier si le dossier existe
            $stmt = $this->db->prepare('SELECT medical_history_id FROM medical_history WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                // Insérer
                $stmt = $this->db->prepare(
                    'INSERT INTO medical_history (patient_id, medical_conditions, family_history, blood_group, chronic_diseases, known_allergies, updated_by, created_at, updated_at)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
                );
                $stmt->bind_param('isssssiss', $patientId, $medicalConditions, $familyHistory, $bloodGroup, $chronicDiseases, $allergies, $updatedBy, $now, $now);
            } else {
                // Mettre à jour
                $stmt = $this->db->prepare(
                    'UPDATE medical_history SET medical_conditions = ?, family_history = ?, blood_group = ?, chronic_diseases = ?, known_allergies = ?, updated_by = ?, updated_at = ? WHERE patient_id = ?'
                );
                $stmt->bind_param('sssssiis', $medicalConditions, $familyHistory, $bloodGroup, $chronicDiseases, $allergies, $updatedBy, $now, $patientId);
            }

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }
            $stmt->close();

            // Mettre à jour aussi le groupe sanguin du patient
            if ($bloodGroup) {
                $stmt = $this->db->prepare('UPDATE patients SET blood_group = ? WHERE patient_id = ?');
                $stmt->bind_param('si', $bloodGroup, $patientId);
                $stmt->execute();
                $stmt->close();
            }

            Response::success(null, 'Antécédents médicaux mis à jour');

        } catch (Exception $e) {
            error_log('Update Medical History Error: ' . $e->getMessage());
            Response::error('Erreur lors de la mise à jour: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les consultations du patient
     */
    public function getConsultations($patientId, $page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyPatientAccess($user['user_id'], $patientId, $user['role']);

            $offset = ($page - 1) * $limit;

            error_log('🔍 [getConsultations] Récupération consultations pour patient: ' . $patientId);

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM consultations WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();
            
            error_log('📊 [getConsultations] Total: ' . $total . ' consultations');

            // Récupérer les consultations avec tous les champs importants
            $stmt = $this->db->prepare(
                'SELECT c.consultation_id, c.patient_id, c.doctor_id, c.speciality_id, c.consultation_date, c.consultation_type, c.reason_for_visit, c.chief_complaint, c.diagnosis, c.treatment_plan, c.notes, c.future_date_follow_up, c.consultation_status, c.created_at, c.updated_at, d.first_name as doctor_first_name, d.last_name as doctor_last_name, s.name as speciality_name
                 FROM consultations c
                 LEFT JOIN doctors d ON c.doctor_id = d.doctor_id
                 LEFT JOIN specialities s ON c.speciality_id = s.speciality_id
                 WHERE c.patient_id = ?
                 ORDER BY c.consultation_date DESC, c.created_at DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $consultations = [];
            while ($row = $result->fetch_assoc()) {
                error_log('📋 [getConsultations] Consultation ' . $row['consultation_id'] . ': ' . json_encode($row));
                error_log('✅ [getConsultations] ID: ' . $row['consultation_id'] . ' - Date: ' . ($row['consultation_date'] ?? 'NULL') . ' - Notes: ' . ($row['notes'] ?? 'NULL'));
                $consultations[] = $row;
            }
            $stmt->close();

            error_log('✅ [getConsultations] Total retourné: ' . count($consultations));
            Response::paginated($consultations, $total, $page, $limit, 'Consultations récupérées');

        } catch (Exception $e) {
            error_log('❌ Get Consultations Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les examens du patient
     */
    public function getExams($patientId, $page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyPatientAccess($user['user_id'], $patientId, $user['role']);

            $offset = ($page - 1) * $limit;

            error_log('🔍 [getExams] Récupération examens pour patient: ' . $patientId);

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM exams WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();
            
            error_log('📊 [getExams] Total: ' . $total . ' examens');

            // Récupérer les examens
            $stmt = $this->db->prepare(
                'SELECT e.exam_id, e.patient_id, e.doctor_id, e.speciality_id, e.laboratory_id, e.exam_request_number, e.exam_date, e.exam_type, e.urgency_level, e.observations, e.exam_status, e.result_interpretation, e.result_values, e.result_interpretation_notes, e.created_at, e.updated_at, d.first_name as doctor_first_name, d.last_name as doctor_last_name, l.name as laboratory_name, s.name as speciality_name
                 FROM exams e
                 LEFT JOIN doctors d ON e.doctor_id = d.doctor_id
                 LEFT JOIN laboratories l ON e.laboratory_id = l.laboratory_id
                 LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
                 WHERE e.patient_id = ?
                 ORDER BY e.exam_date DESC, e.created_at DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $exams = [];
            while ($row = $result->fetch_assoc()) {
                error_log('✅ [getExams] ID: ' . $row['exam_id'] . ' - Date: ' . ($row['exam_date'] ?? 'NULL') . ' - Observations: ' . ($row['observations'] ?? 'NULL'));
                $exams[] = $row;
            }
            $stmt->close();
            
            error_log('✅ [getExams] Total retourné: ' . count($exams));

            Response::paginated($exams, $total, $page, $limit, 'Examens récupérés');

        } catch (Exception $e) {
            error_log('❌ Get Exams Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les vaccinations du patient
     */
    public function getVaccinations($patientId, $page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyPatientAccess($user['user_id'], $patientId, $user['role']);

            $offset = ($page - 1) * $limit;

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM vaccinations WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les vaccinations
            $stmt = $this->db->prepare(
                'SELECT v.*, u.full_name as administered_by_name
                 FROM vaccinations v
                 LEFT JOIN users u ON v.administered_by = u.user_id
                 WHERE v.patient_id = ?
                 ORDER BY v.vaccination_date DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $vaccinations = [];
            while ($row = $result->fetch_assoc()) {
                $vaccinations[] = $row;
            }
            $stmt->close();

            Response::paginated($vaccinations, $total, $page, $limit, 'Vaccinations récupérées');

        } catch (Exception $e) {
            error_log('Get Vaccinations Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les documents médicaux du patient
     */
    public function getDocuments($patientId, $page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyPatientAccess($user['user_id'], $patientId, $user['role']);

            $offset = ($page - 1) * $limit;

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM medical_documents WHERE patient_id = ? AND is_available_for_download = TRUE');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les documents
            $stmt = $this->db->prepare(
                'SELECT md.*, u.full_name as uploaded_by_name
                 FROM medical_documents md
                 LEFT JOIN users u ON md.uploaded_by = u.user_id
                 WHERE md.patient_id = ? AND md.is_available_for_download = TRUE
                 ORDER BY md.upload_date DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $documents = [];
            while ($row = $result->fetch_assoc()) {
                $row['file_url'] = $this->normalizeFileUrl($row['file_path'] ?? '');
                $documents[] = $row;
            }
            $stmt->close();

            Response::paginated($documents, $total, $page, $limit, 'Documents récupérés');

        } catch (Exception $e) {
            error_log('Get Documents Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }
}
?>
