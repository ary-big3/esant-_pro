<?php
define('ENV', 'local');
require_once 'backend/config/database.php';

$db = Database::getInstance()->getConnection();
$result = $db->query('SELECT consultation_id, patient_id, consultation_date, speciality_id, reason_for_visit, diagnosis, notes FROM consultations LIMIT 3');

if($result) {
    while($row = $result->fetch_assoc()) {
        echo json_encode($row, JSON_PRETTY_PRINT) . "\n";
    }
} else {
    echo "Error: " . $db->error;
}
?>
