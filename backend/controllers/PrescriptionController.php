<?php
/**
 * Contrôleur Ordonnances
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class PrescriptionController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Créer une ordonnance
     */
    public function create() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            error_log('🔍 [PrescriptionController::create] Input reçu: ' . json_encode($input));

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['patient_id'] ?? null, 'patient_id');
            $validator->validateRequired($input['medications'] ?? null, 'medications');
            // consultation_id est optionnel

            if ($validator->hasErrors()) {
                $errors = $validator->getErrors();
                $errors['received_patient_id'] = $input['patient_id'] ?? 'NOT_PROVIDED';
                $errors['received_consultation_id'] = $input['consultation_id'] ?? 'NOT_PROVIDED';
                $errors['received_medications'] = !empty($input['medications']) ? 'YES' : 'NO';
                error_log('❌ [PrescriptionController::create] Erreurs: ' . json_encode($errors));
                Response::badRequest('Données invalides', $errors);
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

            $patientId = $input['patient_id'];
            $prescriptionNumber = 'RX-' . date('YmdHis');
            $issueDate = date('Y-m-d');
            $expiryDate = $input['expiry_date'] ?? date('Y-m-d', strtotime('+3 months'));
            $status = PRESCRIPTION_ACTIVE;
            $canShare = false;
            $notes = $input['notes'] ?? null;
            $now = date('Y-m-d H:i:s');

            // Créer une consultation si nécessaire (pour le lien obligatoire)
            $consultationId = $input['consultation_id'] ?? null;
            
            if (!$consultationId) {
                // Créer une consultation automatiquement pour l'ordonnance
                $consultStmt = $this->db->prepare(
                    'INSERT INTO consultations (patient_id, doctor_id, consultation_date, consultation_type, consultation_status, created_at)
                     VALUES (?, ?, ?, ?, ?, ?)'
                );
                $consultationType = 'suivi';
                $consultationStatus = 'completed';
                $consultStmt->bind_param('isssss', $patientId, $doctorId, $now, $consultationType, $consultationStatus, $now);
                
                if (!$consultStmt->execute()) {
                    error_log('❌ [PrescriptionController::create] Erreur création consultation: ' . $this->db->error);
                    throw new Exception('Erreur lors de la création de la consultation');
                }
                
                $consultationId = $this->db->insert_id;
                $consultStmt->close();
                error_log('✅ [PrescriptionController::create] Consultation créée automatiquement: ' . $consultationId);
            }

            $stmt = $this->db->prepare(
                'INSERT INTO prescriptions (consultation_id, patient_id, doctor_id, prescription_number, issue_date, expiry_date, status, notes, can_share, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            // consultation_id est maintenant garanti d'être un entier
            $canShareInt = $canShare ? 1 : 0;
            $stmt->bind_param('iissssssis', $consultationId, $patientId, $doctorId, $prescriptionNumber, $issueDate, $expiryDate, $status, $notes, $canShareInt, $now);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la création de l\'ordonnance');
            }

            $prescriptionId = $this->db->insert_id;
            $stmt->close();

            // Ajouter les médicaments
            if (!empty($input['medications'])) {
                error_log('💊 [PrescriptionController::create] Médicaments à sauvegarder: ' . json_encode($input['medications']));
                foreach ($input['medications'] as $index => $medication) {
                    error_log('💊 [PrescriptionController::create] Traitement médicament $index: ' . json_encode($medication));
                    // Supporter les deux formats (français ET anglais)
                    $medicationName = $medication['medication_name'] ?? $medication['nom'] ?? '';
                    $dosage = !empty($medication['dosage']) ? $medication['dosage'] : '500';
                    $dosageUnit = $medication['dosage_unit'] ?? $medication['unite_dosage'] ?? 'mg';
                    $frequency = !empty($medication['frequency']) ? $medication['frequency'] : (!empty($medication['posologie']) ? $medication['posologie'] : '2x/jour');
                    $duration = !empty($medication['duration']) ? $medication['duration'] : (!empty($medication['duree']) ? $medication['duree'] : '7');
                    $route = $medication['route_of_administration'] ?? $medication['voie_administration'] ?? 'oral';
                    $instructions = $medication['special_instructions'] ?? $medication['instructions'] ?? null;
                    $isEssential = $medication['is_essential'] ?? $medication['essentiel'] ?? false;
                    $sequenceOrder = $index + 1;

                    error_log('💊 [PrescriptionController::create] Après mapping - name: $medicationName, dosage: $dosage, unit: $dosageUnit, freq: $frequency, dur: $duration');

                    if (empty($medicationName)) {
                        error_log('⚠️ [PrescriptionController::create] Nom du médicament vide à l\'index ' . $index . ': ' . json_encode($medication));
                        continue; // Ignorer ce médicament
                    }

                    $stmt = $this->db->prepare(
                        'INSERT INTO prescription_medications (prescription_id, medication_name, dosage, dosage_unit, frequency, duration, route_of_administration, special_instructions, is_essential, sequence_order)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
                    );
                    $stmt->bind_param('isssssssii', $prescriptionId, $medicationName, $dosage, $dosageUnit, $frequency, $duration, $route, $instructions, $isEssential, $sequenceOrder);
                    
                    if (!$stmt->execute()) {
                        error_log('❌ [PrescriptionController::create] Erreur insertion médicament: ' . $this->db->error);
                    }
                    $stmt->close();
                }
            }

            // Créer une notification pour le patient
            $stmtPatientUser = $this->db->prepare('SELECT user_id FROM patients WHERE patient_id = ?');
            $stmtPatientUser->bind_param('i', $patientId);
            $stmtPatientUser->execute();
            $patientUserResult = $stmtPatientUser->get_result();
            if ($patientUserResult->num_rows > 0) {
                $patientUserRow = $patientUserResult->fetch_assoc();
                $patientUserId = $patientUserRow['user_id'];
                $this->createNotification($patientUserId, 'alert', 'Nouvelle ordonnance', 'Une nouvelle ordonnance vous a été prescrite');
            }
            $stmtPatientUser->close();

            // Créer une notification pour le labo (si applicable)
            // Récupérer le laboratoire associé au patient
            $stmtLab = $this->db->prepare(
                'SELECT DISTINCT l.laboratory_id, l.user_id FROM laboratories l
                 INNER JOIN specialities s ON l.laboratory_id = s.laboratory_assignment
                 WHERE s.speciality_id IN (
                    SELECT speciality_id FROM consultations WHERE consultation_id = ?
                 ) LIMIT 1'
            );
            $stmtLab->bind_param('i', $consultationId);
            $stmtLab->execute();
            $labResult = $stmtLab->get_result();
            if ($labResult->num_rows > 0) {
                $labRow = $labResult->fetch_assoc();
                $labUserId = $labRow['user_id'];
                $this->createNotification($labUserId, 'alert', 'Nouvelle ordonnance', 'Une ordonnance a été envoyée et nécessite une validation');
            }
            $stmtLab->close();

            Response::created([
                'prescription_id' => $prescriptionId,
                'prescription_number' => $prescriptionNumber,
                'status' => $status
            ], 'Ordonnance créée avec succès');

        } catch (Exception $e) {
            error_log('Create Prescription Error: ' . $e->getMessage());
            Response::error('Erreur lors de la création: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les ordonnances du patient
     */
    public function getPatientPrescriptions($page = 1, $limit = DEFAULT_PAGE_SIZE) {
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
            } else {
                $patientId = null;
                // TODO: Implémenter l'accès pour les médecins/infirmières
            }

            $offset = ($page - 1) * $limit;

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM prescriptions WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les ordonnances avec les médicaments
            $stmt = $this->db->prepare(
                'SELECT p.*, d.first_name as doctor_first_name, d.last_name as doctor_last_name
                 FROM prescriptions p
                 LEFT JOIN doctors d ON p.doctor_id = d.doctor_id
                 WHERE p.patient_id = ?
                 ORDER BY p.created_at DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $prescriptions = [];
            while ($row = $result->fetch_assoc()) {
                // Récupérer les médicaments de cette ordonnance - TOUS les champs nécessaires
                $stmt2 = $this->db->prepare(
                    'SELECT medication_id, medication_name, dosage, dosage_unit, frequency, duration, route_of_administration, special_instructions, is_essential FROM prescription_medications WHERE prescription_id = ? ORDER BY sequence_order'
                );
                $stmt2->bind_param('i', $row['prescription_id']);
                $stmt2->execute();
                $resultMed = $stmt2->get_result();

                $medications = [];
                while ($med = $resultMed->fetch_assoc()) {
                    // Remplacer les valeurs vides par des valeurs par défaut
                    if (empty($med['dosage'])) $med['dosage'] = '500';
                    if (empty($med['frequency'])) $med['frequency'] = '2x/jour';
                    if (empty($med['duration'])) $med['duration'] = '7';
                    $medications[] = $med;
                }
                $stmt2->close();

                $row['medications'] = $medications;
                $prescriptions[] = $row;
            }
            $stmt->close();

            Response::paginated($prescriptions, $total, $page, $limit, 'Ordonnances récupérées');

        } catch (Exception $e) {
            error_log('Get Prescriptions Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les ordonnances d'un patient spécifique (par médecin)
     */
    public function getPatientPrescriptionsById($patientId, $page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();

            $offset = ($page - 1) * $limit;

            error_log('🔍 [getPatientPrescriptionsById] Récupération ordonnances pour patient: ' . $patientId);

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM prescriptions WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();
            
            error_log('📊 [getPatientPrescriptionsById] Total ordonnances: ' . $total);

            // Récupérer les ordonnances avec les médicaments
            $stmt = $this->db->prepare(
                'SELECT p.prescription_id, p.patient_id, p.doctor_id, p.consultation_id, p.prescription_date, p.prescription_number, p.status, p.issue_date, p.expiry_date, p.notes, p.can_share, p.created_at, p.updated_at, d.first_name as doctor_first_name, d.last_name as doctor_last_name,
                        h.name as hospital_name, h.address as hospital_address, h.phone as hospital_phone, h.email as hospital_email,
                        s.name as speciality_name
                 FROM prescriptions p
                 LEFT JOIN doctors d ON p.doctor_id = d.doctor_id
                 LEFT JOIN hospitals h ON d.hospital_id = h.hospital_id
                 LEFT JOIN consultations c ON p.consultation_id = c.consultation_id
                 LEFT JOIN specialities s ON c.speciality_id = s.speciality_id
                 WHERE p.patient_id = ?
                 ORDER BY p.prescription_date DESC, p.created_at DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $prescriptions = [];
            while ($row = $result->fetch_assoc()) {
                // Récupérer les médicaments de cette ordonnance - TOUS les champs nécessaires
                $stmt2 = $this->db->prepare(
                    'SELECT medication_id, medication_name, dosage, dosage_unit, frequency, duration, route_of_administration, special_instructions, is_essential FROM prescription_medications WHERE prescription_id = ? ORDER BY sequence_order'
                );
                $stmt2->bind_param('i', $row['prescription_id']);
                $stmt2->execute();
                $resultMed = $stmt2->get_result();

                $medications = [];
                while ($med = $resultMed->fetch_assoc()) {
                    // Remplacer les valeurs vides par des valeurs par défaut
                    if (empty($med['dosage'])) $med['dosage'] = '500';
                    if (empty($med['frequency'])) $med['frequency'] = '2x/jour';
                    if (empty($med['duration'])) $med['duration'] = '7';
                    $medications[] = $med;
                }
                $stmt2->close();

                error_log('📦 [getPatientPrescriptionsById] Prescription ' . $row['prescription_id'] . ' médicaments: ' . json_encode($medications));
                $row['medications'] = $medications;
                error_log('✅ [getPatientPrescriptionsById] Prescription ' . $row['prescription_id'] . ' - Date: ' . ($row['prescription_date'] ?? $row['created_at']) . ' - Médicaments: ' . count($medications));
                $prescriptions[] = $row;
            }
            $stmt->close();

            Response::paginated($prescriptions, $total, $page, $limit, 'Ordonnances du patient récupérées');

        } catch (Exception $e) {
            error_log('❌ [getPatientPrescriptionsById] Erreur: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir une ordonnance spécifique
     */
    public function getPrescription($prescriptionId) {
        try {
            $user = AuthMiddleware::verifyAuth();

            $stmt = $this->db->prepare(
                'SELECT p.*, d.first_name as doctor_first_name, d.last_name as doctor_last_name
                 FROM prescriptions p
                 LEFT JOIN doctors d ON p.doctor_id = d.doctor_id
                 WHERE p.prescription_id = ?'
            );
            $stmt->bind_param('i', $prescriptionId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Ordonnance non trouvée');
            }

            $prescription = $result->fetch_assoc();
            $stmt->close();

            // Vérifier les permissions
            if ($user['role'] === ROLE_PATIENT) {
                $patientStmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
                $patientStmt->bind_param('i', $user['user_id']);
                $patientStmt->execute();
                $patientResult = $patientStmt->get_result();
                if ($patientResult->num_rows === 0 || $patientResult->fetch_assoc()['patient_id'] != $prescription['patient_id']) {
                    Response::forbidden('Accès à cette ordonnance non autorisé');
                }
                $patientStmt->close();
            }

            // Récupérer les médicaments
            $stmt = $this->db->prepare(
                'SELECT * FROM prescription_medications WHERE prescription_id = ? ORDER BY sequence_order'
            );
            $stmt->bind_param('i', $prescriptionId);
            $stmt->execute();
            $result = $stmt->get_result();

            $medications = [];
            while ($row = $result->fetch_assoc()) {
                $medications[] = $row;
            }
            $stmt->close();

            $prescription['medications'] = $medications;

            Response::success($prescription, 'Ordonnance récupérée');

        } catch (Exception $e) {
            error_log('Get Prescription Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Mettre à jour une ordonnance et remplacer ses médicaments
     */
    public function updatePrescription($prescriptionId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);
            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['patient_id'] ?? null, 'patient_id');
            $validator->validateRequired($input['medications'] ?? null, 'medications');

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', $validator->getErrors());
            }

            $stmt = $this->db->prepare('SELECT doctor_id, patient_id FROM prescriptions WHERE prescription_id = ?');
            $stmt->bind_param('i', $prescriptionId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Ordonnance non trouvée');
            }
            $prescriptionRow = $result->fetch_assoc();
            $stmt->close();

            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Accès refusé');
            }
            $currentDoctorId = $result->fetch_assoc()['doctor_id'];
            $stmt->close();

            if ($prescriptionRow['doctor_id'] !== $currentDoctorId) {
                Response::forbidden('Vous ne pouvez pas modifier cette ordonnance');
            }

            $patientId = $input['patient_id'];
            $notes = $input['notes'] ?? $prescriptionRow['notes'] ?? null;
            $status = $input['status'] ?? PRESCRIPTION_ACTIVE;
            $updatedAt = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare(
                'UPDATE prescriptions SET patient_id = ?, notes = ?, status = ?, updated_at = ? WHERE prescription_id = ?'
            );
            $stmt->bind_param('isssi', $patientId, $notes, $status, $updatedAt, $prescriptionId);
            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour de l\'ordonnance');
            }
            $stmt->close();

            $stmt = $this->db->prepare('DELETE FROM prescription_medications WHERE prescription_id = ?');
            $stmt->bind_param('i', $prescriptionId);
            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la suppression des anciens médicaments');
            }
            $stmt->close();

            $medications = $input['medications'];
            $sequenceOrder = 1;
            foreach ($medications as $medication) {
                $medicationName = $medication['medication_name'] ?? $medication['nom'] ?? '';
                if (empty($medicationName)) {
                    continue;
                }
                $dosage = $medication['dosage'] ?? '500';
                $dosageUnit = $medication['dosage_unit'] ?? $medication['unite_dosage'] ?? 'mg';
                $frequency = $medication['frequency'] ?? $medication['posologie'] ?? '2x/jour';
                $duration = $medication['duration'] ?? $medication['duree'] ?? '7';
                $route = $medication['route_of_administration'] ?? $medication['voie_administration'] ?? 'oral';
                $instructions = $medication['special_instructions'] ?? $medication['instructions'] ?? null;
                $isEssential = isset($medication['is_essential']) ? (int)$medication['is_essential'] : 0;
                $refMedicationId = $medication['medication_id'] ? (int)$medication['medication_id'] : null;

                $stmt = $this->db->prepare(
                    'INSERT INTO prescription_medications (prescription_id, ref_medication_id, medication_name, dosage, dosage_unit, frequency, duration, route_of_administration, special_instructions, is_essential, sequence_order)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
                );
                $stmt->bind_param('iissssissii', $prescriptionId, $refMedicationId, $medicationName, $dosage, $dosageUnit, $frequency, $duration, $route, $instructions, $isEssential, $sequenceOrder);
                if (!$stmt->execute()) {
                    error_log('❌ [PrescriptionController::updatePrescription] Erreur insertion médicament: ' . $this->db->error);
                }
                $stmt->close();
                $sequenceOrder++;
            }

            Response::success([], 'Ordonnance mise à jour avec succès');

        } catch (Exception $e) {
            error_log('Update Prescription Error: ' . $e->getMessage());
            Response::error('Erreur lors de la mise à jour: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Ajouter un médicament prédéfini à une prescription
     */
    public function addPrescriptionMedication($prescriptionId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['ref_medication_id'] ?? null, 'ref_medication_id');

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', $validator->getErrors());
            }

            // Vérifier que la prescription existe et que le médecin est propriétaire
            $stmt = $this->db->prepare('SELECT doctor_id FROM prescriptions WHERE prescription_id = ?');
            $stmt->bind_param('i', $prescriptionId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Ordonnance non trouvée');
            }
            $prescriptionRow = $result->fetch_assoc();
            $stmt->close();

            // Vérifier l'autorisation
            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Accès refusé');
            }
            $currentDoctorId = $result->fetch_assoc()['doctor_id'];
            $stmt->close();

            if ($prescriptionRow['doctor_id'] !== $currentDoctorId) {
                Response::forbidden('Vous ne pouvez pas modifier cette ordonnance');
            }

            $refMedicationId = $input['ref_medication_id'];
            
            // Récupérer le médicament de référence
            $stmt = $this->db->prepare(
                'SELECT * FROM medication WHERE medication_id = ? AND is_active = 1'
            );
            $stmt->bind_param('i', $refMedicationId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Médicament non trouvé');
            }
            $medication = $result->fetch_assoc();
            $stmt->close();

            // Récupérer le numéro de séquence suivant
            $stmt = $this->db->prepare(
                'SELECT MAX(sequence_order) as max_order FROM prescription_medications WHERE prescription_id = ?'
            );
            $stmt->bind_param('i', $prescriptionId);
            $stmt->execute();
            $result = $stmt->get_result();
            $sequenceRow = $result->fetch_assoc();
            $sequenceOrder = ($sequenceRow['max_order'] ?? 0) + 1;
            $stmt->close();

            // Gérer les personnalisations optionnelles
            $dosage = $input['dosage'] ?? $medication['dosage'];
            $dosageUnit = $input['dosage_unit'] ?? $medication['dosage_unit'];
            $frequency = $input['frequency'] ?? $medication['frequency'];
            $duration = $input['duration'] ?? $medication['default_duration'];
            $route = $input['route_of_administration'] ?? $medication['route_of_administration'];
            $instructions = $input['special_instructions'] ?? null;
            $isEssential = isset($input['is_essential']) ? (int)$input['is_essential'] : 0;

            // Ajouter le médicament à la prescription
            $stmt = $this->db->prepare(
                'INSERT INTO prescription_medications (prescription_id, ref_medication_id, medication_name, dosage, dosage_unit, frequency, duration, route_of_administration, special_instructions, is_essential, sequence_order)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('iissssissii', $prescriptionId, $refMedicationId, $medication['medication_name'], $dosage, $dosageUnit, $frequency, $duration, $route, $instructions, $isEssential, $sequenceOrder);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de l\'ajout du médicament');
            }

            $medicationId = $this->db->insert_id;
            $stmt->close();

            Response::created([
                'medication_id' => $medicationId,
                'ref_medication_id' => $refMedicationId,
                'medication_name' => $medication['medication_name']
            ], 'Médicament ajouté avec succès');

        } catch (Exception $e) {
            error_log('Add Prescription Medication Error: ' . $e->getMessage());
            Response::error('Erreur lors de l\'ajout: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Retirer un médicament d'une prescription
     */
    public function removePrescriptionMedication($prescriptionId, $medicationId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            // Vérifier que la prescription existe et que le médecin est propriétaire
            $stmt = $this->db->prepare('SELECT doctor_id FROM prescriptions WHERE prescription_id = ?');
            $stmt->bind_param('i', $prescriptionId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Ordonnance non trouvée');
            }
            $prescriptionRow = $result->fetch_assoc();
            $stmt->close();

            // Vérifier l'autorisation
            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Accès refusé');
            }
            $currentDoctorId = $result->fetch_assoc()['doctor_id'];
            $stmt->close();

            if ($prescriptionRow['doctor_id'] !== $currentDoctorId) {
                Response::forbidden('Vous ne pouvez pas modifier cette ordonnance');
            }

            // Supprimer le médicament
            $stmt = $this->db->prepare(
                'DELETE FROM prescription_medications WHERE medication_id = ? AND prescription_id = ?'
            );
            $stmt->bind_param('ii', $medicationId, $prescriptionId);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la suppression du médicament');
            }

            if ($stmt->affected_rows === 0) {
                Response::notFound('Médicament non trouvé dans cette ordonnance');
            }

            $stmt->close();

            Response::success([], 'Médicament retiré avec succès');

        } catch (Exception $e) {
            error_log('Remove Prescription Medication Error: ' . $e->getMessage());
            Response::error('Erreur lors de la suppression: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Créer rapidement une prescription à partir de médicaments sélectionnés
     */
    public function quickCreateFromMedications() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['patient_id'] ?? null, 'patient_id');
            $validator->validateRequired($input['medication_ids'] ?? null, 'medication_ids');

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', $validator->getErrors());
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

            $patientId = $input['patient_id'];
            $medicationIds = $input['medication_ids'];
            $prescriptionNumber = 'RX-' . date('YmdHis');
            $issueDate = date('Y-m-d');
            $expiryDate = $input['expiry_date'] ?? date('Y-m-d', strtotime('+3 months'));
            $status = PRESCRIPTION_ACTIVE;
            $notes = $input['notes'] ?? null;
            $now = date('Y-m-d H:i:s');

            // Créer une consultation automatiquement
            $consultStmt = $this->db->prepare(
                'INSERT INTO consultations (patient_id, doctor_id, consultation_date, consultation_type, consultation_status, created_at)
                 VALUES (?, ?, ?, ?, ?, ?)'
            );
            $consultationType = 'suivi';
            $consultationStatus = 'completed';
            $consultStmt->bind_param('isssss', $patientId, $doctorId, $now, $consultationType, $consultationStatus, $now);

            if (!$consultStmt->execute()) {
                throw new Exception('Erreur lors de la création de la consultation');
            }

            $consultationId = $this->db->insert_id;
            $consultStmt->close();

            // Créer la prescription
            $stmt = $this->db->prepare(
                'INSERT INTO prescriptions (consultation_id, patient_id, doctor_id, prescription_number, issue_date, expiry_date, status, notes, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('iisssssss', $consultationId, $patientId, $doctorId, $prescriptionNumber, $issueDate, $expiryDate, $status, $notes, $now);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la création de l\'ordonnance');
            }

            $prescriptionId = $this->db->insert_id;
            $stmt->close();

            // Ajouter les médicaments sélectionnés
            $addedMedications = [];
            foreach ($medicationIds as $index => $medId) {
                $medId = (int)$medId;
                
                // Récupérer le médicament
                $stmt = $this->db->prepare(
                    'SELECT * FROM medication WHERE medication_id = ? AND is_active = 1'
                );
                $stmt->bind_param('i', $medId);
                $stmt->execute();
                $result = $stmt->get_result();
                
                if ($result->num_rows === 0) {
                    error_log("⚠️ Médicament $medId non trouvé");
                    $stmt->close();
                    continue;
                }

                $medication = $result->fetch_assoc();
                $stmt->close();

                $sequenceOrder = $index + 1;
                $dosage = $medication['dosage'];
                $dosageUnit = $medication['dosage_unit'];
                $frequency = $medication['frequency'];
                $duration = $medication['default_duration'];
                $route = $medication['route_of_administration'];

                // Ajouter le médicament à la prescription
                $stmt = $this->db->prepare(
                    'INSERT INTO prescription_medications (prescription_id, ref_medication_id, medication_name, dosage, dosage_unit, frequency, duration, route_of_administration, sequence_order)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
                );
                $stmt->bind_param('iisssssii', $prescriptionId, $medId, $medication['medication_name'], $dosage, $dosageUnit, $frequency, $duration, $route, $sequenceOrder);

                if ($stmt->execute()) {
                    $addedMedications[] = [
                        'medication_id' => $medId,
                        'medication_name' => $medication['medication_name']
                    ];
                }
                $stmt->close();
            }

            // Créer une notification pour le patient
            $stmtPatientUser = $this->db->prepare('SELECT user_id FROM patients WHERE patient_id = ?');
            $stmtPatientUser->bind_param('i', $patientId);
            $stmtPatientUser->execute();
            $patientUserResult = $stmtPatientUser->get_result();
            if ($patientUserResult->num_rows > 0) {
                $patientUserRow = $patientUserResult->fetch_assoc();
                $patientUserId = $patientUserRow['user_id'];
                $this->createNotification($patientUserId, 'alert', 'Nouvelle ordonnance', 'Une nouvelle ordonnance vous a été prescrite');
            }
            $stmtPatientUser->close();

            Response::created([
                'prescription_id' => $prescriptionId,
                'prescription_number' => $prescriptionNumber,
                'status' => $status,
                'medications_added' => count($addedMedications),
                'medications' => $addedMedications
            ], 'Ordonnance créée avec succès');

        } catch (Exception $e) {
            error_log('Quick Create Prescription Error: ' . $e->getMessage());
            Response::error('Erreur lors de la création: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }
    /**
     * Mettre à jour le statut d'une ordonnance
     */
    public function updateStatus($prescriptionId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['status'] ?? null, 'status');
            $validator->validateEnum($input['status'], ['active', 'expired', 'completed', 'cancelled'], 'status');

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', $validator->getErrors());
            }

            $status = $input['status'];
            $updatedAt = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare('UPDATE prescriptions SET status = ?, updated_at = ? WHERE prescription_id = ?');
            $stmt->bind_param('ssi', $status, $updatedAt, $prescriptionId);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }
            $stmt->close();

            Response::success(null, 'Statut de l\'ordonnance mis à jour');

        } catch (Exception $e) {
            error_log('Update Prescription Status Error: ' . $e->getMessage());
            Response::error('Erreur lors de la mise à jour: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Créer une notification
     */
    private function createNotification($userId, $type, $title, $message) {
        try {
            $createdAt = date('Y-m-d H:i:s');
            $stmt = $this->db->prepare(
                'INSERT INTO notifications (user_id, notification_type, title, message, created_at)
                 VALUES (?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('issss', $userId, $type, $title, $message, $createdAt);
            $stmt->execute();
            $stmt->close();
        } catch (Exception $e) {
            error_log('Create Notification Error: ' . $e->getMessage());
        }
    }
}
?>
