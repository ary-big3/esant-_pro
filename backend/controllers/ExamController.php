<?php
/**
 * Contrôleur Examens - VERSION CORRIGÉE
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class ExamController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Prescrire un ou plusieurs examens
     */
    public function prescribeExam() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            $validator = new Validator();
            $validator->validateRequired($input['patient_id'] ?? null, 'patient_id');
            $validator->validateRequired($input['exams'] ?? null, 'exams');
            $validator->validateRequired($input['specialite'] ?? null, 'specialite');

            if ($validator->hasErrors()) {
                Response::badRequest('Données invalides', $validator->getErrors());
            }

            /** DOCTOR ID */
            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::forbidden('Médecin non trouvé');
            }

            $doctorId = $result->fetch_assoc()['doctor_id'];
            $stmt->close();

            /** SPECIALITY */
            $specialityId = null;
            $laboratoryId = null;

            $stmt = $this->db->prepare(
                'SELECT speciality_id, laboratory_assignment FROM specialities WHERE name = ?'
            );
            $stmt->bind_param('s', $input['specialite']);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::badRequest('Spécialité non trouvée');
            }

            $row = $result->fetch_assoc();
            $specialityId = $row['speciality_id'];

            // GESTION LABORATOIRE (sécurisée)
            // Priorité: laboratory_id du input > laboratory_assignment de la spécialité > NULL
            
            // 1. Vérifier si laboratory_id est fourni dans l'input
            if (!empty($input['laboratory_id'])) {
                $labId = $input['laboratory_id'];
                // Si c'est une chaîne, chercher par ID ou name
                if (is_string($labId)) {
                    // Essayer d'abord comme ID numérique
                    if (is_numeric($labId)) {
                        $labId = (int)$labId;
                        $labCheck = $this->db->prepare(
                            "SELECT laboratory_id FROM laboratories WHERE laboratory_id = ?"
                        );
                        $labCheck->bind_param("i", $labId);
                    } else {
                        // Essayer comme name
                        $labCheck = $this->db->prepare(
                            "SELECT laboratory_id FROM laboratories WHERE name = ?"
                        );
                        $labCheck->bind_param("s", $labId);
                    }
                    
                    $labCheck->execute();
                    $labRes = $labCheck->get_result();
                    
                    if ($labRes->num_rows > 0) {
                        $laboratoryId = (int)$labRes->fetch_assoc()['laboratory_id'];
                    }
                    $labCheck->close();
                } else {
                    // C'est déjà un int
                    $labId = (int)$labId;
                    $labCheck = $this->db->prepare(
                        "SELECT laboratory_id FROM laboratories WHERE laboratory_id = ?"
                    );
                    $labCheck->bind_param("i", $labId);
                    $labCheck->execute();
                    $labRes = $labCheck->get_result();
                    
                    if ($labRes->num_rows > 0) {
                        $laboratoryId = $labId;
                    }
                    $labCheck->close();
                }
            }
            // 2. Sinon, essayer le laboratory_assignment de la spécialité
            elseif (!empty($row['laboratory_assignment'])) {
                $labId = (int)$row['laboratory_assignment'];
                $labCheck = $this->db->prepare(
                    "SELECT laboratory_id FROM laboratories WHERE laboratory_id = ?"
                );
                $labCheck->bind_param("i", $labId);
                $labCheck->execute();
                $labRes = $labCheck->get_result();

                if ($labRes->num_rows > 0) {
                    $laboratoryId = $labId;
                }
                $labCheck->close();
            }
            // 3. Sinon laboratory_id reste NULL (ce qui est permis)

            $stmt->close();

            /** DATA */
            $patientId = (int)$input['patient_id'];
            $urgencyLevel = $input['urgence'] ?? URGENCY_NORMAL;
            $observations = $input['observations'] ?? null;
            $now = date('Y-m-d H:i:s');

            /** DATE LOGIC */
            $examDate = new DateTime($now);

            if ($urgencyLevel === 'tres_urgent') {
                $examDate->add(new DateInterval('PT2H'));
            } elseif ($urgencyLevel === 'urgent') {
                $examDate->add(new DateInterval('P1D'));
            } else {
                $examDate->add(new DateInterval('P3D'));
            }

            $examDateStr = $examDate->format('Y-m-d H:i:s');

            /** EXAMS ARRAY */
            $exams = $input['exams'];
            if (!is_array($exams)) {
                $exams = [$exams];
            }

            $createdExams = [];

            foreach ($exams as $examType) {

                $examRequestNumber = 'EXM-' . date('YmdHis') . '-' . uniqid();

                $stmt = $this->db->prepare(
                    "INSERT INTO exams (
                        patient_id,
                        doctor_id,
                        speciality_id,
                        laboratory_id,
                        exam_request_number,
                        exam_date,
                        exam_type,
                        urgency_level,
                        observations,
                        exam_status,
                        result_interpretation,
                        created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
                );

                $status = EXAM_STATUS_PENDING;
                $interpretation = RESULT_TO_VERIFY;

                // Préparer laboratoryId - peut être NULL
                $labIdToInsert = !empty($laboratoryId) ? $laboratoryId : null;

                $stmt->bind_param(
                    'iiiissssssss',
                    $patientId,
                    $doctorId,
                    $specialityId,
                    $labIdToInsert,
                    $examRequestNumber,
                    $examDateStr,
                    $examType,
                    $urgencyLevel,
                    $observations,
                    $status,
                    $interpretation,
                    $now
                );

                if (!$stmt->execute()) {
                    throw new Exception("Erreur insertion examen: $examType");
                }

                $examId = $this->db->insert_id;
                $stmt->close();

                /** FETCH EXAM */
                $stmtFetch = $this->db->prepare(
                    "SELECT e.*,
                            d.first_name AS doctor_first_name,
                            d.last_name AS doctor_last_name,
                            l.name AS laboratory_name,
                            s.name AS speciality_name
                     FROM exams e
                     LEFT JOIN doctors d ON e.doctor_id = d.doctor_id
                     LEFT JOIN laboratories l ON e.laboratory_id = l.laboratory_id
                     LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
                     WHERE e.exam_id = ?"
                );

                $stmtFetch->bind_param('i', $examId);
                $stmtFetch->execute();
                $examData = $stmtFetch->get_result()->fetch_assoc();
                $stmtFetch->close();

                $createdExams[] = $examData;

                /** NOTIFICATION PATIENT */
                $stmtP = $this->db->prepare("SELECT user_id FROM patients WHERE patient_id = ?");
                $stmtP->bind_param('i', $patientId);
                $stmtP->execute();
                $pRes = $stmtP->get_result();

                if ($pRes->num_rows > 0) {
                    $userId = $pRes->fetch_assoc()['user_id'];

                    $this->createNotification(
                        $userId,
                        'exam_requested',
                        'Examen prescrit',
                        "Un examen $examType a été prescrit",
                        null,
                        $examId,
                        null
                    );
                }

                $stmtP->close();
            }

            Response::created([
                'exams' => $createdExams,
                'total' => count($createdExams)
            ], 'Examen(s) prescrit(s) avec succès');

        } catch (Exception $e) {
            error_log($e->getMessage());
            Response::error('Erreur prescription: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Enregistrer résultats
     */
    public function recordResults($examId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_LABORATOIRE, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input || !isset($input['results'])) {
                Response::badRequest('Résultats manquants');
            }

            foreach ($input['results'] as $r) {

                $isAbnormal = (
                    isset($r['reference_min'], $r['reference_max'], $r['measured_value']) &&
                    ($r['measured_value'] < $r['reference_min'] || $r['measured_value'] > $r['reference_max'])
                ) ? 1 : 0;

                $stmt = $this->db->prepare(
                    "INSERT INTO exam_results (
                        exam_id,
                        test_name,
                        measured_value,
                        unit,
                        reference_min,
                        reference_max,
                        is_abnormal,
                        interpretation,
                        notes,
                        created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
                );

                $now = date('Y-m-d H:i:s');

                $stmt->bind_param(
                    'isdddiisss',
                    $examId,
                    $r['test_name'],
                    $r['measured_value'],
                    $r['unit'],
                    $r['reference_min'],
                    $r['reference_max'],
                    $isAbnormal,
                    $r['interpretation'],
                    $r['notes'],
                    $now
                );

                $stmt->execute();
                $stmt->close();
            }

            $status = EXAM_STATUS_COMPLETED;
            $interpretation = $input['result_interpretation'] ?? RESULT_NORMAL;
            $now = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare(
                "UPDATE exams
                 SET exam_status = ?, result_interpretation = ?, signature_date = ?
                 WHERE exam_id = ?"
            );

            $stmt->bind_param('sssi', $status, $interpretation, $now, $examId);
            $stmt->execute();
            $stmt->close();

            // Récupérer les informations de l'examen pour créer un document
            $stmtExam = $this->db->prepare(
                "SELECT patient_id, exam_type FROM exams WHERE exam_id = ?"
            );
            $stmtExam->bind_param('i', $examId);
            $stmtExam->execute();
            $examResult = $stmtExam->get_result();
            $examData = $examResult->fetch_assoc();
            $stmtExam->close();

            if ($examData) {
                $patientId = $examData['patient_id'];
                $examType = $examData['exam_type'];
                
                // Récupérer l'ID utilisateur du labo
                $stmtUser = $this->db->prepare(
                    "SELECT u.user_id FROM users u 
                     JOIN laboratories l ON u.user_id = l.user_id 
                     WHERE u.role = 'labo' LIMIT 1"
                );
                $stmtUser->execute();
                $userResult = $stmtUser->get_result();
                $userData = $userResult->fetch_assoc();
                $stmtUser->close();
                $uploadedBy = $userData['user_id'] ?? null;

                // Créer un document pour les résultats
                $documentTitle = "Résultats - $examType";
                $documentPath = "/documents/exam_results_$examId.pdf";
                
                $stmtDoc = $this->db->prepare(
                    "INSERT INTO medical_documents (
                        patient_id,
                        document_type,
                        document_title,
                        document_description,
                        file_path,
                        uploaded_by,
                        related_exam_id,
                        is_available_for_download,
                        created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
                );

                $docType = 'examen';
                $docDescription = "Résultats d'examen: $examType";
                $isAvailable = 1;

                $stmtDoc->bind_param(
                    'issssiisi',
                    $patientId,
                    $docType,
                    $documentTitle,
                    $docDescription,
                    $documentPath,
                    $uploadedBy,
                    $examId,
                    $isAvailable,
                    $now
                );

                $stmtDoc->execute();
                $stmtDoc->close();

                // Créer une notification pour le patient
                $stmtPatient = $this->db->prepare(
                    "SELECT user_id FROM patients WHERE patient_id = ?"
                );
                $stmtPatient->bind_param('i', $patientId);
                $stmtPatient->execute();
                $patientResult = $stmtPatient->get_result();
                $patientData = $patientResult->fetch_assoc();
                $stmtPatient->close();

                if ($patientData) {
                    $userId = $patientData['user_id'];
                    $stmtNotif = $this->db->prepare(
                        "INSERT INTO notifications (
                            user_id, notification_type, title, message,
                            related_exam_id, created_at
                        ) VALUES (?, ?, ?, ?, ?, ?)"
                    );

                    $notifType = 'exam_results_ready';
                    $notifTitle = 'Résultats disponibles';
                    $notifMessage = "Les résultats de votre examen ($examType) sont maintenant disponibles dans votre dossier médical.";

                    $stmtNotif->bind_param(
                        'isssii',
                        $userId,
                        $notifType,
                        $notifTitle,
                        $notifMessage,
                        $examId,
                        $now
                    );

                    $stmtNotif->execute();
                    $stmtNotif->close();
                }
            }

            Response::success(null, 'Résultats enregistrés et document créé');

        } catch (Exception $e) {
            Response::error($e->getMessage(), 500);
        }
    }

    /**
     * Récupérer les examens d'un patient
     */
    public function getPatientExamsById($patientId, $page = 1, $limit = 10) {
        try {
            $user = AuthMiddleware::verifyAuth();
            
            // Vérifier les permissions
            if ($user['role'] === ROLE_PATIENT) {
                // Les patients peuvent voir leurs examens ou ceux de leurs enfants
                $stmt = $this->db->prepare('SELECT patient_id FROM patients WHERE user_id = ?');
                $stmt->bind_param('i', $user['user_id']);
                $stmt->execute();
                $result = $stmt->get_result();
                $ownPatientId = $result->num_rows > 0 ? $result->fetch_assoc()['patient_id'] : null;
                $stmt->close();

                if ($ownPatientId != $patientId) {
                    // Vérifier si c'est un enfant du parent
                    $stmt = $this->db->prepare(
                        'SELECT patient_id FROM patients WHERE patient_id = ? AND parent_id = ?'
                    );
                    $stmt->bind_param('ii', $patientId, $ownPatientId);
                    $stmt->execute();
                    $result = $stmt->get_result();
                    if ($result->num_rows === 0) {
                        Response::forbidden('Accès à ces examens non autorisé');
                    }
                    $stmt->close();
                }
            } else {
                // Les médecins/infirmières/laboratoires peuvent accéder
                AuthMiddleware::verifyPatientAccess($user['user_id'], $patientId, $user['role']);
            }

            $offset = ($page - 1) * $limit;
            $patientId = (int)$patientId;

            // Récupérer le total des examens
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM exams WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les examens avec les informations détaillées
            $stmt = $this->db->prepare(
                "SELECT e.*,
                        d.first_name AS doctor_first_name,
                        d.last_name AS doctor_last_name,
                        l.name AS laboratory_name,
                        s.name AS speciality_name
                 FROM exams e
                 LEFT JOIN doctors d ON e.doctor_id = d.doctor_id
                 LEFT JOIN laboratories l ON e.laboratory_id = l.laboratory_id
                 LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
                 WHERE e.patient_id = ?
                 ORDER BY e.exam_date DESC
                 LIMIT ? OFFSET ?"
            );

            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();
            
            $exams = [];
            while ($row = $result->fetch_assoc()) {
                // Parse result_values JSON si disponible
                if (!empty($row['result_values'])) {
                    $row['result_values'] = json_decode($row['result_values'], true);
                }
                $exams[] = $row;
            }
            
            $stmt->close();

            Response::success([
                'exams' => $exams,
                'total' => $total,
                'page' => $page,
                'limit' => $limit,
                'pages' => ceil($total / $limit)
            ], 'Examens récupérés');

        } catch (Exception $e) {
            error_log('Get Patient Exams Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    private function createNotification($userId, $type, $title, $message, $patientId = null, $examId = null, $appointmentId = null) {
        try {
            $now = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare(
                "INSERT INTO notifications (
                    user_id, notification_type, title, message,
                    related_patient_id, related_exam_id, related_appointment_id, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
            );

            $stmt->bind_param(
                'isssiiis',
                $userId,
                $type,
                $title,
                $message,
                $patientId,
                $examId,
                $appointmentId,
                $now
            );

            $stmt->execute();
            $stmt->close();

        } catch (Exception $e) {
            error_log($e->getMessage());
        }
    }
}
?>