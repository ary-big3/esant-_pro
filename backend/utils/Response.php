<?php
/**
 * Classe pour gérer les réponses JSON de l'API
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/constants.php';

class Response {
    /**
     * Envoyer une réponse de succès
     */
    public static function success($data = null, $message = MSG_SUCCESS, $statusCode = HTTP_OK) {
        http_response_code($statusCode);
        header('Content-Type: application/json');

        $response = [
            'success' => true,
            'message' => $message,
            'data' => $data,
            'timestamp' => date('Y-m-d H:i:s')
        ];

        echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    }

    /**
     * Envoyer une réponse d'erreur
     */
    public static function error($message = MSG_ERROR, $statusCode = HTTP_SERVER_ERROR, $errors = null) {
        http_response_code($statusCode);
        header('Content-Type: application/json');

        $response = [
            'success' => false,
            'message' => $message,
            'statusCode' => $statusCode,
            'timestamp' => date('Y-m-d H:i:s')
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    }

    /**
     * Envoyer une réponse avec pagination
     */
    public static function paginated($data, $total, $page, $pageSize, $message = MSG_SUCCESS) {
        http_response_code(HTTP_OK);
        header('Content-Type: application/json');

        $response = [
            'success' => true,
            'message' => $message,
            'data' => $data,
            'pagination' => [
                'total' => $total,
                'page' => $page,
                'pageSize' => $pageSize,
                'totalPages' => ceil($total / $pageSize)
            ],
            'timestamp' => date('Y-m-d H:i:s')
        ];

        echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    }

    /**
     * Envoyer une réponse non autorisée
     */
    public static function unauthorized($message = MSG_UNAUTHORIZED) {
        self::error($message, HTTP_UNAUTHORIZED);
    }

    /**
     * Envoyer une réponse interdite
     */
    public static function forbidden($message = MSG_FORBIDDEN) {
        self::error($message, HTTP_FORBIDDEN);
    }

    /**
     * Envoyer une réponse non trouvée
     */
    public static function notFound($message = MSG_NOT_FOUND) {
        self::error($message, HTTP_NOT_FOUND);
    }

    /**
     * Envoyer une réponse de données invalides
     */
    public static function badRequest($message = MSG_INVALID_INPUT, $errors = null) {
        self::error($message, HTTP_BAD_REQUEST, $errors);
    }

    /**
     * Envoyer une réponse de conflit
     */
    public static function conflict($message = MSG_CONFLICT) {
        self::error($message, HTTP_CONFLICT);
    }

    /**
     * Envoyer une réponse créée
     */
    public static function created($data, $message = MSG_SUCCESS) {
        self::success($data, $message, HTTP_CREATED);
    }
}
?>
