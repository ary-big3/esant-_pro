<?php
/**
 * Middleware d'authentification
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../utils/JWT.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../config/constants.php';

class AuthMiddleware {
    /**
     * Vérifier l'authentification JWT
     */
    public static function verifyAuth() {
        try {
            // Log pour déboguer
            error_log('🔐 [AuthMiddleware] Vérification de l\'authentification...');
            
            // Afficher les headers reçus pour déboguer
            $headers = getallheaders();
            error_log('📋 Headers reçus: ' . json_encode($headers));
            error_log('📋 $_SERVER[HTTP_AUTHORIZATION]: ' . ($_SERVER['HTTP_AUTHORIZATION'] ?? 'NON DÉFINI'));
            
            $token = JWT::extractTokenFromHeader();
            error_log('🔑 Token extrait: ' . ($token ? substr($token, 0, 20) . '...' : 'NULL'));
            
            if (!$token) {
                error_log('❌ [AuthMiddleware] Token NULL - Accès refusé');
                Response::unauthorized('Token manquant');
            }

            error_log('✅ [AuthMiddleware] Token trouvé, décodage...');
            $payload = JWT::decode($token);
            error_log('✅ [AuthMiddleware] Token décodé avec succès');
            return $payload;
        } catch (Exception $e) {
            error_log('❌ [AuthMiddleware] Erreur: ' . $e->getMessage());
            Response::unauthorized($e->getMessage());
        }
    }

    /**
     * Vérifier qu'un utilisateur a un rôle spécifique
     */
    public static function verifyRole($requiredRole, $userRole) {
        if ($userRole !== $requiredRole) {
            Response::forbidden('Rôle insuffisant pour cette opération');
        }
    }

    /**
     * Vérifier que l'utilisateur peut accéder aux données d'un patient
     */
    public static function verifyPatientAccess($userId, $patientId, $userRole) {
        // Un administrateur peut toujours accéder
        if ($userRole === ROLE_ADMIN) {
            return true;
        }

        // Un patient peut accéder à ses propres données ou à celles de ses enfants
        if ($userRole === ROLE_PATIENT) {
            // TODO: Vérifier si le patient est propriétaire ou parent
            return true;
        }

        // Un médecin/infirmière peut accéder aux patients qu'il suit
        if (in_array($userRole, [ROLE_MEDECIN, ROLE_INFIRMIERE])) {
            // TODO: Vérifier la relation entre le professionnel et le patient
            return true;
        }

        Response::forbidden('Accès aux données du patient non autorisé');
    }

    /**
     * Ajouter les headers de sécurité
     */
    public static function addSecurityHeaders() {
        // Déterminer l'origine dynamiquement pour le CORS
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
        
        // Accepter localhost, 127.0.0.1, et adresses 192.168.x.x (réseau local)
        $allowedOrigins = [
            'http://localhost',
            'http://localhost:8080',
            'http://localhost:3000',
            'http://127.0.0.1',
            'http://127.0.0.1:8080',
            'http://127.0.0.1:3000',
        ];
        
        // Autoriser le réseau local 192.168.x.x
        if (preg_match('/^http:\/\/192\.168\.\d+\.\d+/', $origin)) {
            $allowedOrigins[] = $origin;
        }
        
        // En développement, accepter toutes les origines (décommenter pour prod)
        // Mais on préfère une liste blanche
        if (in_array($origin, $allowedOrigins) || $_ENV['APP_ENV'] === 'development') {
            header('Access-Control-Allow-Origin: ' . (!empty($origin) ? $origin : '*'));
        } else {
            header('Access-Control-Allow-Origin: ' . FRONTEND_BASE_URL);
        }
        
        header('X-Content-Type-Options: nosniff');
        header('X-Frame-Options: DENY');
        header('X-XSS-Protection: 1; mode=block');
        header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
        header('Content-Security-Policy: default-src \'self\'');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Max-Age: 86400');
    }

    /**
     * Gérer les requêtes OPTIONS (CORS preflight)
     */
    public static function handlePreflightRequest() {
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            http_response_code(200);
            exit;
        }
    }
}
?>
