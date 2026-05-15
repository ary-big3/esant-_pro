<?php
// Script pour vérifier les comptes médecin existants

header('Content-Type: application/json');

try {
    // Connexion à la base de données
    $db = new mysqli('localhost', 'root', '', 'esante_db');
    
    if ($db->connect_error) {
        throw new Exception("Erreur de connexion: " . $db->connect_error);
    }
    
    $db->set_charset("utf8mb4");
    
    // Récupérer tous les comptes médecin
    $query = "SELECT u.user_id, u.email, u.full_name, u.role, u.is_active, u.created_at
              FROM users u 
              WHERE u.role = 'medecin' 
              ORDER BY u.created_at DESC";
    
    $result = $db->query($query);
    
    if (!$result) {
        throw new Exception("Erreur requête: " . $db->error);
    }
    
    $doctors = [];
    while ($row = $result->fetch_assoc()) {
        $doctors[] = [
            'user_id' => $row['user_id'],
            'email' => $row['email'],
            'full_name' => $row['full_name'],
            'role' => $row['role'],
            'is_active' => $row['is_active'] ? 'Oui' : 'Non',
            'created_at' => $row['created_at'],
        ];
    }
    
    // Aussi vérifier les infirmiers, labos, et admins pour comparaison
    $otherQuerу = "SELECT role, COUNT(*) as count FROM users GROUP BY role";
    $otherResult = $db->query($otherQuerу);
    
    $roleCount = [];
    while ($row = $otherResult->fetch_assoc()) {
        $roleCount[] = $row;
    }
    
    $response = [
        'success' => true,
        'message' => 'Comptes médecin trouvés',
        'data' => [
            'total_doctors' => count($doctors),
            'doctors' => $doctors,
            'user_count_by_role' => $roleCount,
        ]
    ];
    
    echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
    $db->close();
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur',
        'error' => $e->getMessage(),
    ]);
}
?>
