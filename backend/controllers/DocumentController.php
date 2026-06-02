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

            $documentTypeMap = [
                'Bilan' => 'rapport_medical',
                'Rapport Médical' => 'rapport_medical',
                'Autre' => 'autre',
                'Prescription' => 'prescription',
                'Examen' => 'examen',
                'Imagerie' => 'imagerie',
                'Analyse' => 'analyse',
            ];
            $documentType = $documentTypeMap[$documentType] ?? 'autre';

            $uploadedBy = $user['user_id'];
            $fileSizeKb = (int) round($file['size'] / 1024);
            $fileFormat = strtolower($ext);
            $documentTitle = $file['name'];
            $isAvailable = 1;

            // Insérer dans la base de données
            $stmt = $this->db->prepare(
                'INSERT INTO medical_documents (
                    patient_id,
                    document_type,
                    document_title,
                    document_description,
                    file_path,
                    file_size_kb,
                    file_format,
                    uploaded_by,
                    is_available_for_download,
                    created_at
                 ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())'
            );
            $stmt->bind_param(
                'issssiisi',
                $patientId,
                $documentType,
                $documentTitle,
                $description,
                $filePath,
                $fileSizeKb,
                $fileFormat,
                $uploadedBy,
                $isAvailable
            );

            if (!$stmt->execute()) {
                unlink($filePath);
                Response::error($stmt->error, HTTP_SERVER_ERROR);
            }

            $documentId = $stmt->insert_id;
            $stmt->close();

            $uploaderName = $user['full_name'] ?? null;

            $publicUrl = '/esante/backend/public/uploads/documents/' . $fileName;
            Response::success([
                'document_id' => $documentId,
                'patient_id' => $patientId,
                'uploaded_by' => $uploadedBy,
                'uploaded_by_name' => $uploaderName,
                'document_type' => $documentType,
                'document_title' => $documentTitle,
                'file_name' => $fileName,
                'file_path' => $filePath,
                'file_url' => $publicUrl,
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
                'SELECT d.*, u.full_name as uploaded_by_name
                 FROM medical_documents d
                 LEFT JOIN users u ON d.uploaded_by = u.user_id
                 WHERE d.patient_id = ?
                 ORDER BY d.created_at DESC
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

            $stmt = $this->db->prepare('SELECT file_path, uploaded_by FROM medical_documents WHERE document_id = ?');
            $stmt->bind_param('i', $documentId);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 0) {
                Response::notFound('Document non trouvé');
            }

            $document = $result->fetch_assoc();
            $stmt->close();

            // Vérifier la propriété du document
            if ($document['uploaded_by'] != $user['user_id']) {
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
