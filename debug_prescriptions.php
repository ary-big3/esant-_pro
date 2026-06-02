<?php
/**
 * Script de debugging pour prescriptions/ordonnances
 */

require_once __DIR__ . '/backend/config/database.php';

$db = Database::getInstance()->getConnection();

echo "=== DEBUG PRESCRIPTIONS ===\n\n";

// Vérifier s'il y a des prescriptions
$result = $db->query('SELECT COUNT(*) as total FROM prescriptions');
$row = $result->fetch_assoc();
echo "📊 Total prescriptions en base de données: " . $row['total'] . "\n\n";

if ($row['total'] > 0) {
    // Afficher les 3 dernières prescriptions
    echo "📋 Dernières prescriptions:\n";
    $result = $db->query(
        'SELECT p.prescription_id, p.patient_id, p.doctor_id, p.prescription_date, p.created_at, p.issue_date, p.status,
                d.first_name as doctor_first_name, d.last_name as doctor_last_name
         FROM prescriptions p
         LEFT JOIN doctors d ON p.doctor_id = d.doctor_id
         ORDER BY p.created_at DESC
         LIMIT 3'
    );
    
    while ($row = $result->fetch_assoc()) {
        echo "\n---\n";
        echo "ID: " . $row['prescription_id'] . "\n";
        echo "Patient ID: " . $row['patient_id'] . "\n";
        echo "Médecin: " . ($row['doctor_first_name'] ?? 'N/A') . " " . ($row['doctor_last_name'] ?? 'N/A') . "\n";
        echo "Prescription date: " . ($row['prescription_date'] ?? 'NULL') . "\n";
        echo "Issue date: " . ($row['issue_date'] ?? 'NULL') . "\n";
        echo "Created at: " . ($row['created_at'] ?? 'NULL') . "\n";
        echo "Status: " . ($row['status'] ?? 'NULL') . "\n";
        
        // Afficher les médicaments
        $stmt = $db->prepare('SELECT medication_name, dosage, dosage_unit, frequency, duration FROM prescription_medications WHERE prescription_id = ?');
        $stmt->bind_param('i', $row['prescription_id']);
        $stmt->execute();
        $medResult = $stmt->get_result();
        $medCount = $medResult->num_rows;
        echo "Médicaments: $medCount\n";
        $medIndex = 1;
        while ($med = $medResult->fetch_assoc()) {
            echo "  $medIndex. " . $med['medication_name'] . " " . $med['dosage'] . $med['dosage_unit'] . " - " . $med['frequency'] . " - " . $med['duration'] . " jours\n";
            $medIndex++;
        }
        $stmt->close();
    }
} else {
    echo "❌ Aucune prescription trouvée en base de données\n";
}

echo "\n\n=== FIN DEBUG ===\n";
?>
