<?php
/**
 * Utilitaires JWT pour l'authentification
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/constants.php';

class JWT {
    /**
     * Encoder un payload en JWT
     */
    public static function encode($payload) {
        try {
            $header = [
                'alg' => JWT_ALGORITHM,
                'typ' => 'JWT'
            ];

            $payload['iat'] = time();
            $payload['exp'] = time() + JWT_EXPIRY;

            $headerEncoded = self::base64urlEncode(json_encode($header));
            $payloadEncoded = self::base64urlEncode(json_encode($payload));
            $signature = self::signSignature($headerEncoded, $payloadEncoded);

            return "{$headerEncoded}.{$payloadEncoded}.{$signature}";
        } catch (Exception $e) {
            throw new Exception('Erreur lors du codage JWT: ' . $e->getMessage());
        }
    }

    /**
     * Décoder et vérifier un JWT
     */
    public static function decode($token) {
        try {
            $parts = explode('.', $token);
            if (count($parts) !== 3) {
                throw new Exception('Format du token invalide');
            }

            list($headerEncoded, $payloadEncoded, $signatureReceived) = $parts;

            // Vérifier la signature
            $signatureComputed = self::signSignature($headerEncoded, $payloadEncoded);
            if (!hash_equals($signatureComputed, $signatureReceived)) {
                throw new Exception('Signature du token invalide');
            }

            // Décoder le payload
            $payload = json_decode(self::base64urlDecode($payloadEncoded), true);
            if (!$payload) {
                throw new Exception('Payload du token invalide');
            }

            // Vérifier l'expiration
            if (isset($payload['exp']) && $payload['exp'] < time()) {
                throw new Exception('Token expiré');
            }

            return $payload;
        } catch (Exception $e) {
            throw new Exception('Erreur lors du décodage JWT: ' . $e->getMessage());
        }
    }

    /**
     * Signer la signature
     */
    private static function signSignature($headerEncoded, $payloadEncoded) {
        $message = "{$headerEncoded}.{$payloadEncoded}";
        $signature = hash_hmac('sha256', $message, JWT_SECRET_KEY, true);
        return self::base64urlEncode($signature);
    }

    /**
     * Encodage base64url
     */
    private static function base64urlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Décodage base64url
     */
    private static function base64urlDecode($data) {
        return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', 4 - strlen($data) % 4));
    }

    /**
     * Extraire le token du header Authorization
     */
    public static function extractTokenFromHeader() {
        error_log('🔍 [JWT.extractTokenFromHeader] Extraction du token du header...');
        
        // Essayer d'abord via getallheaders() (fonctionne sur Apache avec mod_php)
        $headers = getallheaders();
        error_log('   Headers via getallheaders(): ' . json_encode($headers));
        
        if (isset($headers['Authorization'])) {
            error_log('   ✅ Authorization trouvé dans getallheaders()');
            $authHeader = $headers['Authorization'];
            if (preg_match('/Bearer\s+(.+)/i', $authHeader, $matches)) {
                error_log('   ✅ Bearer token extrait: ' . substr($matches[1], 0, 20) . '...');
                return $matches[1];
            }
        } else {
            error_log('   ❌ Authorization NOT trouvé dans getallheaders()');
        }
        
        // Fallback: Vérifier $_SERVER['HTTP_AUTHORIZATION'] (pour nginx et certaines configs Apache)
        error_log('   Fallback 1: Vérification de $_SERVER[HTTP_AUTHORIZATION]');
        if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            error_log('   ✅ $_SERVER[HTTP_AUTHORIZATION] trouvé!');
            $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
            if (preg_match('/Bearer\s+(.+)/i', $authHeader, $matches)) {
                error_log('   ✅ Bearer token extrait: ' . substr($matches[1], 0, 20) . '...');
                return $matches[1];
            }
        } else {
            error_log('   ❌ $_SERVER[HTTP_AUTHORIZATION] NOT trouvé');
        }

        error_log('❌ [JWT.extractTokenFromHeader] Aucun token trouvé!');
        return null;
    }
}
?>
