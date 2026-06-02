<?php
/**
 * Script pour mettre à jour les valeurs null dans la table consultations
 */

require_once __DIR__ . '/config/database.php';

$db = Database::getInstance()->getConnection();

echo "Mise à jour des valeurs null dans la table consultations...\n";

// Mettre à jour reason_for_visit
$stmt = $db->prepare("UPDATE consultations SET reason_for_visit = 'Consultation de suivi' WHERE reason_for_visit IS NULL OR reason_for_visit = ''");
$stmt->execute();
$affected = $stmt->affected_rows;
echo "✅ reason_for_visit mis à jour: $affected lignes\n";
$stmt->close();

// Mettre à jour chief_complaint
$stmt = $db->prepare("UPDATE consultations SET chief_complaint = 'Non spécifié' WHERE chief_complaint IS NULL OR chief_complaint = ''");
$stmt->execute();
$affected = $stmt->affected_rows;
echo "✅ chief_complaint mis à jour: $affected lignes\n";
$stmt->close();

// Mettre à jour diagnosis
$stmt = $db->prepare("UPDATE consultations SET diagnosis = 'En cours d\\'évaluation' WHERE diagnosis IS NULL OR diagnosis = ''");
$stmt->execute();
$affected = $stmt->affected_rows;
echo "✅ diagnosis mis à jour: $affected lignes\n";
$stmt->close();

// Mettre à jour treatment_plan
$stmt = $db->prepare("UPDATE consultations SET treatment_plan = 'Traitement à définir' WHERE treatment_plan IS NULL OR treatment_plan = ''");
$stmt->execute();
$affected = $stmt->affected_rows;
echo "✅ treatment_plan mis à jour: $affected lignes\n";
$stmt->close();

// Mettre à jour notes
$stmt = $db->prepare("UPDATE consultations SET notes = 'Aucune note particulière' WHERE notes IS NULL OR notes = ''");
$stmt->execute();
$affected = $stmt->affected_rows;
echo "✅ notes mis à jour: $affected lignes\n";
$stmt->close();

echo "\n✅ Mise à jour terminée!\n";
