<?php
// Script pour corriger les passwords des médecins

header('Content-Type: application/json');

try {
    $db = new mysqli('localhost', 'root', '', 'esante_db');
    
    if ($db->connect_error) {
        throw new Exception("Erreur: " . $db->connect_error);
    }
    
    $db->set_charset("utf8mb4");
    
    // Passwords génériques
    $passwords = [
        'drkossi@gmail.com' => '456123',        // Dr Kossi
        'paulakpan@gmail.com' => 'password123', // Paul Akpan
    ];
    
    $updates = [];
    
    foreach ($passwords as $email => $password) {
        $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
        
        $stmt = $db->prepare("UPDATE users SET password_hash = ? WHERE email = ? AND role = 'medecin'");
        $stmt->bind_param('ss', $hashedPassword, $email);
        $stmt->execute();
        
        $affected = $db->affected_rows;
        
        $updates[] = [
            'email' => $email,
            'password' => $password,
            'new_hash' => substr($hashedPassword, 0, 25) . '...',
            'rows_updated' => $affected,
            'status' => $affected > 0 ? 'Mis à jour ✅' : 'Pas trouvé ❌',
        ];
        
        $stmt->close();
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Passwords réinitialisés',
        'data' => $updates,
        'instructions' => [
            'Testez avec: drkossi@gmail.com / 456123',
            'Ou avec: paulakpan@gmail.com / password123',
        ]
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
    $db->close();
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
    ]);
}
?>
