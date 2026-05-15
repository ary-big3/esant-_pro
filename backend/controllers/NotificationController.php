<?php
/**
 * Contrôleur Notifications
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class NotificationController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Récupérer les notifications de l'utilisateur connecté
     */
    public function getMyNotifications($page = 1, $limit = 20) {
        try {
            $user = AuthMiddleware::verifyAuth();

            error_log('DEBUG: Récupération notifications pour user_id=' . $user['user_id'] . ', page=' . $page . ', limit=' . $limit);

            $offset = ($page - 1) * $limit;

            // Compter le total
            $stmt = $this->db->prepare(
                'SELECT COUNT(*) as total FROM notifications WHERE user_id = ?'
            );
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            $total = $result->fetch_assoc()['total'];
            $stmt->close();

            error_log('DEBUG: Total notifications = ' . $total);

            // Récupérer les notifications
            $stmt = $this->db->prepare(
                'SELECT n.*, 
                        CASE 
                            WHEN n.related_patient_id IS NOT NULL THEN p.first_name
                            ELSE NULL
                        END as related_patient_first_name,
                        CASE 
                            WHEN n.related_patient_id IS NOT NULL THEN p.last_name
                            ELSE NULL
                        END as related_patient_last_name
                 FROM notifications n
                 LEFT JOIN patients p ON n.related_patient_id = p.patient_id
                 WHERE n.user_id = ?
                 ORDER BY n.created_at DESC
                 LIMIT ? OFFSET ?'
            );
            $stmt->bind_param('iii', $user['user_id'], $limit, $offset);
            $stmt->execute();
            $result = $stmt->get_result();

            $notifications = [];
            while ($row = $result->fetch_assoc()) {
                error_log('DEBUG: Notification trouvée: ' . $row['notification_id'] . ' - ' . $row['notification_type']);
                $notifications[] = $row;
            }
            $stmt->close();

            error_log('DEBUG: Retour de ' . count($notifications) . ' notifications');
            Response::paginated($notifications, $total, $page, $limit, 'Notifications récupérées');

        } catch (Exception $e) {
            error_log('Get Notifications Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Marquer une notification comme lue
     */
    public function markAsRead($notificationId) {
        try {
            $user = AuthMiddleware::verifyAuth();

            // Vérifier que la notification appartient à l'utilisateur
            $stmt = $this->db->prepare('SELECT user_id FROM notifications WHERE notification_id = ?');
            $stmt->bind_param('i', $notificationId);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                Response::notFound('Notification non trouvée');
            }
            $notification = $result->fetch_assoc();
            if ($notification['user_id'] !== $user['user_id']) {
                Response::forbidden('Vous n\'avez pas accès à cette notification');
            }
            $stmt->close();

            // Marquer comme lue
            $readAt = date('Y-m-d H:i:s');
            $stmt = $this->db->prepare('UPDATE notifications SET is_read = 1, read_at = ? WHERE notification_id = ?');
            $stmt->bind_param('si', $readAt, $notificationId);

            if (!$stmt->execute()) {
                throw new Exception('Erreur lors de la mise à jour');
            }
            $stmt->close();

            Response::success(null, 'Notification marquée comme lue');

        } catch (Exception $e) {
            error_log('Mark Notification Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Récupérer le nombre de notifications non lues
     */
    public function getUnreadCount() {
        try {
            $user = AuthMiddleware::verifyAuth();

            $stmt = $this->db->prepare(
                'SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = ? AND is_read = 0'
            );
            $stmt->bind_param('i', $user['user_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            $data = $result->fetch_assoc();
            $stmt->close();

            Response::success($data, 'Nombre de notifications non lues');

        } catch (Exception $e) {
            error_log('Get Unread Count Error: ' . $e->getMessage());
            Response::error($e->getMessage(), HTTP_SERVER_ERROR);
        }
    }
}
?>
