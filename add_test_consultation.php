<?php
define('ENV', 'local');
require_once 'backend/config/database.php';

$db = Database::getInstance()->getConnection();

// D'abord vérifier les specialities
$result = $db->query('SELECT speciality_id, name FROM specialities LIMIT 5');
echo "=== Spécialités disponibles ===\n";
while($row = $result->fetch_assoc()) {
    echo json_encode($row) . "\n";
}

// Utiliser une spécialité qui existe (Allergologie = 58)
$patientId = 6;
$doctorId = 1;
$specialityId = 58; // Allergologie
$reasonForVisit = "Bilan d'allergie";
$diagnosis = "Allergie aux acariens détectée";
$notes = "Patient à revoir pour test de désensibilisation";
$treatment = "Antihistaminiques H1, éviction des acariens";

$stmt = $db->prepare('
    UPDATE consultations 
    SET speciality_id = ?, reason_for_visit = ?, diagnosis = ?, notes = ?, treatment_plan = ?
    WHERE consultation_id = 17
');

$stmt->bind_param('issss', $specialityId, $reasonForVisit, $diagnosis, $notes, $treatment);

if($stmt->execute()) {
    echo "✅ Consultation 17 mise à jour\n";
} else {
    echo "❌ Erreur: " . $stmt->error . "\n";
}

// Vérifier
$result = $db->query('
    SELECT c.consultation_id, c.speciality_id, c.reason_for_visit, c.diagnosis, c.notes, 
           s.name as speciality_name
    FROM consultations c
    LEFT JOIN specialities s ON c.speciality_id = s.speciality_id
    WHERE c.consultation_id = 17
');
$row = $result->fetch_assoc();
echo "\n=== Consultation mise à jour ===\n";
echo json_encode($row, JSON_PRETTY_PRINT) . "\n";

$stmt->close();
?>
