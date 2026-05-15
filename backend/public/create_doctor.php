<?php
/**
 * Script pour créer un médecin de test
 * Accédez via: http://192.168.8.104/esante/backend/public/create_doctor.php
 */

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../config/database.php';

$response = [
    'success' => false,
    'message' => '',
    'data' => []
];

try {
    $dbInstance = Database::getInstance();
    $db = $dbInstance->getConnection();

    $email = 'drkossi@gmail.com';
    $password = '456123';
    $fullName = 'Dr Kossi Mensah';
    $phone = '77901122';
    $role = 'medecin';

    // Générer le hash du mot de passe
    $passwordHash = password_hash($password, PASSWORD_BCRYPT);

    // 1. Vérifier si l'utilisateur existe déjà
    $checkStmt = $db->prepare('SELECT user_id FROM users WHERE email = ?');
    $checkStmt->bind_param('s', $email);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();

    if ($checkResult->num_rows > 0) {
        $existingUser = $checkResult->fetch_assoc();
        $userId = $existingUser['user_id'];
        error_log("✅ Utilisateur existe déjà: user_id = $userId");
    } else {
        // 2. Insérer dans users
        $insertStmt = $db->prepare(
            'INSERT INTO users (email, password_hash, full_name, phone, role, is_active, created_at) 
             VALUES (?, ?, ?, ?, ?, TRUE, NOW())'
        );

        if (!$insertStmt) {
            throw new Exception('Erreur prepare users: ' . $db->error);
        }

        $insertStmt->bind_param('sssss', $email, $passwordHash, $fullName, $phone, $role);

        if (!$insertStmt->execute()) {
            throw new Exception('Erreur execute users: ' . $insertStmt->error);
        }

        $userId = $db->insert_id;
        error_log("✅ Utilisateur créé: user_id = $userId");
    }

    // 3. Vérifier si le médecin existe déjà
    $checkDoctorStmt = $db->prepare('SELECT doctor_id FROM doctors WHERE user_id = ?');
    $checkDoctorStmt->bind_param('i', $userId);
    $checkDoctorStmt->execute();
    $checkDoctorResult = $checkDoctorStmt->get_result();

    if ($checkDoctorResult->num_rows == 0) {
        // 4. Insérer dans doctors
        $firstName = 'Kossi';
        $lastName = 'Mensah';
        $medicalLicense = 'LIC-KM-001';
        $speciality = 'Médecine générale';

        $doctorStmt = $db->prepare(
            'INSERT INTO doctors (user_id, first_name, last_name, phone, email, medical_license, speciality, is_available) 
             VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)'
        );

        if (!$doctorStmt) {
            throw new Exception('Erreur prepare doctors: ' . $db->error);
        }

        $doctorStmt->bind_param('issssss', $userId, $firstName, $lastName, $phone, $email, $medicalLicense, $speciality);

        if (!$doctorStmt->execute()) {
            throw new Exception('Erreur execute doctors: ' . $doctorStmt->error);
        }

        error_log("✅ Médecin créé avec succès");
    } else {
        error_log("ℹ️ Le médecin existe déjà pour cet utilisateur");
    }

    // 5. Récupérer les données du médecin
    $getStmt = $db->prepare(
        'SELECT u.user_id, u.email, u.full_name, u.phone, u.role, d.doctor_id, d.medical_license 
         FROM users u 
         LEFT JOIN doctors d ON u.user_id = d.user_id 
         WHERE u.email = ?'
    );
    $getStmt->bind_param('s', $email);
    $getStmt->execute();
    $getResult = $getStmt->get_result();
    $medecin = $getResult->fetch_assoc();

    $response['success'] = true;
    $response['message'] = '✅ Médecin créé avec succès!';
    $response['data'] = [
        'user_id' => $medecin['user_id'],
        'email' => $medecin['email'],
        'full_name' => $medecin['full_name'],
        'phone' => $medecin['phone'],
        'role' => $medecin['role'],
        'doctor_id' => $medecin['doctor_id'],
        'password' => $password,
        'instructions' => 'Connectez-vous avec: ' . $email . ' / ' . $password
    ];

} catch (Exception $e) {
    error_log("❌ Erreur: " . $e->getMessage());
    $response['success'] = false;
    $response['message'] = '❌ Erreur: ' . $e->getMessage();
}

echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
?>

