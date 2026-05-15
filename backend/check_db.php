<?php
// Script pour vérifier l'état de la base de données
require_once 'config/database.php';

echo "<h2>Diagnostic - Vérifier l'état de la base de données</h2>";

// 1. Vérifier les médecins et leurs spécialités
echo "<h3>Médecins et spécialités:</h3>";
$stmt = $db->prepare('SELECT doctor_id, user_id, first_name, last_name, speciality FROM doctors LIMIT 10');
$stmt->execute();
$result = $stmt->get_result();
echo "<table border='1'><tr><th>doctor_id</th><th>user_id</th><th>Name</th><th>Speciality</th></tr>";
while ($row = $result->fetch_assoc()) {
    echo "<tr><td>" . $row['doctor_id'] . "</td><td>" . $row['user_id'] . "</td><td>" . $row['first_name'] . " " . $row['last_name'] . "</td><td>" . $row['speciality'] . "</td></tr>";
}
echo "</table>";
$stmt->close();

// 2. Vérifier les demandes de rendez-vous récentes
echo "<h3>Demandes de rendez-vous récentes:</h3>";
$stmt = $db->prepare(
    'SELECT ar.request_id, ar.speciality_id, ar.status, ar.created_at,
            ap.patient_id
     FROM appointment_requests ar
     LEFT JOIN patients ap ON ar.status IS NOT NULL
     ORDER BY ar.created_at DESC
     LIMIT 10'
);
$stmt->execute();
$result = $stmt->get_result();
echo "<table border='1'><tr><th>request_id</th><th>speciality_id</th><th>status</th><th>created_at</th></tr>";
while ($row = $result->fetch_assoc()) {
    echo "<tr><td>" . $row['request_id'] . "</td><td>" . $row['speciality_id'] . "</td><td>" . $row['status'] . "</td><td>" . $row['created_at'] . "</td></tr>";
}
echo "</table>";
$stmt->close();

// 3. Vérifier les appointments créés
echo "<h3>Appointments récents:</h3>";
$stmt = $db->prepare(
    'SELECT a.appointment_id, a.patient_id, a.doctor_id, a.status, a.appointment_request_id, a.created_at
     FROM appointments a
     ORDER BY a.created_at DESC
     LIMIT 10'
);
$stmt->execute();
$result = $stmt->get_result();
echo "<table border='1'><tr><th>appointment_id</th><th>patient_id</th><th>doctor_id</th><th>status</th><th>request_id</th><th>created_at</th></tr>";
while ($row = $result->fetch_assoc()) {
    echo "<tr><td>" . $row['appointment_id'] . "</td><td>" . $row['patient_id'] . "</td><td>" . $row['doctor_id'] . "</td><td>" . $row['status'] . "</td><td>" . $row['appointment_request_id'] . "</td><td>" . $row['created_at'] . "</td></tr>";
}
echo "</table>";
$stmt->close();

// 4. Vérifier les notifications
echo "<h3>Notifications récentes:</h3>";
$stmt = $db->prepare(
    'SELECT n.notification_id, n.user_id, n.notification_type, n.title, n.related_patient_id, n.related_appointment_id, n.created_at
     FROM notifications n
     WHERE n.notification_type = "appointment_reminder"
     ORDER BY n.created_at DESC
     LIMIT 10'
);
$stmt->execute();
$result = $stmt->get_result();
echo "<table border='1'><tr><th>notification_id</th><th>user_id</th><th>type</th><th>title</th><th>patient_id</th><th>appointment_id</th><th>created_at</th></tr>";
while ($row = $result->fetch_assoc()) {
    echo "<tr><td>" . $row['notification_id'] . "</td><td>" . $row['user_id'] . "</td><td>" . $row['notification_type'] . "</td><td>" . $row['title'] . "</td><td>" . ($row['related_patient_id'] ?? 'NULL') . "</td><td>" . ($row['related_appointment_id'] ?? 'NULL') . "</td><td>" . $row['created_at'] . "</td></tr>";
}
echo "</table>";
$stmt->close();

echo "<p style='color: red;'><strong>Si appointment_id est NULL dans les notifications, c'est le problème!</strong></p>";
?>
