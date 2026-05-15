<?php
// Test simple pour vérifier que le backend fonctionne

header('Content-Type: application/json');

try {
    // Vérifier que la base de données se connecte
    require_once __DIR__ . '/config/database.php';
    $db = Database::getInstance()->getConnection();
    
    if ($db->connect_error) {
        echo json_encode([
            'success' => false,
            'message' => 'Erreur de connexion BD: ' . $db->connect_error
        ]);
        exit;
    }
    
    // Tester la lecture de la table appointment_requests
    $stmt = $db->prepare('SELECT COUNT(*) as total FROM appointment_requests LIMIT 1');
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result->fetch_assoc();
    
    echo json_encode([
        'success' => true,
        'message' => 'Backend OK',
        'appointment_requests_count' => $row['total']
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Erreur: ' . $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
}
?>
