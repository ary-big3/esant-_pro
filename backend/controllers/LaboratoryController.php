<?php
/**
 * Contrôleur Laboratoire
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/Validator.php';
require_once __DIR__ . '/../config/constants.php';

class LaboratoryController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Obtenir le profil du laboratoire
     */
    public function getProfile() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_LABORATOIRE, $user['role']);

            $stmt = $this->db->prepare(
                'SELECT l.*, u.email, u.full_name, u.phone, u.last_login
                 FROM laboratories l
                 JOIN users u ON l.user_id = u.user_id
                 WHERE l.user_id = ?'
            );
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Profil laboratoire non trouvé');
            }

            $laboratory = $result->fetch_assoc();
            $stmt->close();

            Response::success($laboratory, 'Profil laboratoire récupéré');

        } catch (Exception $e) {
            error_log('Get Laboratory Profile Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les examens en attente
     */
    public function getPendingExams($page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_LABORATOIRE, $user['role']);

            $offset = ($page - 1) * $limit;

            // Récupérer le laboratory_id (optionnel)
            $laboratoryId = null;
            $stmt = $this->db->prepare('SELECT laboratory_id FROM laboratories WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                $laboratoryId = $result->fetch_assoc()['laboratory_id'];
            }
            $stmt->close();

            $completed = EXAM_STATUS_COMPLETED;

            // Compter le total
            if ($laboratoryId !== null) {
                $stmt = $this->db->prepare(
                    'SELECT COUNT(*) as total FROM exams WHERE laboratory_id = ? AND exam_status != ?'
                );
                $stmt->bind_param('is', $laboratoryId, $completed);
            } else {
                $stmt = $this->db->prepare(
                    'SELECT COUNT(*) as total FROM exams WHERE exam_status != ?'
                );
                $stmt->bind_param('s', $completed);
            }
            $stmt->execute();
            $total = $stmt->get_result()->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les examens
            if ($laboratoryId !== null) {
                $stmt = $this->db->prepare(
                    'SELECT e.*, p.first_name as patient_first_name, p.last_name as patient_last_name, d.first_name as doctor_first_name, d.last_name as doctor_last_name, s.name as speciality_name
                     FROM exams e
                     JOIN patients p ON e.patient_id = p.patient_id
                     LEFT JOIN doctors d ON e.doctor_id = d.doctor_id
                     LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
                     WHERE e.laboratory_id = ? AND e.exam_status != ?
                     ORDER BY e.urgency_level DESC, e.exam_date ASC
                     LIMIT ? OFFSET ?'
                );
                $stmt->bind_param('isii', $laboratoryId, $completed, $limit, $offset);
            } else {
                $stmt = $this->db->prepare(
                    'SELECT e.*, p.first_name as patient_first_name, p.last_name as patient_last_name, d.first_name as doctor_first_name, d.last_name as doctor_last_name, s.name as speciality_name
                     FROM exams e
                     JOIN patients p ON e.patient_id = p.patient_id
                     LEFT JOIN doctors d ON e.doctor_id = d.doctor_id
                     LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
                     WHERE e.exam_status != ?
                     ORDER BY e.urgency_level DESC, e.exam_date ASC
                     LIMIT ? OFFSET ?'
                );
                $stmt->bind_param('sii', $completed, $limit, $offset);
            }
            $stmt->execute();
            $result = $stmt->get_result();

            $exams = [];
            while ($row = $result->fetch_assoc()) {
                $exams[] = $row;
            }
            $stmt->close();

            Response::paginated($exams, $total, $page, $limit, 'Examens en attente récupérés');

        } catch (Exception $e) {
            error_log('Get Pending Exams Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les examens en cours de traitement
     */
    public function getInProgressExams($page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_LABORATOIRE, $user['role']);

            $offset = ($page - 1) * $limit;

            // Récupérer le laboratory_id (optionnel)
            $laboratoryId = null;
            $stmt = $this->db->prepare('SELECT laboratory_id FROM laboratories WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                $laboratoryId = $result->fetch_assoc()['laboratory_id'];
            }
            $stmt->close();

            $inProgress = EXAM_STATUS_IN_PROGRESS;

            // Compter le total
            if ($laboratoryId !== null) {
                $stmt = $this->db->prepare(
                    'SELECT COUNT(*) as total FROM exams WHERE laboratory_id = ? AND exam_status = ?'
                );
                $stmt->bind_param('is', $laboratoryId, $inProgress);
            } else {
                $stmt = $this->db->prepare(
                    'SELECT COUNT(*) as total FROM exams WHERE exam_status = ?'
                );
                $stmt->bind_param('s', $inProgress);
            }
            $stmt->execute();
            $total = $stmt->get_result()->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les examens
            if ($laboratoryId !== null) {
                $stmt = $this->db->prepare(
                    'SELECT e.*, p.first_name as patient_first_name, p.last_name as patient_last_name, d.first_name as doctor_first_name, d.last_name as doctor_last_name, s.name as speciality_name
                     FROM exams e
                     JOIN patients p ON e.patient_id = p.patient_id
                     LEFT JOIN doctors d ON e.doctor_id = d.doctor_id
                     LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
                     WHERE e.laboratory_id = ? AND e.exam_status = ?
                     ORDER BY e.urgency_level DESC, e.exam_date ASC
                     LIMIT ? OFFSET ?'
                );
                $stmt->bind_param('isii', $laboratoryId, $inProgress, $limit, $offset);
            } else {
                $stmt = $this->db->prepare(
                    'SELECT e.*, p.first_name as patient_first_name, p.last_name as patient_last_name, d.first_name as doctor_first_name, d.last_name as doctor_last_name, s.name as speciality_name
                     FROM exams e
                     JOIN patients p ON e.patient_id = p.patient_id
                     LEFT JOIN doctors d ON e.doctor_id = d.doctor_id
                     LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
                     WHERE e.exam_status = ?
                     ORDER BY e.urgency_level DESC, e.exam_date ASC
                     LIMIT ? OFFSET ?'
                );
                $stmt->bind_param('sii', $inProgress, $limit, $offset);
            }
            $stmt->execute();
            $result = $stmt->get_result();

            $exams = [];
            while ($row = $result->fetch_assoc()) {
                $exams[] = $row;
            }
            $stmt->close();

            Response::paginated($exams, $total, $page, $limit, 'Examens en cours récupérés');

        } catch (Exception $e) {
            error_log('Get In Progress Exams Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Marquer un examen comme en cours de traitement
     */
    public function startExam($examId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_LABORATOIRE, $user['role']);

            $status = EXAM_STATUS_IN_PROGRESS;
            $updatedAt = date('Y-m-d H:i:s');

            $stmt = $this->db->prepare('UPDATE exams SET exam_status = ?, updated_at = ? WHERE exam_id = ?');
            $stmt->bind_param('ssi', $status, $updatedAt, $examId);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }
            $stmt->close();

            Response::success(null, 'Examen marqué comme en cours');

        } catch (Exception $e) {
            error_log('Start Exam Error: ' . $e->getMessage());
            Response::error('Erreur lors de la mise à jour: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Enregistrer les résultats d'un examen
     */
    public function recordExamResults($examId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_LABORATOIRE, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            if (!$input) {
                Response::badRequest('Données JSON invalides');
            }

            // Récupérer le user_id du laboratoire
            $stmt = $this->db->prepare('SELECT user_id FROM laboratories WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Laboratoire non trouvé');
            }
            $stmt->close();

            // Enregistrer les résultats
            if (isset($input['results'])) {
                foreach ($input['results'] as $result) {
                    $testName = $result['test_name'] ?? '';
                    $measuredValue = $result['measured_value'] ?? null;
                    $unit = $result['unit'] ?? null;
                    $referenceMin = $result['reference_min'] ?? null;
                    $referenceMax = $result['reference_max'] ?? null;
                    $isAbnormal = ($measuredValue < $referenceMin || $measuredValue > $referenceMax) ? 1 : 0;
                    $interpretation = $result['interpretation'] ?? null;
                    $notes = $result['notes'] ?? null;
                    $now = date('Y-m-d H:i:s');

                    $stmt = $this->db->prepare(
                        'INSERT INTO exam_results (exam_id, test_name, measured_value, unit, reference_min, reference_max, is_abnormal, interpretation, notes, created_at)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
                    );
                    $stmt->bind_param('isiddiisss', $examId, $testName, $measuredValue, $unit, $referenceMin, $referenceMax, $isAbnormal, $interpretation, $notes, $now);
                    $stmt->execute();
                    $stmt->close();
                }
            }

            // Mettre à jour le statut de l'examen
            $resultInterpretation = $input['result_interpretation'] ?? RESULT_NORMAL;
            $examStatus = EXAM_STATUS_COMPLETED;
            $timestamp = date('Y-m-d H:i:s');
            $signedByTechnician = $user['user_id'];

            $stmt = $this->db->prepare(
                'UPDATE exams SET exam_status = ?, result_interpretation = ?, signature_date = ?, signed_by_technician = ?, notification_patient_sent = ?, notification_doctor_sent = ?, updated_at = ? WHERE exam_id = ?'
            );
            $patientNotified = true;
            $doctorNotified = true;
            $stmt->bind_param('sssissii', $examStatus, $resultInterpretation, $timestamp, $signedByTechnician, $patientNotified, $doctorNotified, $timestamp, $examId);
            $stmt->execute();
            $stmt->close();

            // Créer des notifications
            $stmt = $this->db->prepare('SELECT patient_id, doctor_id FROM exams WHERE exam_id = ?');
            $stmt->bind_param('i', $examId);
            $stmt->execute();
            $result = $stmt->get_result();
            $examData = $result->fetch_assoc();
            $stmt->close();

            $this->createNotification($examData['patient_id'], 'result_ready', 'Résultats disponibles', 'Les résultats de votre examen sont prêts');
            $this->createNotification($examData['doctor_id'], 'result_ready', 'Résultats d\'examen', 'Les résultats d\'un examen sont disponibles');

            Response::success(null, 'Résultats enregistrés et examen complété');

        } catch (Exception $e) {
            error_log('Record Exam Results Error: ' . $e->getMessage());
            Response::error('Erreur lors de l\'enregistrement: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir l'historique des examens complétés
     */
    public function getCompletedExams($page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_LABORATOIRE, $user['role']);

            $offset = ($page - 1) * $limit;

            // Récupérer le laboratory_id (optionnel)
            $laboratoryId = null;
            $stmt = $this->db->prepare('SELECT laboratory_id FROM laboratories WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows > 0) {
                $laboratoryId = $result->fetch_assoc()['laboratory_id'];
            }
            $stmt->close();

            $completed = EXAM_STATUS_COMPLETED;

            // Compter le total
            if ($laboratoryId !== null) {
                $stmt = $this->db->prepare(
                    'SELECT COUNT(*) as total FROM exams WHERE laboratory_id = ? AND exam_status = ?'
                );
                $stmt->bind_param('is', $laboratoryId, $completed);
            } else {
                $stmt = $this->db->prepare(
                    'SELECT COUNT(*) as total FROM exams WHERE exam_status = ?'
                );
                $stmt->bind_param('s', $completed);
            }
            $stmt->execute();
            $total = $stmt->get_result()->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les examens
            if ($laboratoryId !== null) {
                $stmt = $this->db->prepare(
                    'SELECT e.*, p.first_name as patient_first_name, p.last_name as patient_last_name, d.first_name as doctor_first_name, d.last_name as doctor_last_name, s.name as speciality_name
                     FROM exams e
                     JOIN patients p ON e.patient_id = p.patient_id
                     LEFT JOIN doctors d ON e.doctor_id = d.doctor_id
                     LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
                     WHERE e.laboratory_id = ? AND e.exam_status = ?
                     ORDER BY e.signature_date DESC
                     LIMIT ? OFFSET ?'
                );
                $stmt->bind_param('isii', $laboratoryId, $completed, $limit, $offset);
            } else {
                $stmt = $this->db->prepare(
                    'SELECT e.*, p.first_name as patient_first_name, p.last_name as patient_last_name, d.first_name as doctor_first_name, d.last_name as doctor_last_name, s.name as speciality_name
                     FROM exams e
                     JOIN patients p ON e.patient_id = p.patient_id
                     LEFT JOIN doctors d ON e.doctor_id = d.doctor_id
                     LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
                     WHERE e.exam_status = ?
                     ORDER BY e.signature_date DESC
                     LIMIT ? OFFSET ?'
                );
                $stmt->bind_param('sii', $completed, $limit, $offset);
            }
            $stmt->execute();
            $result = $stmt->get_result();

            $exams = [];
            while ($row = $result->fetch_assoc()) {
                $exams[] = $row;
            }
            $stmt->close();

            Response::paginated($exams, $total, $page, $limit, 'Examens complétés récupérés');

        } catch (Exception $e) {
            error_log('Get Completed Exams Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les ordonnances en attente de révision (examens liés)
     */
    public function getPendingPrescriptions($page = 1, $limit = DEFAULT_PAGE_SIZE) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_LABORATOIRE, $user['role']);

            $offset = ($page - 1) * $limit;

            // Récupérer le laboratory_id
            $stmt = $this->db->prepare('SELECT laboratory_id FROM laboratories WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::forbidden('Laboratoire non trouvé');
            }
            $laboratoryId = $result->fetch_assoc()['laboratory_id'];
            $stmt->close();

            // Compter le total
            $stmt = $this->db->prepare(
                'SELECT COUNT(DISTINCT e.exam_id) as total 
                 FROM exams e 
                 WHERE e.laboratory_id = ? AND e.lab_acceptance_status = ? AND e.exam_status = ?'
            );
            $pending = 'pending';
            $examPending = EXAM_STATUS_PENDING;
            $stmt->bind_param('iss', $laboratoryId, $pending, $examPending);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            // Récupérer les examens en attente d'acceptation
            $stmt = $this->db->prepare(
                'SELECT e.*, 
                        p.first_name as patient_first_name, p.last_name as patient_last_name,
                        d.first_name as doctor_first_name, d.last_name as doctor_last_name, d.user_id as doctor_user_id,
                        s.name as speciality_name,
                        pr.prescription_number
                 FROM exams e
                 JOIN patients p ON e.patient_id = p.patient_id
                 LEFT JOIN doctors d ON e.doctor_id = d.doctor_id
                 LEFT JOIN specialities s ON e.speciality_id = s.speciality_id
                 LEFT JOIN prescriptions pr ON e.prescription_id = pr.prescription_id
                 WHERE e.laboratory_id = ? AND e.lab_acceptance_status = ? AND e.exam_status = ?
                 ORDER BY e.urgency_level DESC, e.exam_date ASC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('issii', $laboratoryId, $pending, $examPending, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $exams = [];
            while ($row = $result->fetch_assoc()) {
                $exams[] = $row;
            }
            $stmt->close();

            Response::paginated($exams, $total, $page, $limit, 'Ordonnances en attente récupérées');

        } catch (Exception $e) {
            error_log('Get Pending Prescriptions Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Labo accepte un examen prescrit
     */
    public function acceptExam($examId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_LABORATOIRE, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            // Vérifier que l'examen existe et appartient à ce labo
            $stmt = $this->db->prepare('SELECT e.*, l.user_id FROM exams e JOIN laboratories l ON e.laboratory_id = l.laboratory_id WHERE e.exam_id = ? AND l.user_id = ?');
            $stmt->bind_param('ii', $examId, $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Examen non trouvé');
            }
            $exam = $result->fetch_assoc();
            $stmt->close();

            // Mettre à jour le statut
            $status = 'accepted';
            $now = date('Y-m-d H:i:s');
            $notes = $input['notes'] ?? null;
            $userId = $user['user_id'];

            $stmt = $this->db->prepare(
                'UPDATE exams SET lab_acceptance_status = ?, accepted_at = ?, accepted_by = ?, lab_acceptance_notes = ?, updated_at = ? WHERE exam_id = ?'
            );
            $stmt->bind_param('ssissi', $status, $now, $userId, $notes, $now, $examId);
            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }
            $stmt->close();

            // Notifier le patient et le médecin
            $this->createNotification($exam['patient_id'], 'exam_accepted', 'Examen accepté', 'Votre examen a été accepté par le laboratoire');
            $this->createNotification($exam['doctor_id'], 'exam_accepted', 'Examen accepté', 'L\'examen a été accepté par le laboratoire');

            Response::success(['exam_id' => $examId], 'Examen accepté');

        } catch (Exception $e) {
            error_log('Accept Exam Error: ' . $e->getMessage());
            Response::error('Erreur lors de l\'acceptation: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Labo refuse un examen prescrit
     */
    public function rejectExam($examId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_LABORATOIRE, $user['role']);

            $input = json_decode(file_get_contents('php://input'), true);

            // Vérifier que l'examen existe et appartient à ce labo
            $stmt = $this->db->prepare('SELECT e.*, l.user_id FROM exams e JOIN laboratories l ON e.laboratory_id = l.laboratory_id WHERE e.exam_id = ? AND l.user_id = ?');
            $stmt->bind_param('ii', $examId, $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Examen non trouvé');
            }
            $exam = $result->fetch_assoc();
            $stmt->close();

            $validator = new Validator();
            $validator->validateRequired($input['reason'] ?? null, 'reason');
            if ($validator->hasErrors()) {
                Response::error($validator->getErrors(), HTTP_BAD_REQUEST);
            }

            // Mettre à jour le statut
            $status = 'rejected';
            $now = date('Y-m-d H:i:s');
            $reason = $input['reason'];

            $stmt = $this->db->prepare(
                'UPDATE exams SET lab_acceptance_status = ?, accepted_at = ?, lab_acceptance_notes = ?, updated_at = ? WHERE exam_id = ?'
            );
            $stmt->bind_param('ssssi', $status, $now, $reason, $now, $examId);
            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }
            $stmt->close();

            // Notifier le patient et le médecin
            $this->createNotification($exam['patient_id'], 'exam_rejected', 'Examen refusé', 'Votre examen a été refusé par le laboratoire. Raison: ' . $reason);
            $this->createNotification($exam['doctor_id'], 'exam_rejected', 'Examen refusé', 'L\'examen a été refusé. Raison: ' . $reason);

            Response::success(['exam_id' => $examId], 'Examen refusé');

        } catch (Exception $e) {
            error_log('Reject Exam Error: ' . $e->getMessage());
            Response::error('Erreur lors du rejet: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Uploader un document résultat (PDF/image) et marquer l'examen comme complété
     */
    public function uploadResultDocument() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_LABORATOIRE, $user['role']);

            $examId = $_POST['exam_id'] ?? null;
            $description = $_POST['description'] ?? '';

            if (!$examId || !isset($_FILES['file'])) {
                Response::badRequest('Données manquantes (exam_id et fichier requis)');
            }

            $file = $_FILES['file'];
            if ($file['error'] !== UPLOAD_ERR_OK) {
                Response::badRequest('Erreur lors du téléchargement du fichier');
            }

            // Récupérer l'examen
            $stmt = $this->db->prepare('SELECT * FROM exams WHERE exam_id = ?');
            $stmt->bind_param('i', $examId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Examen non trouvé');
            }
            $exam = $result->fetch_assoc();
            $stmt->close();

            // Créer le dossier d'upload
            $uploadsDir = __DIR__ . '/../public/uploads/lab-results';
            if (!is_dir($uploadsDir)) {
                mkdir($uploadsDir, 0755, true);
            }

            // Générer un nom unique
            $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
            $fileName = 'result_' . $examId . '_' . uniqid() . '.' . $ext;
            $filePath = $uploadsDir . '/' . $fileName;

            if (!move_uploaded_file($file['tmp_name'], $filePath)) {
                Response::error('Erreur de sauvegarde du fichier', HTTP_SERVER_ERROR);
            }

            $fileUrl = '/esante/backend/public/uploads/lab-results/' . $fileName;
            $now = date('Y-m-d H:i:s');

            // Insérer dans medical_documents (dossier patient)
            $patientId = $exam['patient_id'];
            $documentType = 'examen';
            $documentTitle = 'Résultat: ' . ($exam['exam_type'] ?? 'Examen');
            $docDescription = $description ?: '';
            $fileFormat = $ext;
            $fileSizeKb = round($file['size'] / 1024);
            $uploadedBy = $user['user_id'];
            $relatedExamId = $examId;

            $stmt = $this->db->prepare(
                'INSERT INTO medical_documents (patient_id, document_type, document_title, document_description, file_path, file_size_kb, file_format, uploaded_by, related_exam_id, is_available_for_download)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE)'
            );
            $stmt->bind_param('isssssiis', $patientId, $documentType, $documentTitle, $docDescription, $fileUrl, $fileSizeKb, $fileFormat, $uploadedBy, $relatedExamId);
            if (!$stmt->execute()) {
                unlink($filePath);
                Response::error('Erreur insertion document', HTTP_SERVER_ERROR);
            }
            $documentId = $stmt->insert_id;
            $stmt->close();

            // Mettre à jour l'examen: statut complété
            $completed = EXAM_STATUS_COMPLETED;
            $resultInterpretation = RESULT_NORMAL;
            $signedBy = $user['user_id'];

            $stmt = $this->db->prepare(
                'UPDATE exams SET exam_status = ?, result_interpretation = ?, result_values = ?, signature_date = ?, signed_by_technician = ?, notification_patient_sent = TRUE, notification_doctor_sent = TRUE, updated_at = ? WHERE exam_id = ?'
            );
            $stmt->bind_param('ssssiii', $completed, $resultInterpretation, $fileUrl, $now, $signedBy, $now, $examId);
            $stmt->execute();
            $stmt->close();

            // Notifier le patient et le médecin
            $examDoctorId = $exam['doctor_id'];
            $this->createNotification($patientId, 'result_ready', 'Résultats disponibles', 'Les résultats de votre examen sont prêts');
            $this->createNotification($examDoctorId, 'result_ready', 'Résultats d\'examen', 'Les résultats d\'un examen sont disponibles');

            Response::success([
                'document_id' => $documentId,
                'exam_id' => $examId,
                'file_url' => $fileUrl,
                'file_name' => $fileName,
                'document_type' => $documentType,
            ], 'Résultat enregistré et document ajouté au dossier patient');

        } catch (Exception $e) {
            error_log('Upload Lab Result Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
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
