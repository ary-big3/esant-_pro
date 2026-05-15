<?php
/**
 * Contrôleur Documents Médicaux
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../config/constants.php';

class DocumentController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Télécharger un document médical
     */
    public function upload() {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $patientId = $_POST['patient_id'] ?? null;
            $documentType = $_POST['document_type'] ?? 'Bilan';
            $description = $_POST['description'] ?? '';

            if (!$patientId || !isset($_FILES['file'])) {
                Response::badRequest('Données manquantes');
            }

            $file = $_FILES['file'];
            if ($file['error'] !== UPLOAD_ERR_OK) {
                Response::badRequest('Erreur lors du téléchargement du fichier');
            }

            // Créer le dossier d'upload s'il n'existe pas
            $uploadsDir = __DIR__ . '/../public/uploads/documents';
            if (!is_dir($uploadsDir)) {
                mkdir($uploadsDir, 0755, true);
            }

            // Générer un nom unique pour le fichier
            $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
            $fileName = uniqid() . '_' . str_replace(' ', '_', $file['name']);
            $filePath = $uploadsDir . '/' . $fileName;

            if (!move_uploaded_file($file['tmp_name'], $filePath)) {
                Response::error('Erreur de sauvegarde du fichier', HTTP_SERVER_ERROR);
            }

            // Récupérer le doctor_id
            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $doctorId = $stmt->get_result()->fetch_assoc()['doctor_id'];
            $stmt->close();

            // Insérer dans la base de données
            $stmt = $this->db->prepare(
                'INSERT INTO medical_documents (patient_id, doctor_id, document_type, file_name, file_path, description, uploaded_at)
                 VALUES (?, ?, ?, ?, ?, ?, NOW())'
            );
            $stmt->bind_param('iisss', $patientId, $doctorId, $documentType, $fileName, $filePath, $description);

            if (!$stmt->execute()) {
                unlink($filePath);
                Response::error($stmt->error, HTTP_SERVER_ERROR);
            }

            $documentId = $stmt->insert_id;
            $stmt->close();

            // Récupérer les infos du médecin
            $stmt = $this->db->prepare(
                'SELECT u.full_name FROM doctors d
                 JOIN users u ON d.user_id = u.user_id
                 WHERE d.doctor_id = ?'
            );
            $stmt->bind_param('i', $doctorId);
            $stmt->execute();
            $doctorName = $stmt->get_result()->fetch_assoc()['full_name'];
            $stmt->close();

            Response::success([
                'document_id' => $documentId,
                'patient_id' => $patientId,
                'doctor_id' => $doctorId,
                'doctor_name' => $doctorName,
                'document_type' => $documentType,
                'file_name' => $fileName,
                'file_path' => '/esante/backend/public/uploads/documents/' . $fileName,
                'description' => $description,
                'uploaded_at' => date('Y-m-d H:i:s'),
            ], 'Document téléchargé');

        } catch (Exception $e) {
            error_log('Upload Document Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Obtenir les documents d'un patient
     */
    public function getPatientDocuments($patientId, $page = 1, $limit = 10) {
        try {
            $user = AuthMiddleware::verifyAuth();

            $offset = ($page - 1) * $limit;

            $stmt = $this->db->prepare(
                'SELECT d.*, u.full_name as doctor_name
                 FROM medical_documents d
                 JOIN doctors dr ON d.doctor_id = dr.doctor_id
                 JOIN users u ON dr.user_id = u.user_id
                 WHERE d.patient_id = ?
                 ORDER BY d.uploaded_at DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $patientId, $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $documents = [];
            while ($row = $result->fetch_assoc()) {
                $documents[] = $row;
            }
            $stmt->close();

            // Compter le total
            $stmt = $this->db->prepare('SELECT COUNT(*) as total FROM medical_documents WHERE patient_id = ?');
            $stmt->bind_param('i', $patientId);
            $stmt->execute();
            $total = $stmt->get_result()->fetch_assoc()['total'];
            $stmt->close();

            Response::success([
                'documents' => $documents,
                'total' => $total,
                'page' => $page,
                'limit' => $limit,
            ], 'Documents récupérés');

        } catch (Exception $e) {
            error_log('Get Documents Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Supprimer un document
     */
    public function delete($documentId) {
        try {
            $user = AuthMiddleware::verifyAuth();
            AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

            $stmt = $this->db->prepare('SELECT file_path, doctor_id FROM medical_documents WHERE document_id = ?');
            $stmt->bind_param('i', $documentId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Document non trouvé');
            }

            $document = $result->fetch_assoc();
            $stmt->close();

            // Récupérer le doctor_id du médecin connecté
            $stmt = $this->db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $userDoctorId = $stmt->get_result()->fetch_assoc()['doctor_id'];
            $stmt->close();

            // Vérifier la propriété
            if ($document['doctor_id'] != $userDoctorId) {
                Response::forbidden('Vous ne pouvez supprimer que vos propres documents');
            }

            // Supprimer le fichier
            if (file_exists($document['file_path'])) {
                unlink($document['file_path']);
            }

            // Supprimer de la base de données
            $stmt = $this->db->prepare('DELETE FROM medical_documents WHERE document_id = ?');
            $stmt->bind_param('i', $documentId);
            $stmt->execute();
            $stmt->close();

            Response::success(null, 'Document supprimé');

        } catch (Exception $e) {
            error_log('Delete Document Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }
}
