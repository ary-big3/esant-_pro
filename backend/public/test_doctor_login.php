<?php
// Script pour tester la connexion médecin

header('Content-Type: application/json');

$email = $_GET['email'] ?? 'drkossi@gmail.com';
$password = $_GET['password'] ?? '456123';

try {
    // Connexion à la base de données
    $db = new mysqli('localhost', 'root', '', 'esante_db');
    
    if ($db->connect_error) {
        throw new Exception("Erreur de connexion: " . $db->connect_error);
    }
    
    $db->set_charset("utf8mb4");
    
    // Rechercher l'utilisateur
    $stmt = $db->prepare("SELECT user_id, email, full_name, role, password_hash FROM users WHERE email = ? AND role = 'medecin'");
    $stmt->bind_param('s', $email);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception("Utilisateur médecin non trouvé avec cet email: $email");
    }
    
    $user = $result->fetch_assoc();
    
    // Vérifier le mot de passe
    $passwordValid = password_verify($password, $user['password_hash']);
    
    $response = [
        'success' => true,
        'message' => 'Test de connexion',
        'data' => [
            'email_searched' => $email,
            'user_found' => true,
            'user_id' => $user['user_id'],
            'email' => $user['email'],
            'full_name' => $user['full_name'],
            'role' => $user['role'],
            'password_hash' => substr($user['password_hash'], 0, 20) . '...',
            'password_valid' => $passwordValid,
            'password_tried' => $password,
            'message_debug' => $passwordValid ? 'Mot de passe CORRECT ✅' : 'Mot de passe INCORRECT ❌',
        ]
    ];
    
    echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
    $stmt->close();
    $db->close();
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur test login',
        'error' => $e->getMessage(),
        'email_searched' => $email ?? 'non fourni',
    ]);
}
?>
