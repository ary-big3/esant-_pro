<?php
header('Content-Type: application/json; charset=utf-8');

// Charger la base de données
require_once 'backend/database/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // Récupérer les 5 dernières prescriptions avec leurs médicaments
    $stmt = $db->prepare('
        SELECT p.prescription_id, p.prescription_date, p.created_at, d.first_name, d.last_name
        FROM prescriptions p
        LEFT JOIN doctors d ON p.doctor_id = d.doctor_id
        ORDER BY p.prescription_id DESC
        LIMIT 5
    ');
    $stmt->execute();
    $result = $stmt->get_result();
    
    $prescriptions = [];
    while ($row = $result->fetch_assoc()) {
        // Pour chaque ordonnance, récupérer les médicaments
        $medStmt = $db->prepare('
            SELECT medication_id, medication_name, dosage, dosage_unit, frequency, duration
            FROM prescription_medications
            WHERE prescription_id = ?
        ');
        $medStmt->bind_param('i', $row['prescription_id']);
        $medStmt->execute();
        $medResult = $medStmt->get_result();
        
        $medications = [];
        while ($med = $medResult->fetch_assoc()) {
            $medications[] = $med;
        }
        $medStmt->close();
        
        $row['medications'] = $medications;
        $prescriptions[] = $row;
    }
    $stmt->close();
    
    echo json_encode([
        'success' => true,
        'count' => count($prescriptions),
        'prescriptions' => $prescriptions
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
?>
