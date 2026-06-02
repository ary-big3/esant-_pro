<?php
/**
 * Contrôleur Consultations
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class ConsultationController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Créer une consultation
     */
    public function create() {
        try {
            $user = AuthMiddleware::verifyAuth();

            // Vérifier que l'utilisateur est un médecin
            if ($user['role'] !== ROLE_MEDECIN) {
                Response::forbidden('Seul un médecin peut créer une consultation. Rôle actuel: ' . $user['role']);
            }

            $input = json_decode(file_get_contents('php://input'), true);

            error_log('🔍 [ConsultationController::create] Input reçu: ' . json_encode($input));

            if (!$input) {
                error_log('❌ [ConsultationController::create] JSON invalide');
                Response::badRequest('Données JSON invalides');
            }

            // Mapper les noms de champs du frontend vers le backend
            $input['consultation_date'] = $input['consultation_date'] ?? $input['date'] ?? null;
            $input['reason_for_visit'] = $input['reason_for_visit'] ?? $input['motif'] ?? null;
            $input['chief_complaint'] = $input['chief_complaint'] ?? $input['motif'] ?? null;
            $input['notes'] = $input['notes'] ?? $input['observations'] ?? null;
            $input['diagnosis'] = $input['diagnosis'] ?? $input['diagnostic'] ?? null;
            
            error_log('🔍 [ConsultationController::create] Input reçu: ' . json_encode($input));
            error_log('🔍 [ConsultationController::create] After mapping - consultation_date: ' . ($input['consultation_date'] ?? 'NULL') . ', notes: ' . ($input['notes'] ?? 'NULL') . ', diagnosis: ' . ($input['diagnosis'] ?? 'NULL'));

            $validator = new Validator();
            $validator->validateRequired($input['patient_id'] ?? null, 'patient_id');
            $validator->validateRequired($input['consultation_date'] ?? null, 'consultation_date');

            if ($validator->hasErrors()) {
                $errors = $validator->getErrors();
                $errors['received_patient_id'] = $input['patient_id'] ?? 'NOT_PROVIDED';
                $errors['received_consultation_date'] = $input['consultation_date'] ?? 'NOT_PROVIDED';
                error_log('❌ [ConsultationController::create] Erreurs: ' . json_encode($errors));
                Response::badRequest('Données invalides', HTTP_BAD_REQUEST, $errors);
            }

            // Récupérer le doctor_id
            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Médecin non trouvé');
            }
            $doctorId = $result->fetch_assoc()['doctor_id'];
            $stmt->close();

            // Créer la consultation
            $patientId = $input['patient_id'];
            // Convertir la date ISO 8601 en format MySQL DATETIME
            $consultationDateRaw = $input['consultation_date'];
            $consultationDate = date('Y-m-d H:i:s', strtotime($consultationDateRaw));
            $consultationType = $input['consultation_type'] ?? 'en_personne';
            $reasonForVisit = isset($input['reason_for_visit']) && $input['reason_for_visit'] !== '' ? $input['reason_for_visit'] : 'Consultation de suivi';
            $chiefComplaint = isset($input['chief_complaint']) && $input['chief_complaint'] !== '' ? $input['chief_complaint'] : 'Non spécifié';
            $diagnosis = isset($input['diagnosis']) && $input['diagnosis'] !== '' ? $input['diagnosis'] : 'En cours d\'évaluation';
            $treatmentPlan = isset($input['treatment_plan']) && $input['treatment_plan'] !== '' ? $input['treatment_plan'] : 'Traitement à définir';
            $notes = isset($input['notes']) && $input['notes'] !== '' ? $input['notes'] : 'Aucune note particulière';
            $futureFollowUp = isset($input['future_date_follow_up']) ? $input['future_date_follow_up'] : null;
            $consultationStatus = CONSULTATION_COMPLETED;
            $prescriptionIncluded = $input['prescription_included'] ?? false;
            $specialityId = isset($input['speciality_id']) ? $input['speciality_id'] : null;
            $now = date('Y-m-d H:i:s');
            
            error_log('💾 [ConsultationController::create] Données à sauvegarder:');
            error_log('   - consultation_date: ' . $consultationDate);
            error_log('   - notes: ' . ($notes ?? 'NULL'));
            error_log('   - diagnosis: ' . ($diagnosis ?? 'NULL'));

            $stmt = $this->db->prepare(
                'INSERT INTO consultations (patient_id, doctor_id, speciality_id, consultation_date, consultation_type, reason_for_visit, chief_complaint, diagnosis, treatment_plan, notes, future_date_follow_up, consultation_status, prescription_included, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $prescriptionIncluded = $prescriptionIncluded ? 1 : 0; // Convertir booléen en entier
            $stmt->bind_param('iiisssssssisss', $patientId, $doctorId, $specialityId, $consultationDate, $consultationType, $reasonForVisit, $chiefComplaint, $diagnosis, $treatmentPlan, $notes, $futureFollowUp, $consultationStatus, $prescriptionIncluded, $now);

            if (!$stmt->execute()) {
                error_log('❌ [ConsultationController::create] Erreur INSERT: ' . $this->db->error);
                throw new Exception('Erreur lors de la création de la consultation: ' . $this->db->error);
            }

            $consultationId = $this->db->insert_id;
            $stmt->close();
            
            error_log('✅ [ConsultationController::create] Consultation créée avec ID: ' . $consultationId);

            // Créer une notification
            $this->createNotification($patientId, 'alert', 'Consultation enregistrée', 'Une consultation a été enregistrée', null, null, null);

            Response::created([
                'consultation_id' => $consultationId,
                'status' => $consultationStatus
            ], 'Consultation créée avec succès');

        } catch (Exception $e) {
            error_log('Create Consultation Error: ' . $e->getMessage());
            Response::error('Erreur lors de la création: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les consultations du patient
     */
    public function getPatientConsultations($patientIdParam = null, $page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();

            // Récupérer le patient_id
            if ($user['role'] === ROLE_PATIENT) {
                $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
                $stmt->bind_param('i', $user['user_id']);
                $stmt->execute();
                $result = $stmt->get_result();
                if ($result->num_rows === 0) {
                    Response::badRequest('Profil patient non trouvé');
                }
                $patientId = $result->fetch_assoc()['patient_id'];
                $stmt->close();
            } else if ($user['role'] === ROLE_MEDECIN && $patientIdParam !== null) {
                // Les médecins peuvent accéder aux consultations du patient via l'URL
                $patientId = (int)$patientIdParam;
            } else {
                $patientId = null;
                Response::forbidden('Accès non autorisé aux consultations');
            }

            $offset = ($page - 1) * $limit;

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM consultations WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les consultations
            $stmt = $this->db->prepare(
                'SELECT c.consultation_id, c.patient_id, c.doctor_id, c.speciality_id, c.consultation_date, c.consultation_type, c.reason_for_visit, c.chief_complaint, c.diagnosis, c.treatment_plan, c.notes, c.future_date_follow_up, c.consultation_status, c.created_at, c.updated_at, d.first_name as doctor_first_name, d.last_name as doctor_last_name, s.name as speciality_name
                 FROM consultations c
                 LEFT JOIN doctors d ON c.doctor_id = d.doctor_id
                 LEFT JOIN specialities s ON c.speciality_id = s.speciality_id
                 WHERE c.patient_id = ?
                 ORDER BY c.consultation_date DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $consultations = [];
            while ($row = $result->fetch_assoc()) {
                // Remplacer les null par des valeurs par défaut
                $row['reason_for_visit'] = $row['reason_for_visit'] ?? 'Consultation de suivi';
                $row['chief_complaint'] = $row['chief_complaint'] ?? 'Non spécifié';
                $row['diagnosis'] = $row['diagnosis'] ?? 'En cours d\'évaluation';
                $row['treatment_plan'] = $row['treatment_plan'] ?? 'Traitement à définir';
                $row['notes'] = $row['notes'] ?? 'Aucune note particulière';
                
                error_log('🔍 [getPatientConsultations] Consultation - ID: ' . $row['consultation_id'] . ', Date: ' . ($row['consultation_date'] ?? 'NULL') . ', Notes: ' . ($row['notes'] ?? 'NULL'));
                $consultations[] = $row;
            }
            $stmt->close();
            
            error_log('✅ [getPatientConsultations] Total: ' . count($consultations) . ' consultations retournées');

            Response::paginated($consultations, $total, $page, $limit, 'Consultations récupérées');

        } catch (Exception $e) {
            error_log('Get Consultations Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir une consultation spécifique
     */
    public function getConsultation($consultationId) {
        try {
            $user = AuthMiddleware::verifyAuth();

            $stmt = $this->db->prepare(
                'SELECT c.*, d.first_name as doctor_first_name, d.last_name as doctor_last_name, s.name as speciality_name
                 FROM consultations c
                 LEFT JOIN doctors d ON c.doctor_id = d.doctor_id
                 LEFT JOIN specialities s ON c.speciality_id = s.speciality_id
                 WHERE c.consultation_id = ?'
            );
            $stmt->bind_param('i', $consultationId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Consultation non trouvée');
            }

            $consultation = $result->fetch_assoc();
            $stmt->close();

            // Remplacer les null par des valeurs par défaut
            $consultation['reason_for_visit'] = $consultation['reason_for_visit'] ?? 'Consultation de suivi';
            $consultation['chief_complaint'] = $consultation['chief_complaint'] ?? 'Non spécifié';
            $consultation['diagnosis'] = $consultation['diagnosis'] ?? 'En cours d\'évaluation';
            $consultation['treatment_plan'] = $consultation['treatment_plan'] ?? 'Traitement à définir';
            $consultation['notes'] = $consultation['notes'] ?? 'Aucune note particulière';

            // Vérifier les permissions
            if ($user['role'] === ROLE_PATIENT) {
                $patientStmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
                $patientStmt->bind_param('i', $user['user_id']);
                $patientStmt->execute();
                $patientResult = $patientStmt->get_result();
                if ($patientResult->num_rows === 0 || $patientResult->fetch_assoc()['patient_id'] != $consultation['patient_id']) {
                    Response::forbidden('Accès à cette consultation non autorisé');
                }
                $patientStmt->close();
            }

            Response::success($consultation, 'Consultation récupérée');

        } catch (Exception $e) {
            error_log('Get Consultation Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Mettre à jour une consultation
     */
    public function update($consultationId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            // Construire la requête UPDATE
            $fields = [];
            $params = [];
            $types = '';

            if (isset($input['diagnosis'])) {
                $fields[] = 'diagnosis = ?';
                $params[] = $input['diagnosis'];
                $types .= 's';
            }
            if (isset($input['treatment_plan'])) {
                $fields[] = 'treatment_plan = ?';
                $params[] = $input['treatment_plan'];
                $types .= 's';
            }
            if (isset($input['notes'])) {
                $fields[] = 'notes = ?';
                $params[] = $input['notes'];
                $types .= 's';
            }
            if (isset($input['future_date_follow_up'])) {
                $fields[] = 'future_date_follow_up = ?';
                $params[] = $input['future_date_follow_up'];
                $types .= 's';
            }
            if (isset($input['consultation_status'])) {
                $fields[] = 'consultation_status = ?';
                $params[] = $input['consultation_status'];
                $types .= 's';
            }

            if (empty($fields)) {
                Response::badRequest('Aucune donnée à mettre à jour');
            }

            $updatedAt = date('Y-m-d H:i:s');
            $fields[] = 'updated_at = ?';
            $params[] = $updatedAt;
            $types .= 's';

            $params[] = $consultationId;
            $types .= 'i';

            $query = 'UPDATE consultations SET ' . implode(', ', $fields) . ' WHERE consultation_id = ?';
            $stmt = $this->db->prepare($query);
            $stmt->bind_param($types, ...$params);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }
            $stmt->close();

            Response::success(null, 'Consultation mise à jour avec succès');

        } catch (Exception $e) {
            error_log('Update Consultation Error: ' . $e->getMessage());
            Response::error('Erreur lors de la mise à jour: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Créer une notification
     */
    private function createNotification($userId, $type, $title, $message, $patientId = null, $examId = null, $appointmentId = null) {
        try {
            $createdAt = date('Y-m-d H:i:s');
            $stmt = $this->db->prepare(
                'INSERT INTO notifications (user_id, notification_type, title, message, related_patient_id, related_exam_id, related_appointment_id, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('isssiiis', $userId, $type, $title, $message, $patientId, $examId, $appointmentId, $createdAt);
            $stmt->execute();
            $stmt->close();
        } catch (Exception $e) {
            error_log('Create Notification Error: ' . $e->getMessage());
        }
    }
}
?>
