<?php
/**
 * Point d'entrée principal de l'API
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

header('Content-Type: application/json; charset=utf-8');

// Configuration d'erreur
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/../logs/error.log');

// Créer le dossier logs si nécessaire
if (!is_dir(__DIR__ . '/../logs')) {
    mkdir(__DIR__ . '/../logs', 0755, true);
}

// Auto-loader simple
spl_autoload_register(function ($class) {
    $directories = [
        __DIR__ . '/../config/',
        __DIR__ . '/../controllers/',
        __DIR__ . '/../middleware/',
        __DIR__ . '/../utils/',
        __DIR__ . '/../models/',
    ];

    foreach ($directories as $directory) {
        $file = $directory . $class . '.php';
        if (file_exists($file)) {
            require_once $file;
            return true;
        }
    }

    return false;
});

// Charger les dépendances essentielles
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/constants.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/JWT.php';
require_once __DIR__ . '/../routes/Router.php';

// Démarrer le routage
try {
    $router = new Router();
    $router->dispatch();
} catch (Exception $e) {
    error_log('Fatal Error: ' . $e->getMessage());
    Response::error('Erreur interne du serveur: ' . $e->getMessage(), HTTP_SERVER_ERROR);
}
?>
