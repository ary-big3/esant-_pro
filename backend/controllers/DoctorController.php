<?php
/**
 * Contrôleur Médecin
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class DoctorController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Obtenir le profil du médecin courant
     */
    public function getProfile() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $stmt = $this->db->prepare(
                'SELECT d.*, u.email, u.full_name, u.phone, u.last_login, h.name as hospital_name
                 FROM doctors d
                 JOIN users u ON d.user_id = u.user_id
                 LEFT JOIN hospitals h ON d.hospital_id = h.hospital_id
                 WHERE d.user_id = ?'
            );
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Profil médecin non trouvé');
            }

            $doctor = $result->fetch_assoc();
            $stmt->close();

            Response::success($doctor, 'Profil médecin récupéré');

        } catch (Exception $e) {
            error_log('Get Doctor Profile Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Rechercher des patients (seulement les patients traités par ce médecin)
     */
    public function searchPatients() {
        try {
            error_log('🔵 [searchPatients] DÉBUT');
            
            $user = AuthMiddleware::verifyAuth();
            error_log('🔵 [searchPatients] User: ' . $user['user_id'] . ' (' . $user['role'] . ')');
            
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            // Récupérer le doctor_id du médecin
            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                error_log('❌ [searchPatients] Médecin non trouvé');
                Response::forbidden('Médecin non trouvé');
            }
            $doctorId = $result->fetch_assoc()['doctor_id'];
            $stmt->close();
            error_log('🟢 [searchPatients] Doctor ID: ' . $doctorId);
            
            $input = json_decode(file_get_contents('php://input'), true);
            $searchTerm = $input['search_query'] ?? $input['search'] ?? '';
            error_log('🔵 [searchPatients] Search term: "' . $searchTerm . '"');

            // Permettre les recherches vides pour retourner tous les patients du médecin
            if (!empty($searchTerm) && strlen($searchTerm) < 2) {
                error_log('⚠️ [searchPatients] Terme trop court');
                Response::badRequest('Terme de recherche trop court (minimum 2 caractères)');
            }

            // Extraire l'ID numérique si le format "PAT-XXXX" est utilisé
            $patientIdToSearch = null;
            if (preg_match('/^PAT-(\d+)$/i', $searchTerm, $matches)) {
                $patientIdToSearch = (int)$matches[1];
                error_log('🟢 [searchPatients] Recherche par ID: ' . $patientIdToSearch);
            } elseif (is_numeric($searchTerm)) {
                $patientIdToSearch = (int)$searchTerm;
                error_log('🟢 [searchPatients] Recherche par ID numérique: ' . $patientIdToSearch);
            }

            $patients = [];
            
            // Si c'est une recherche par ID, faire une requête directe
            if ($patientIdToSearch !== null) {
                error_log('🔵 [searchPatients] Exécution SQL par ID');
                $stmt = $this->db->prepare(
                    'SELECT DISTINCT p.patient_id, p.first_name, p.last_name, p.date_of_birth, p.gender, p.blood_group, u.email
                     FROM patients p
                     JOIN users u ON p.user_id = u.user_id
                     WHERE p.patient_id = ?
                     LIMIT 20'
                );
                if (!$stmt) {
                    error_log('❌ [searchPatients] Erreur prepare: ' . $this->db->error);
                    Response::error('Erreur SQL: ' . $this->db->error, 500);
                    return;
                }
                $stmt->bind_param('i', $patientIdToSearch);
            } else {
                // Sinon, chercher par nom/prénom dans TOUS les patients
                error_log('🔵 [searchPatients] Exécution SQL par nom/prénom');
                $searchPattern = '%' . $searchTerm . '%';
                $stmt = $this->db->prepare(
                    'SELECT DISTINCT p.patient_id, p.first_name, p.last_name, p.date_of_birth, p.gender, p.blood_group, u.email
                     FROM patients p
                     JOIN users u ON p.user_id = u.user_id
                     WHERE (p.first_name LIKE ? OR p.last_name LIKE ? OR CONCAT(p.first_name, \' \', p.last_name) LIKE ?)
                     LIMIT 20'
                );
                if (!$stmt) {
                    error_log('❌ [searchPatients] Erreur prepare: ' . $this->db->error);
                    Response::error('Erreur SQL: ' . $this->db->error, 500);
                    return;
                }
                $stmt->bind_param('sss', $searchPattern, $searchPattern, $searchPattern);
            }
            
            error_log('🔵 [searchPatients] Avant execute');
            $stmt->execute();
            error_log('🔵 [searchPatients] Après execute');
            
            $result = $stmt->get_result();

            error_log('🔵 [searchPatients] Nombre de résultats: ' . $result->num_rows);

            while ($row = $result->fetch_assoc()) {
                // Ajouter l'ID du patient formaté
                $row['patient_display_id'] = 'PAT-' . str_pad($row['patient_id'], 4, '0', STR_PAD_LEFT);
                error_log('🟢 [searchPatients] Patient trouvé: ' . $row['first_name'] . ' ' . $row['last_name'] . ' - Genre: ' . ($row['gender'] ?? 'NULL') . ' - Groupe: ' . ($row['blood_group'] ?? 'NULL'));
                $patients[] = $row;
            }
            $stmt->close();

            error_log('✅ [searchPatients] Retour de ' . count($patients) . ' patients');
            Response::success($patients, 'Patients trouvés');

        } catch (Exception $e) {
            error_log('❌ [searchPatients] Exception: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Rechercher n'importe quel patient dans la base de données (par ID)
     */
    public function searchAnyPatient() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);
            
            $input = json_decode(file_get_contents('php://input'), true);
            $searchTerm = $input['search_query'] ?? $input['search'] ?? '';

            // Permettre les recherches vides
            if (!empty($searchTerm) && strlen($searchTerm) < 1) {
                Response::badRequest('Terme de recherche vide');
            }

            // Extraire l'ID numérique si le format "PAT-XXXX" est utilisé
            $patientIdToSearch = null;
            if (preg_match('/^PAT-(\d+)$/i', $searchTerm, $matches)) {
                $patientIdToSearch = (int)$matches[1];
            } elseif (is_numeric($searchTerm)) {
                $patientIdToSearch = (int)$searchTerm;
            }

            $patients = [];
            
            // Si c'est une recherche par ID, faire une requête directe
            if ($patientIdToSearch !== null) {
                $stmt = $this->db->prepare(
                    'SELECT p.patient_id, p.first_name, p.last_name, p.date_of_birth, p.gender, p.blood_group, u.email
                     FROM patients p
                     JOIN users u ON p.user_id = u.user_id
                     WHERE p.patient_id = ?
                     LIMIT 20'
                );
                $stmt->bind_param('i', $patientIdToSearch);
            } else {
                // Sinon, chercher par nom/prénom
                $searchPattern = '%' . $searchTerm . '%';
                $stmt = $this->db->prepare(
                    'SELECT p.patient_id, p.first_name, p.last_name, p.date_of_birth, p.gender, p.blood_group, u.email
                     FROM patients p
                     JOIN users u ON p.user_id = u.user_id
                     WHERE p.first_name LIKE ? OR p.last_name LIKE ? OR CONCAT(p.first_name, \' \', p.last_name) LIKE ?
                     LIMIT 20'
                );
                $stmt->bind_param('sss', $searchPattern, $searchPattern, $searchPattern);
            }
            
            $stmt->execute();
            $result = $stmt->get_result();

            while ($row = $result->fetch_assoc()) {
                // Ajouter l'ID du patient formaté
                $row['patient_display_id'] = 'PAT-' . str_pad($row['patient_id'], 4, '0', STR_PAD_LEFT);
                $patients[] = $row;
            }
            $stmt->close();

            // CORRECTION: Retourner success: false si aucun patient trouvé
            if (count($patients) === 0) {
                Response::success([], 'Aucun patient trouvé');
            } else {
                Response::success($patients, count($patients) . ' patient(s) trouvé(s)');
            }

        } catch (Exception $e) {
            error_log('Search Any Patient Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les statistiques du médecin
     */
    public function getStatistics() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

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

            // Compter les consultations d'aujourd'hui
            $today = date('Y-m-d');
            $stmt = $this->db->prepare(
                'SELECT COUNT(*) as count FROM consultations WHERE doctor_id = ? AND DATE(consultation_date) = ?'
            );
            $stmt->bind_param('is', $doctorId, $today);
            $stmt->execute();
            $result = $stmt->get_result();
            $consultationsToday = $result->fetch_assoc()['count'];
            $stmt->close();

            // Compter les patients supervisés
            $stmt = $this->db->prepare(
                'SELECT DISTINCT patient_id FROM consultations WHERE doctor_id = ?'
            );
            $stmt->bind_param('i', $doctorId);
            $stmt->execute();
            $result = $stmt->get_result();
            $patientsSupervisited = $result->num_rows;
            $stmt->close();

            // Compter les ordonnances en attente
            $stmt = $this->db->prepare(
                'SELECT COUNT(*) as count FROM prescriptions WHERE doctor_id = ? AND status = ?'
            );
            $active = STATUS_ACTIVE;
            $stmt->bind_param('is', $doctorId, $active);
            $stmt->execute();
            $result = $stmt->get_result();
            $prescriptionsPending = $result->fetch_assoc()['count'];
            $stmt->close();

            // Compter les cas urgents
            $stmt = $this->db->prepare(
                'SELECT COUNT(*) as count FROM exams WHERE doctor_id = ? AND urgency_level = ? AND exam_status != ?'
            );
            $urgent = URGENCY_URGENT;
            $completed = EXAM_STATUS_COMPLETED;
            $stmt->bind_param('iss', $doctorId, $urgent, $completed);
            $stmt->execute();
            $result = $stmt->get_result();
            $urgentCases = $result->fetch_assoc()['count'];
            $stmt->close();

            Response::success([
                'consultations_today' => intval($consultationsToday),
                'patients_supervised' => intval($patientsSupervisited),
                'prescriptions_pending' => intval($prescriptionsPending),
                'urgent_cases' => intval($urgentCases)
            ], 'Statistiques récupérées');

        } catch (Exception $e) {
            error_log('Get Statistics Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les spécialités du médecin
     */
    public function getSpecialities() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

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

            // Récupérer les spécialités
            $stmt = $this->db->prepare(
                'SELECT s.*, ds.years_of_experience, ds.is_primary
                 FROM specialities s
                 LEFT JOIN doctor_specialities ds ON s.speciality_id = ds.speciality_id AND ds.doctor_id = ?
                 WHERE ds.doctor_id IS NOT NULL'
            );
            $stmt->bind_param('i', $doctorId);
            $stmt->execute();
            $result = $stmt->get_result();

            $specialities = [];
            while ($row = $result->fetch_assoc()) {
                $specialities[] = $row;
            }
            $stmt->close();

            Response::success($specialities, 'Spécialités du médecin récupérées');

        } catch (Exception $e) {
            error_log('Get Specialities Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir l'agenda du médecin avec pagination
     */
    public function getAgenda($page = 1, $limit = 20) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

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

            // Validation des paramètres
            $page = max(1, intval($page));
            $limit = min(100, max(1, intval($limit)));
            $offset = ($page - 1) * $limit;

            // Compter le total des rendez-vous
            $stmt = $this->db->prepare(
                'SELECT COUNT(*) as total FROM appointments WHERE doctor_id = ?'
            );
            $stmt->bind_param('i', $doctorId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les rendez-vous
            $stmt = $this->db->prepare(
                'SELECT a.appointment_id, a.patient_id, a.appointment_date, 
                        a.appointment_duration_minutes, a.status, a.reason_for_appointment,
                        a.appointment_request_id,
                        p.first_name, p.last_name
                 FROM appointments a
                 JOIN patients p ON a.patient_id = p.patient_id
                 WHERE a.doctor_id = ?
                 ORDER BY a.appointment_date DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $doctorId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $appointments = [];
            while ($row = $result->fetch_assoc()) {
                $row['patient_name'] = $row['first_name'] . ' ' . $row['last_name'];
                $appointments[] = $row;
            }
            $stmt->close();

            Response::paginated(
                $appointments,
                intval($total),
                $page,
                $limit,
                'Agenda récupéré'
            );

        } catch (Exception $e) {
            error_log('Get Agenda Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les notifications du médecin
     */
    public function getNotifications($page = 1, $limit = 20) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            // Valider les paramètres
            $page = max(1, intval($page));
            $limit = min(100, max(1, intval($limit)));
            $offset = ($page - 1) * $limit;

            // RÉCUPÉRER TOUTES les notifications appointment_reminder pour ce médecin - SANS FILTRAGE STRICT
            $stmt = $this->db->prepare(
                'SELECT COUNT(*) as total FROM notifications 
                 WHERE user_id = ? AND notification_type = "appointment_reminder"'
            );
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les notifications avec infos patient
            $stmt = $this->db->prepare(
                'SELECT n.notification_id, n.notification_type, n.title, n.message, 
                        n.related_patient_id, n.related_appointment_id, n.is_read, n.created_at,
                        p.first_name, p.last_name
                 FROM notifications n
                 LEFT JOIN patients p ON n.related_patient_id = p.patient_id
                 WHERE n.user_id = ? AND n.notification_type = "appointment_reminder"
                 ORDER BY n.created_at DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $user['user_id'], $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $notifications = [];
            while ($row = $result->fetch_assoc()) {
                $row['patient_name'] = ($row['first_name'] ?? '') . ' ' . ($row['last_name'] ?? '');
                $notifications[] = $row;
            }
            $stmt->close();

            Response::paginated(
                $notifications,
                intval($total),
                $page,
                $limit,
                'Notifications récupérées'
            );

        } catch (Exception $e) {
            error_log('Get Notifications Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les créneaux disponibles du médecin
     */
    public function getAvailableSlots() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $month = $_GET['month'] ?? date('Y-m');
            $duration = intval($_GET['duration'] ?? 30);

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

            // Récupérer les créneaux indisponibles pour le mois
            $startOfMonth = $month . '-01 00:00:00';
            $endOfMonth = date('Y-m-t 23:59:59', strtotime($month . '-01'));

            $stmt = $this->db->prepare(
                'SELECT start_date, end_date FROM unavailable_slots 
                 WHERE doctor_id = ? AND start_date >= ? AND end_date <= ?'
            );
            $stmt->bind_param('iss', $doctorId, $startOfMonth, $endOfMonth);
            $stmt->execute();
            $result = $stmt->get_result();

            $unavailableSlots = [];
            while ($row = $result->fetch_assoc()) {
                $unavailableSlots[] = $row;
            }
            $stmt->close();

            // Récupérer les rendez-vous existants
            $stmt = $this->db->prepare(
                'SELECT appointment_date, appointment_duration_minutes FROM appointments 
                 WHERE doctor_id = ? AND appointment_date >= ? AND appointment_date <= ?'
            );
            $stmt->bind_param('iss', $doctorId, $startOfMonth, $endOfMonth);
            $stmt->execute();
            $result = $stmt->get_result();

            $bookedSlots = [];
            while ($row = $result->fetch_assoc()) {
                $bookedSlots[] = $row;
            }
            $stmt->close();

            // Générer les créneaux disponibles
            $availableDates = [];
            $currentDate = new DateTime($month . '-01');
            $endDate = new DateTime(date('Y-m-t', strtotime($month . '-01')));

            while ($currentDate <= $endDate) {
                $dateStr = $currentDate->format('Y-m-d');
                $slots = [];

                // Générer les créneaux horaires pour la journée (par ex: 09:00 à 17:00)
                $slotTime = new DateTime($dateStr . ' 09:00');
                $endTime = new DateTime($dateStr . ' 17:00');

                while ($slotTime < $endTime) {
                    $slotTimeStr = $slotTime->format('Y-m-d H:i:s');
                    $slotEndTime = clone $slotTime;
                    $slotEndTime->add(new DateInterval('PT' . $duration . 'M'));

                    // Vérifier si le créneau est disponible
                    $available = true;

                    // Vérifier les créneaux indisponibles
                    foreach ($unavailableSlots as $unavailable) {
                        $unavailStart = new DateTime($unavailable['start_date']);
                        $unavailEnd = new DateTime($unavailable['end_date']);
                        if (($slotTime >= $unavailStart && $slotTime < $unavailEnd) ||
                            ($slotEndTime > $unavailStart && $slotEndTime <= $unavailEnd)) {
                            $available = false;
                            break;
                        }
                    }

                    // Vérifier les rendez-vous existants
                    if ($available) {
                        foreach ($bookedSlots as $booked) {
                            $bookedStart = new DateTime($booked['appointment_date']);
                            $bookedEnd = clone $bookedStart;
                            $bookedEnd->add(new DateInterval('PT' . $booked['appointment_duration_minutes'] . 'M'));

                            if (($slotTime >= $bookedStart && $slotTime < $bookedEnd) ||
                                ($slotEndTime > $bookedStart && $slotEndTime <= $bookedEnd)) {
                                $available = false;
                                break;
                            }
                        }
                    }

                    $slots[] = [
                        'time' => $slotTime->format('H:i'),
                        'available' => $available
                    ];

                    $slotTime->add(new DateInterval('PT' . $duration . 'M'));
                }

                $availableDates[] = [
                    'date' => $dateStr,
                    'slots' => $slots
                ];

                $currentDate->add(new DateInterval('P1D'));
            }

            Response::success(['available_dates' => $availableDates], 'Créneaux disponibles récupérés');

        } catch (Exception $e) {
            error_log('Get Available Slots Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Créer un créneau indisponible
     */
    public function createUnavailableSlot() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            // Valider les données
            if (!isset($input['start_date']) || !isset($input['end_date'])) {
                Response::badRequest('Les dates de début et fin sont obligatoires');
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

            $startDate = $input['start_date'];
            $endDate = $input['end_date'];
            $reason = $input['reason'] ?? null;

            // Insérer le créneau indisponible
            $stmt = $this->db->prepare(
                'INSERT INTO unavailable_slots (doctor_id, start_date, end_date, reason, created_by)
                 VALUES (?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('isssi', $doctorId, $startDate, $endDate, $reason, $user['user_id']);

            if ($stmt->execute()) {
                $stmt->close();
                Response::success(
                    ['unavailable_slot_id' => $this->db->insert_id],
                    'Créneau indisponible créé',
                    HTTP_CREATED
                );
            } else {
                $stmt->close();
                Response::error('Erreur lors de la création du créneau indisponible', HTTP_SERVER_ERROR);
            }

        } catch (Exception $e) {
            error_log('Create Unavailable Slot Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les créneaux indisponibles
     */
    public function getUnavailableSlots() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $month = $_GET['month'] ?? date('Y-m');

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

            $startOfMonth = $month . '-01 00:00:00';
            $endOfMonth = date('Y-m-t 23:59:59', strtotime($month . '-01'));

            $stmt = $this->db->prepare(
                'SELECT unavailable_slot_id, start_date, end_date, reason
                 FROM unavailable_slots
                 WHERE doctor_id = ? AND start_date >= ? AND end_date <= ?
                 ORDER BY start_date ASC'
            );
            $stmt->bind_param('iss', $doctorId, $startOfMonth, $endOfMonth);
            $stmt->execute();
            $result = $stmt->get_result();

            $slots = [];
            while ($row = $result->fetch_assoc()) {
                $slots[] = $row;
            }
            $stmt->close();

            Response::success($slots, 'Créneaux indisponibles récupérés');

        } catch (Exception $e) {
            error_log('Get Unavailable Slots Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Supprimer un créneau indisponible
     */
    public function deleteUnavailableSlot($slotId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

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

            // Vérifier que le créneau appartient au médecin
            $stmt = $this->db->prepare(
                'SELECT unavailable_slot_id FROM unavailable_slots 
                 WHERE unavailable_slot_id = ? AND doctor_id = ?'
            );
            $stmt->bind_param('ii', $slotId, $doctorId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Créneau indisponible non trouvé');
            }
            $stmt->close();

            // Supprimer le créneau
            $stmt = $this->db->prepare('DELETE FROM unavailable_slots WHERE unavailable_slot_id = ?');
            $stmt->bind_param('i', $slotId);

            if ($stmt->execute()) {
                $stmt->close();
                Response::success(null, 'Créneau indisponible supprimé');
            } else {
                $stmt->close();
                Response::error('Erreur lors de la suppression du créneau', HTTP_SERVER_ERROR);
            }

        } catch (Exception $e) {
            error_log('Delete Unavailable Slot Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les rendez-vous d'aujourd'hui
     */
    public function getTodayAppointments() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

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

            $today = date('Y-m-d');
            $stmt = $this->db->prepare(
                'SELECT a.appointment_id, a.patient_id, a.appointment_date, 
                        a.appointment_duration_minutes, a.status, a.reason_for_appointment,
                        p.first_name, p.last_name
                 FROM appointments a
                 JOIN patients p ON a.patient_id = p.patient_id
                 WHERE a.doctor_id = ? AND DATE(a.appointment_date) = ?
                 ORDER BY a.appointment_date ASC'
            );
            $stmt->bind_param('is', $doctorId, $today);
            $stmt->execute();
            $result = $stmt->get_result();

            $appointments = [];
            while ($row = $result->fetch_assoc()) {
                $dt = new DateTime($row['appointment_date']);
                $row['appointment_time'] = $dt->format('H:i');
                $appointments[] = $row;
            }
            $stmt->close();

            Response::success($appointments, "Rendez-vous d'aujourd'hui récupérés");

        } catch (Exception $e) {
            error_log('Get Today Appointments Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les rendez-vous par date
     */
    public function getAppointmentsByDate($date) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

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

            // Valider le format de la date
            if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
                Response::badRequest('Format de date invalide (YYYY-MM-DD)');
            }

            $stmt = $this->db->prepare(
                'SELECT a.appointment_id, a.patient_id, a.appointment_date, 
                        a.appointment_duration_minutes, a.status, a.reason_for_appointment,
                        p.first_name, p.last_name
                 FROM appointments a
                 JOIN patients p ON a.patient_id = p.patient_id
                 WHERE a.doctor_id = ? AND DATE(a.appointment_date) = ?
                 ORDER BY a.appointment_date ASC'
            );
            $stmt->bind_param('is', $doctorId, $date);
            $stmt->execute();
            $result = $stmt->get_result();

            $appointments = [];
            while ($row = $result->fetch_assoc()) {
                $dt = new DateTime($row['appointment_date']);
                $row['start_time'] = $dt->format('H:i');
                $row['end_time'] = $dt->add(new DateInterval('PT' . $row['appointment_duration_minutes'] . 'M'))->format('H:i');
                $appointments[] = $row;
            }
            $stmt->close();

            Response::success($appointments, 'Rendez-vous récupérés');

        } catch (Exception $e) {
            error_log('Get Appointments By Date Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Envoyer une demande d'accès patient
     */
    public function sendAccessRequest() {
        try {
            error_log('🔵 [sendAccessRequest] DÉBUT');
            
            $user = AuthMiddleware::verifyAuth();
            error_log('🔵 [sendAccessRequest] User authentifié: user_id=' . $user['user_id'] . ', role=' . $user['role']);
            
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            // Récupérer le doctor_id
            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                error_log('❌ [sendAccessRequest] Médecin non trouvé pour user_id=' . $user['user_id']);
                Response::forbidden('Médecin non trouvé');
            }
            $doctorId = $result->fetch_assoc()['doctor_id'];
            $stmt->close();
            error_log('🟢 [sendAccessRequest] Doctor trouvé: doctor_id=' . $doctorId);

            // Valider les données
            $data = json_decode(file_get_contents('php://input'), true);
            error_log('🔵 [sendAccessRequest] Données reçues: ' . json_encode($data));
            
            if (!isset($data['patient_id'])) {
                error_log('❌ [sendAccessRequest] patient_id manquant');
                Response::badRequest('patient_id requis');
            }

            $patientId = intval($data['patient_id']);
            $reason = $data['reason'] ?? 'Consultation requise';
            $permissionType = $data['permission_type'] ?? 'view_only';
            
            error_log('🟢 [sendAccessRequest] patientId=' . $patientId . ', reason=' . $reason . ', permissionType=' . $permissionType);

            // Vérifier que le patient existe
            $stmt = $this->db->prepare('SELECT patient_id, user_id FROM patients WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                $stmt->close();
                error_log('❌ [sendAccessRequest] Patient non trouvé: patient_id=' . $patientId);
                Response::notFound('Patient non trouvé');
            }
            $patientData = $result->fetch_assoc();
            $patientUserId = $patientData['user_id'];
            $stmt->close();
            
            error_log('🟢 [sendAccessRequest] Patient trouvé: patientId=' . $patientId . ', patientUserId=' . $patientUserId);

            // Vérifier qu'une demande n'existe pas déjà en attente
            $stmt = $this->db->prepare(
                'SELECT request_id FROM access_requests 
                 WHERE doctor_id = ? AND patient_id = ? AND status = "pending"'
            );
            $stmt->bind_param('ii', $doctorId, $patientId);
            $stmt->execute();
            if ($stmt->get_result()->num_rows > 0) {
                $stmt->close();
                error_log('⚠️ [sendAccessRequest] Demande en attente existante');
                Response::conflict('Une demande d\'accès est déjà en attente pour ce patient');
            }
            $stmt->close();

            // Insérer la demande d'accès dans access_requests
            error_log('🔵 [sendAccessRequest] Insertion dans access_requests: patientId=' . $patientId . ', doctorId=' . $doctorId . ', requesterUserId=' . $user['user_id']);
            
            $stmt = $this->db->prepare(
                'INSERT INTO access_requests (patient_id, doctor_id, requester_user_id, reason_for_access, permission_type, status)
                 VALUES (?, ?, ?, ?, ?, "pending")'
            );
            $stmt->bind_param('iiiss', $patientId, $doctorId, $user['user_id'], $reason, $permissionType);
            if (!$stmt->execute()) {
                error_log('❌ [sendAccessRequest] Erreur insertion: ' . $stmt->error);
                throw new Exception('Erreur lors de l\'insertion de la demande: ' . $stmt->error);
            }
            $requestId = $this->db->insert_id;
            error_log('🟢 [sendAccessRequest] Demande créée avec request_id=' . $requestId);
            $stmt->close();

            // Récupérer le nom du médecin
            $stmt = $this->db->prepare('SELECT full_name FROM users WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $doctorName = $stmt->get_result()->fetch_assoc()['full_name'];
            $stmt->close();

            // Créer une notification pour le patient
            $notificationTitle = "Demande d'accès à votre dossier médical";
            $notificationMessage = "Le Dr. $doctorName demande l'accès à votre dossier médical. Raison: $reason";
            $notificationType = 'access_request';
            $isRead = 0;

            error_log('DEBUG: Créer notification pour patient user_id=' . $patientUserId);
            error_log('DEBUG: SQL params - patientUserId=' . $patientUserId . ', type=' . $notificationType . ', title=' . $notificationTitle . ', message=' . $notificationMessage . ', patientId=' . $patientId . ', isRead=' . $isRead);

            $stmt = $this->db->prepare(
                'INSERT INTO notifications (user_id, notification_type, title, message, related_patient_id, is_read, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, NOW())'
            );
            $stmt->bind_param('isssii', $patientUserId, $notificationType, $notificationTitle, $notificationMessage, $patientId, $isRead);
            if (!$stmt->execute()) {
                error_log('❌ Notification creation failed: ' . $stmt->error);
            } else {
                error_log('✅ Notification créée avec succès pour user_id=' . $patientUserId);
            }
            $stmt->close();

            error_log('🟢 [sendAccessRequest] Notification créée avec succès pour user_id=' . $patientUserId);
            error_log('✅ [sendAccessRequest] FIN - request_id=' . $requestId . ' créée dans access_requests');

            Response::success(['request_id' => $requestId], 'Demande d\'accès envoyée au patient');

        } catch (Exception $e) {
            error_log('❌ [sendAccessRequest] ERREUR: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }
}
?>
