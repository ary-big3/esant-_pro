#!/bin/bash

# Test de vérification que les ordonnances retournent les détails complets
# (dosage, fréquence, durée) et pas juste le nom du médicament

echo "🧪 TEST: Vérifier que les ordonnances affichent tous les détails"
echo "=================================================="

# Configuration
API_BASE="http://localhost/esante/backend/api"
PATIENT_ID="2"  # Changer selon votre BDD
PAGE=1
LIMIT=10

# Récupérer les ordonnances du patient
echo ""
echo "📥 Requête: GET $API_BASE/patients/$PATIENT_ID/prescriptions?page=$PAGE&limit=$LIMIT"
echo ""

curl -s -X GET \
  "$API_BASE/patients/$PATIENT_ID/prescriptions?page=$PAGE&limit=$LIMIT" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  | python3 -m json.tool 2>/dev/null || echo "Erreur: Impossible de parser JSON"

echo ""
echo "=================================================="
echo ""
echo "✅ Vérifications à effectuer:"
echo "   1. Chaque 'medications' contient: medication_name, dosage, dosage_unit, frequency, duration"
echo "   2. dosage et frequency ne sont pas vides"
echo "   3. duration contient une valeur numérique"
echo ""
echo "🔧 Si les champs sont vides:"
echo "   → Vérifier que consultation_screen.dart sauvegarde les ordonnances"
echo "   → Vérifier que PrescriptionController retourne SELECT dosage, frequency, duration"
echo "   → Vérifier que prescription_medications a des données en BD"
echo ""
