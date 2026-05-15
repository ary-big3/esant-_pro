<?php
/**
 * Contrôleur Rendez-vous
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class AppointmentController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Créer un rendez-vous
     */
    public function create() {
        try {
            $user = AuthMiddleware::verifyAuth();
            $input = json_decode(file_get_contents('php://input'), true);

            error_log('CREATE APPOINTMENT - Input received: ' . json_encode($input));

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['appointment_date'] ?? null, 'appointment_date');
            $validator->validateDateTime($input['appointment_date'] ?? null, 'appointment_date');

            if ($validator->hasErrors()) {
                error_log('Validation errors: ' . json_encode($validator->getErrors()));
                Response::badRequest('Données invalides', $validator->getErrors());
            }

            // Récupérer le patient_id et doctor_id selon le rôle
            if ($user['role'] === ROLE_PATIENT) {
                // Un patient crée un rendez-vous pour lui-même avec un médecin spécifique
                $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
                $stmt->bind_param('i', $user['user_id']);
                $stmt->execute();
                $result = $stmt->get_result();
                if ($result->num_rows === 0) {
                    Response::badRequest('Profil patient non trouvé');
                }
                $patientId = $result->fetch_assoc()['patient_id'];
                $stmt->close();

                // Le doctor_id doit être fourni par le patient
                $doctorId = $input['doctor_id'] ?? null;
                if (!$doctorId) {
                    Response::badRequest('ID médecin manquant');
                }
            } elseif ($user['role'] === ROLE_MEDECIN) {
                // Un médecin c$rée un rendez-vous - récupère automatiquement son ID
                $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
                $stmt->bind_param('i', $user['user_id']);
                $stmt->execute();
                $result = $stmt->get_result();
                if ($result->num_rows === 0) {
                    Response::badRequest('Profil médecin non trouvé');
                }
                $doctorId = $result->fetch_assoc()['doctor_id'];
                $stmt->close();

                // Le patient_id doit être fourni par le médecin
                $patientId = $input['patient_id'] ?? null;
                if (!$patientId) {
                    Response::badRequest('ID patient manquant');
                }
            } else {
                Response::forbidden('Seuls les patients et médecins peuvent créer des rendez-vous');
            }

            // Vérifier que le patient existe
            $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                Response::badRequest('Patient non trouvé', HTTP_NOT_FOUND);
            }
            $stmt->close();

            // Vérifier que le médecin existe
            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE doctor_id = ?');
            $stmt->bind_param('i', $doctorId);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                Response::badRequest('Médecin non trouvé', HTTP_NOT_FOUND);
            }
            $stmt->close();

            // Créer le rendez-vous
            $appointmentStatus = STATUS_PENDING;
            $appointmentDate = $input['appointment_date'];
            $duration = $input['appointment_duration_minutes'] ?? 30;
            $specialityId = $input['speciality_id'] ?? null;
            $hospitalId = $input['hospital_id'] ?? null;
            $appointmentType = $input['appointment_type'] ?? 'consultation';
            $reason = $input['reason_for_appointment'] ?? null;
            $notes = $input['notes'] ?? null;
            $createdAt = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare(
                'INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_duration_minutes, speciality_id, hospital_id, appointment_type, reason_for_appointment, notes, status, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            // Types: i=int, s=string
            // Order: patientId(i), doctorId(i), appointmentDate(s), duration(i), specialityId(i), hospitalId(i), appointmentType(s), reason(s), notes(s), status(s), createdAt(s)
            $stmt->bind_param('iisiiisssss', $patientId, $doctorId, $appointmentDate, $duration, $specialityId, $hospitalId, $appointmentType, $reason, $notes, $appointmentStatus, $createdAt);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la création du rendez-vous');
            }

            $appointmentId = $this->db->insert_id;
            $stmt->close();

            // Créer une notification pour le médecin
            // Récupérer le user_id du docteur
            $stmtDoctorUser = $this->db->prepare('SELECT user_id FROM doctors WHERE doctor_id = ?');
            $stmtDoctorUser->bind_param('i', $doctorId);
            $stmtDoctorUser->execute();
            $doctorUserResult = $stmtDoctorUser->get_result();
            if ($doctorUserResult->num_rows > 0) {
                $doctorUser = $doctorUserResult->fetch_assoc();
                $doctorUserId = $doctorUser['user_id'];
                $this->createNotification($doctorUserId, 'appointment_reminder', 'Nouveau rendez-vous', 'Un nouveau rendez-vous a été programmé', $patientId, null, $appointmentId);
            }
            $stmtDoctorUser->close();
            
            // Créer une notification pour le patient
            // Récupérer le user_id du patient pour la notification
            $stmtPatient = $this->db->prepare('SELECT user_id FROM patients WHERE patient_id = ?');
            $stmtPatient->bind_param('i', $patientId);
            $stmtPatient->execute();
            $resultPatient = $stmtPatient->get_result();
            if ($resultPatient->num_rows > 0) {
                $patientUser = $resultPatient->fetch_assoc();
                $patientUserId = $patientUser['user_id'];
                // Créer notification pour le patient avec le nom du médecin
                $stmt2 = $this->db->prepare('SELECT first_name, last_name FROM doctors WHERE doctor_id = ?');
                $stmt2->bind_param('i', $doctorId);
                $stmt2->execute();
                $doctorResult = $stmt2->get_result();
                if ($doctorResult->num_rows > 0) {
                    $doctor = $doctorResult->fetch_assoc();
                    $doctorName = $doctor['first_name'] . ' ' . $doctor['last_name'];
                    $this->createNotification($patientUserId, 'appointment_scheduled', 'Rendez-vous programmé', 'Un rendez-vous a été programmé avec Dr. ' . $doctorName, null, null, $appointmentId);
                }
                $stmt2->close();
            }
            $stmtPatient->close();

            Response::created([
                'appointment_id' => $appointmentId,
                'status' => $appointmentStatus
            ], 'Rendez-vous créé avec succès');

        } catch (Exception $e) {
            error_log('Create Appointment Error: ' . $e->getMessage());
            Response::error('Erreur lors de la création: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les rendez-vous du patient
     */
    public function getPatientAppointments($page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);

            // Récupérer le patient_id
            $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::badRequest('Profil patient non trouvé');
            }
            $patientId = $result->fetch_assoc()['patient_id'];
            $stmt->close();

            $offset = ($page - 1) * $limit;

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM appointments WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les rendez-vous
            $stmt = $this->db->prepare(
                'SELECT a.*, d.first_name as doctor_first_name, d.last_name as doctor_last_name, s.name as speciality_name, h.name as hospital_name
                 FROM appointments a
                 LEFT JOIN doctors d ON a.doctor_id = d.doctor_id
                 LEFT JOIN specialities s ON a.speciality_id = s.speciality_id
                 LEFT JOIN hospitals h ON a.hospital_id = h.hospital_id
                 WHERE a.patient_id = ?
                 ORDER BY a.appointment_date DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $appointments = [];
            while ($row = $result->fetch_assoc()) {
                $appointments[] = $row;
            }
            $stmt->close();

            Response::paginated($appointments, $total, $page, $limit, 'Rendez-vous récupérés');

        } catch (Exception $e) {
            error_log('Get Appointments Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les rendez-vous d'un médecin
     */
    public function getDoctorAppointments($doctorId, $page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            
            if ($user['role'] === ROLE_MEDECIN) {
                // Vérifier que le médecin ne voit que ses propres rendez-vous
                // TODO: Implémenter une vérification appropriée
            }

            $offset = ($page - 1) * $limit;

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM appointments WHERE doctor_id = ?');
            $stmt->bind_param('i', $doctorId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les rendez-vous
            $stmt = $this->db->prepare(
                'SELECT a.*, p.first_name as patient_first_name, p.last_name as patient_last_name, s.name as speciality_name, h.name as hospital_name
                 FROM appointments a
                 LEFT JOIN patients p ON a.patient_id = p.patient_id
                 LEFT JOIN specialities s ON a.speciality_id = s.speciality_id
                 LEFT JOIN hospitals h ON a.hospital_id = h.hospital_id
                 WHERE a.doctor_id = ?
                 ORDER BY a.appointment_date DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $doctorId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $appointments = [];
            while ($row = $result->fetch_assoc()) {
                $appointments[] = $row;
            }
            $stmt->close();

            Response::paginated($appointments, $total, $page, $limit, 'Rendez-vous du médecin récupérés');

        } catch (Exception $e) {
            error_log('Get Doctor Appointments Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Mettre à jour le statut d'un rendez-vous
     */
    public function updateStatus($appointmentId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['status'] ?? null, 'status');
            $validator->validateEnum($input['status'], ['confirmed', 'pending', 'completed', 'cancelled', 'no_show'], 'status');

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', $validator->getErrors());
            }

            $status = $input['status'];
            $updatedAt = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare('UPDATE appointments SET status = ?, updated_at = ? WHERE appointment_id = ?');
            $stmt->bind_param('ssi', $status, $updatedAt, $appointmentId);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }
            $stmt->close();

            Response::success(null, 'Statut du rendez-vous mis à jour');

        } catch (Exception $e) {
            error_log('Update Appointment Status Error: ' . $e->getMessage());
            Response::error('Erreur lors de la mise à jour: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Créer une demande de rendez-vous (par spécialité, pas par médecin spécifique)
     */
    public function createAppointmentRequest() {
        try {
            error_log('[createAppointmentRequest] START');
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_PATIENT, $user['role']);
            
            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            error_log('[createAppointmentRequest] Input: ' . json_encode($input));

            $validator = new Validator();
            $validator->validateRequired($input['appointment_date'] ?? null, 'appointment_date');
            $validator->validateDateTime($input['appointment_date'] ?? null, 'appointment_date');
            $validator->validateRequired($input['speciality'] ?? null, 'speciality');

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', $validator->getErrors());
            }

            // Récupérer le patient_id
            $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::badRequest('Profil patient non trouvé');
            }
            $patientId = $result->fetch_assoc()['patient_id'];
            $stmt->close();

            error_log('[createAppointmentRequest] Patient ID: ' . $patientId);

            // Récupérer la spécialité
            $specialityName = $input['speciality'];
            $stmt = $this->db->prepare('SELECT speciality_id FROM specialities WHERE name = ?');
            $stmt->bind_param('s', $specialityName);
            $stmt->execute();
            $result = $stmt->get_result();
            $specialityId = 0; // Initialiser à 0 par défaut
            if ($result->num_rows > 0) {
                $specialityId = $result->fetch_assoc()['speciality_id'];
            }
            $stmt->close();

            error_log('[createAppointmentRequest] Speciality ID: ' . $specialityId);

            // Créer la demande de rendez-vous
            $appointmentDate = $input['appointment_date'];
            $appointmentType = $input['appointment_type'] ?? 'consultation';
            $reason = $input['reason_for_appointment'] ?? ''; // Convertir null en string vide
            $notes = $input['notes'] ?? ''; // Convertir null en string vide
            $appointmentDuration = $input['appointment_duration_minutes'] ?? 30;
            $createdAt = date('Y-m-d H:i:s');
            $status = 'pending';

            error_log('[createAppointmentRequest] Creating appointment request');

            $stmt = $this->db->prepare(
                'INSERT INTO appointment_requests (patient_id, speciality_id, appointment_date, appointment_duration_minutes, appointment_type, reason_for_appointment, notes, status, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('iisisssss', $patientId, $specialityId, $appointmentDate, $appointmentDuration, $appointmentType, $reason, $notes, $status, $createdAt);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la création de la demande');
            }

            $requestId = $this->db->insert_id;
            $stmt->close();

            // Récupérer tous les médecins avec cette spécialité
            $stmt = $this->db->prepare(
                'SELECT doctor_id, user_id, first_name, last_name FROM doctors WHERE speciality = ?'
            );
            $stmt->bind_param('s', $specialityName);
            $stmt->execute();
            $result = $stmt->get_result();

            $doctorIds = [];
            while ($row = $result->fetch_assoc()) {
                $doctorIds[] = $row;
            }
            $stmt->close();
            
            error_log('[createAppointmentRequest] Found ' . count($doctorIds) . ' doctors for speciality: ' . $specialityName);

            // Créer un appointment pour CHAQUE médecin avec cette spécialité
            foreach ($doctorIds as $doctor) {
                $doctorId = $doctor['doctor_id'];
                
                $stmt = $this->db->prepare(
                    'INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_duration_minutes, speciality_id, appointment_type, reason_for_appointment, notes, status, appointment_request_id, created_at)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
                );
                
                $appointmentStatus = 'pending';
                $stmt->bind_param('iisiissssis', $patientId, $doctorId, $appointmentDate, $appointmentDuration, $specialityId, $appointmentType, $reason, $notes, $appointmentStatus, $requestId, $createdAt);
                $stmt->execute();
                
                // Récupérer l'ID du rendez-vous créé
                $appointmentId = $this->db->insert_id;
                $stmt->close();

                // Créer une notification pour le médecin avec l'appointment_id
                $this->createNotification(
                    $doctor['user_id'], 
                    'appointment_reminder', 
                    'Nouvelle demande de rendez-vous', 
                    'Un patient demande un rendez-vous en ' . $specialityName, 
                    $patientId, 
                    null, 
                    $appointmentId
                );
            }

            // Créer une notification pour le patient
            $stmtPatient = $this->db->prepare('SELECT user_id FROM patients WHERE patient_id = ?');
            $stmtPatient->bind_param('i', $patientId);
            $stmtPatient->execute();
            $resultPatient = $stmtPatient->get_result();
            if ($resultPatient->num_rows > 0) {
                $patientUser = $resultPatient->fetch_assoc();
                $this->createNotification(
                    $patientUser['user_id'], 
                    'appointment_scheduled', 
                    'Demande envoyée', 
                    'Votre demande de rendez-vous en ' . $specialityName . ' a été envoyée aux médecins', 
                    null, 
                    null, 
                    null
                );
            }
            $stmtPatient->close();

            Response::success([
                'request_id' => $requestId,
                'doctors_notified' => count($doctorIds),
                'status' => 'pending'
            ], 'Demande de rendez-vous créée avec succès', HTTP_CREATED);

        } catch (Exception $e) {
            error_log('Create Appointment Request Error: ' . $e->getMessage());
            error_log('Stack trace: ' . $e->getTraceAsString());
            Response::error('Erreur lors de la création: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Approuver une demande de rendez-vous (par un médecin)
     */
    public function approveAppointmentRequest($appointmentId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            // Récupérer le doctor_id du médecin connecté
            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::badRequest('Profil médecin non trouvé');
            }
            $doctorId = $result->fetch_assoc()['doctor_id'];
            $stmt->close();

            // Récupérer l'appointment et vérifier qu'il belongs au médecin
            $stmt = $this->db->prepare(
                'SELECT a.*, ar.request_id FROM appointments a 
                 LEFT JOIN appointment_requests ar ON a.appointment_request_id = ar.request_id
                 WHERE a.appointment_id = ? AND a.doctor_id = ?'
            );
            $stmt->bind_param('ii', $appointmentId, $doctorId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Vous n\'avez pas accès à ce rendez-vous');
            }

            $appointment = $result->fetch_assoc();
            $requestId = $appointment['request_id'];
            $patientId = $appointment['patient_id'];
            $stmt->close();

            // Vérifier que la demande est toujours pending
            $stmt = $this->db->prepare('SELECT status FROM appointment_requests WHERE request_id = ?');
            $stmt->bind_param('i', $requestId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0 || $result->fetch_assoc()['status'] !== 'pending') {
                Response::badRequest('Cette demande a déjà été acceptée ou annulée');
            }
            $stmt->close();

            // Approuver cet appointment
            $confirmedStatus = 'confirmed';
            $updatedAt = date('Y-m-d H:i:s');
            
            $stmt = $this->db->prepare('UPDATE appointments SET status = ?, updated_at = ? WHERE appointment_id = ?');
            $stmt->bind_param('ssi', $confirmedStatus, $updatedAt, $appointmentId);
            $stmt->execute();
            $stmt->close();

            // Annuler les autres appointments de la même demande
            $stmt = $this->db->prepare(
                'UPDATE appointments SET status = ?, updated_at = ? 
                 WHERE appointment_request_id = ? AND appointment_id != ? AND status = ?'
            );
            $cancelledStatus = 'cancelled';
            $pendingStatus = 'pending';
            $stmt->bind_param('ssiii', $cancelledStatus, $updatedAt, $requestId, $appointmentId, $pendingStatus);
            $stmt->execute();
            $stmt->close();

            // Mettre à jour le statut de la demande
            $acceptedStatus = 'accepted';
            $stmt = $this->db->prepare(
                'UPDATE appointment_requests SET status = ?, accepted_by_doctor_id = ?, accepted_at = ? WHERE request_id = ?'
            );
            $stmt->bind_param('sisi', $acceptedStatus, $doctorId, $updatedAt, $requestId);
            $stmt->execute();
            $stmt->close();

            // Créer une notification pour le patient
            $stmtPatient = $this->db->prepare('SELECT user_id FROM patients WHERE patient_id = ?');
            $stmtPatient->bind_param('i', $patientId);
            $stmtPatient->execute();
            $resultPatient = $stmtPatient->get_result();
            if ($resultPatient->num_rows > 0) {
                $patientUser = $resultPatient->fetch_assoc();
                $stmt2 = $this->db->prepare('SELECT first_name, last_name FROM doctors WHERE doctor_id = ?');
                $stmt2->bind_param('i', $doctorId);
                $stmt2->execute();
                $doctorResult = $stmt2->get_result();
                if ($doctorResult->num_rows > 0) {
                    $doctor = $doctorResult->fetch_assoc();
                    $doctorName = $doctor['first_name'] . ' ' . $doctor['last_name'];
                    $this->createNotification(
                        $patientUser['user_id'], 
                        'appointment_scheduled', 
                        'Rendez-vous confirmé', 
                        'Dr. ' . $doctorName . ' a accepté votre demande de rendez-vous', 
                        null, 
                        null, 
                        $appointmentId
                    );
                }
                $stmt2->close();
            }
            $stmtPatient->close();

            Response::success(null, 'Rendez-vous confirmé avec succès');

        } catch (Exception $e) {
            error_log('Approve Appointment Request Error: ' . $e->getMessage());
            Response::error('Erreur lors de l\'approbation: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Créer une notification
     */
    private function createNotification($userId, $type, $title, $message, $patientId = null, $examId = null, $appointmentId = null) {
        try {
            $createdAt = date('Y-m-d H:i:s');
            // Convertir null en 0 pour les paramètres int
            $patientId = $patientId ?? 0;
            $examId = $examId ?? 0;
            $appointmentId = $appointmentId ?? 0;
            
            error_log('[createNotification] Creating notification - userId: ' . $userId . ', type: ' . $type . ', appointmentId: ' . $appointmentId);
            
            $stmt = $this->db->prepare(
                'INSERT INTO notifications (user_id, notification_type, title, message, related_patient_id, related_exam_id, related_appointment_id, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('isssiiis', $userId, $type, $title, $message, $patientId, $examId, $appointmentId, $createdAt);
            
            if (!$stmt->execute()) {
                error_log('[createNotification] FAILED to insert notification: ' . $stmt->error);
            } else {
                error_log('[createNotification] SUCCESS - notification created with ID: ' . $this->db->insert_id);
            }
            
            $stmt->close();
        } catch (Exception $e) {
            error_log('Create Notification Error: ' . $e->getMessage());
            error_log('Notification params - userId: ' . $userId . ', type: ' . $type . ', title: ' . $title);
        }
    }
}
?>
