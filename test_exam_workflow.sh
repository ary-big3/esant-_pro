#!/bin/bash
# Test workflow d'examen: prescription → récupération → résultats → document

API_URL="http://192.168.8.101/esante/backend/public"
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJyb2xlIjoibWVkZWNpbiIsImlhdCI6MTcxNjAxOTE5OH0.8K-3J7R9q0Z5X5W5X5W5"

echo "=== TEST WORKFLOW EXAMEN ==="
echo ""

# 1. Prescrire un examen
echo "1️⃣ PRESCRIPTION D'EXAMEN"
curl -X POST "$API_URL/exams" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "patient_id": "21",
    "exams": ["Créatinine", "ALAT"],
    "specialite": "Biochimie",
    "urgence": "normal",
    "observations": "Test de prescription",
    "laboratory_id": ""
  }' | jq .
echo ""

# 2. Récupérer les examens du patient
echo "2️⃣ RÉCUPÉRATION DES EXAMENS DU PATIENT"
curl -X GET "$API_URL/patient/21/exams" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

echo "✅ Tests complétés"
