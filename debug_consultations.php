<?php
/**
 * Script de debugging pour consultations
 */

require_once __DIR__ . '/backend/config/database.php';

$db = Database::getInstance()->getConnection();

echo "=== DEBUG CONSULTATIONS ===\n\n";

// Vérifier s'il y a des consultations
$result = $db->query('SELECT COUNT(*) as total FROM consultations');
$row = $result->fetch_assoc();
echo "📊 Total consultations en base de données: " . $row['total'] . "\n\n";

if ($row['total'] > 0) {
    // Afficher les 3 dernières consultations
    echo "📋 Dernières consultations:\n";
    $result = $db->query(
        'SELECT c.consultation_id, c.patient_id, c.doctor_id, c.consultation_date, c.notes, c.diagnosis, c.created_at,
                d.first_name as doctor_first_name, d.last_name as doctor_last_name
         FROM consultations c
         LEFT JOIN doctors d ON c.doctor_id = d.doctor_id
         ORDER BY c.consultation_date DESC
         LIMIT 3'
    );
    
    while ($row = $result->fetch_assoc()) {
        echo "\n---\n";
        echo "ID: " . $row['consultation_id'] . "\n";
        echo "Patient ID: " . $row['patient_id'] . "\n";
        echo "Médecin: " . ($row['doctor_first_name'] ?? 'N/A') . " " . ($row['doctor_last_name'] ?? 'N/A') . "\n";
        echo "Date consultation: " . ($row['consultation_date'] ?? 'NULL') . "\n";
        echo "Notes: " . ($row['notes'] ?? 'NULL') . "\n";
        echo "Diagnostic: " . ($row['diagnosis'] ?? 'NULL') . "\n";
        echo "Created at: " . ($row['created_at'] ?? 'NULL') . "\n";
    }
} else {
    echo "❌ Aucune consultation trouvée en base de données\n";
}

echo "\n\n=== FIN DEBUG ===\n";
?>
