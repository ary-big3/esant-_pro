<?php
// Diagnostic pour déboguer les notifications
require_once 'config/database.php';

header('Content-Type: application/json');

$user_id = $_GET['user_id'] ?? 1; // Médecin user_id par défaut

$diagnostic = [
    'user_id' => $user_id,
    'doctors' => [],
    'notifications' => [],
    'appointments' => [],
    'appointment_requests' => []
];

// Récupérer les infos du médecin
$stmt = $db->prepare('SELECT doctor_id, user_id, speciality FROM doctors WHERE user_id = ?');
$stmt->bind_param('i', $user_id);
$stmt->execute();
$doctorResult = $stmt->get_result();
if ($doctorResult->num_rows > 0) {
    $diagnostic['doctor'] = $doctorResult->fetch_assoc();
}
$stmt->close();

// Récupérer TOUTES les notifications pour ce médecin
$stmt = $db->prepare(
    'SELECT n.notification_id, n.notification_type, n.title, n.related_appointment_id, 
            n.related_patient_id, n.created_at,
            a.appointment_id, a.status as appointment_status,
            ar.request_id, ar.status as request_status
     FROM notifications n
     LEFT JOIN appointments a ON n.related_appointment_id = a.appointment_id
     LEFT JOIN appointment_requests ar ON a.appointment_request_id = ar.request_id
     WHERE n.user_id = ?
     ORDER BY n.created_at DESC
     LIMIT 20'
);
$stmt->bind_param('i', $user_id);
$stmt->execute();
$result = $stmt->get_result();
while ($row = $result->fetch_assoc()) {
    $diagnostic['notifications'][] = $row;
}
$stmt->close();

// Récupérer les appointments du médecin
$stmt = $db->prepare(
    'SELECT a.appointment_id, a.status, a.appointment_request_id, a.appointment_date
     FROM appointments a
     WHERE a.doctor_id = (SELECT doctor_id FROM doctors WHERE user_id = ?)
     ORDER BY a.created_at DESC
     LIMIT 10'
);
$stmt->bind_param('i', $user_id);
$stmt->execute();
$result = $stmt->get_result();
while ($row = $result->fetch_assoc()) {
    $diagnostic['appointments'][] = $row;
}
$stmt->close();

// Récupérer les appointment_requests
$stmt = $db->prepare(
    'SELECT ar.request_id, ar.status, ar.speciality_id, ar.created_at
     FROM appointment_requests ar
     ORDER BY ar.created_at DESC
     LIMIT 10'
);
$stmt->execute();
$result = $stmt->get_result();
while ($row = $result->fetch_assoc()) {
    $diagnostic['appointment_requests'][] = $row;
}
$stmt->close();

echo json_encode($diagnostic, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
?>
