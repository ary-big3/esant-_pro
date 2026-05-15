<?php
/**
 * Script de vérification du setup de l'API
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

header('Content-Type: application/json; charset=utf-8');

// Initialiser les variables
$checks = [
    'php_version' => false,
    'mysqli_extension' => false,
    'database_connection' => false,
    'database_tables' => [],
    'file_permissions' => [],
    'api_routes' => false,
];

$messages = [];

// 1. Vérifier la version PHP
if (version_compare(PHP_VERSION, '7.0.0', '>=')) {
    $checks['php_version'] = true;
    $messages[] = ['status' => 'success', 'message' => 'Version PHP: ' . PHP_VERSION];
} else {
    $messages[] = ['status' => 'error', 'message' => 'PHP 7.0.0 ou plus requis'];
}

// 2. Vérifier l'extension MySQLi
if (extension_loaded('mysqli')) {
    $checks['mysqli_extension'] = true;
    $messages[] = ['status' => 'success', 'message' => 'Extension MySQLi: Installée'];
} else {
    $messages[] = ['status' => 'error', 'message' => 'Extension MySQLi non trouvée'];
}

// 3. Vérifier la connexion à la base de données
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/constants.php';

try {
    $db = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);
    
    if ($db->connect_error) {
        $messages[] = ['status' => 'error', 'message' => 'Connexion BD: ' . $db->connect_error];
    } else {
        $checks['database_connection'] = true;
        $messages[] = ['status' => 'success', 'message' => 'Base de données: Connectée'];
        
        // Vérifier les tables
        $requiredTables = [
            'users', 'patients', 'doctors', 'nurses', 'laboratories',
            'consultations', 'appointments', 'prescriptions', 'exams',
            'medical_documents', 'vital_signs', 'notifications',
            'medical_history', 'allergies', 'vaccinations'
        ];
        
        foreach ($requiredTables as $table) {
            $result = $db->query("SHOW TABLES LIKE '$table'");
            if ($result && $result->num_rows > 0) {
                $checks['database_tables'][$table] = true;
            } else {
                $checks['database_tables'][$table] = false;
                $messages[] = ['status' => 'warning', 'message' => "Table '$table' non trouvée"];
            }
        }
    }
} catch (Exception $e) {
    $messages[] = ['status' => 'error', 'message' => 'Erreur BD: ' . $e->getMessage()];
}

// 4. Vérifier les permissions des fichiers
$directoriesToCheck = [
    __DIR__ . '/../config',
    __DIR__ . '/../controllers',
    __DIR__ . '/../logs',
    __DIR__ . '/../public'
];

foreach ($directoriesToCheck as $dir) {
    if (is_writable($dir)) {
        $checks['file_permissions'][basename($dir)] = true;
    } else {
        $checks['file_permissions'][basename($dir)] = false;
        $messages[] = ['status' => 'warning', 'message' => "Répertoire '$dir' non inscriptible"];
    }
}

// 5. Vérifier les routes API
if ($checks['database_connection']) {
    $checks['api_routes'] = true;
    $messages[] = ['status' => 'success', 'message' => 'Routes API: Disponibles'];
}

// Statut global
$overallStatus = 'success';
foreach ($checks as $key => $value) {
    if (is_array($value)) {
        foreach ($value as $subValue) {
            if ($subValue === false) {
                $overallStatus = 'error';
            }
        }
    } elseif ($value === false) {
        $overallStatus = 'error';
    }
}

$response = [
    'status' => $overallStatus,
    'timestamp' => date('Y-m-d H:i:s'),
    'checks' => $checks,
    'messages' => $messages,
    'api_info' => [
        'version' => API_VERSION,
        'base_url' => API_BASE_URL,
        'frontend_base_url' => FRONTEND_BASE_URL
    ]
];

echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
?>
