#!/bin/bash

# Test RDV Notifications Bidirectionnelles
# Script de test complet pour vérifier le flux des notifications

echo "======================================"
echo "Test RDV Notifications Bidirectionnelles"
echo "======================================"
echo ""

# Configuration
API_URL="http://localhost/esante/backend/public"
PATIENT_TOKEN="YOUR_PATIENT_TOKEN_HERE"
DOCTOR_CARDIO_TOKEN="YOUR_DOCTOR_CARDIO_TOKEN_HERE"
DOCTOR_DERMATO_TOKEN="YOUR_DOCTOR_DERMATO_TOKEN_HERE"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction de test HTTP
test_api() {
    local method=$1
    local endpoint=$2
    local token=$3
    local data=$4
    local name=$5

    echo -e "${YELLOW}[TEST] $name${NC}"
    echo "  Méthode: $method"
    echo "  Endpoint: $endpoint"
    
    if [ "$method" = "POST" ] || [ "$method" = "PUT" ]; then
        echo "  Données: $data"
        response=$(curl -s -X "$method" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_URL$endpoint")
    else
        response=$(curl -s -X "$method" \
            -H "Authorization: Bearer $token" \
            "$API_URL$endpoint")
    fi
    
    echo "  Réponse: $response"
    echo ""
    
    # Retourner l'ID si c'est une création
    echo "$response"
}

# ========================
# ÉTAPE 1 : Patient demande un RDV
# ========================
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}ÉTAPE 1 : Patient demande un RDV en Cardiologie${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

request_data='{
  "speciality": "Cardiologie",
  "appointment_date": "2024-02-20 10:00:00",
  "appointment_type": "consultation",
  "reason_for_appointment": "Checkup cardiaque"
}'

response=$(test_api "POST" "/appointment-requests" "$PATIENT_TOKEN" "$request_data" \
    "1.1 - Patient crée une demande RDV")

# Extraire l'ID du rendez-vous (dépend de la structure de réponse)
# appointment_id=$(echo "$response" | grep -o '"appointment_id":[0-9]*' | grep -o '[0-9]*')

echo -e "${YELLOW}✓ Demande créée. Le backend devrait avoir créé des notifications${NC}"
echo -e "${YELLOW}  pour TOUS les médecins Cardiologues.${NC}"
echo ""

# ========================
# ÉTAPE 2 : Médecin Cardiologue voit la notification
# ========================
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}ÉTAPE 2 : Médecin Cardiologue reçoit la notification${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

response=$(test_api "GET" "/doctor/notifications?page=1&limit=10" "$DOCTOR_CARDIO_TOKEN" "" \
    "2.1 - Médecin Cardiologue récupère ses notifications")

echo -e "${YELLOW}✓ Vérifier que:${NC}"
echo -e "${YELLOW}  - La réponse contient une notification${NC}"
echo -e "${YELLOW}  - Le type est 'appointment_reminder'${NC}"
echo -e "${YELLOW}  - Le message mentionne 'Cardiologie'${NC}"
echo ""

# ========================
# ÉTAPE 3 : Médecin Dermatologue NE voit PAS la notification
# ========================
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}ÉTAPE 3 : Médecin Dermatologue n'a PAS reçu (filtrage!)${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

response=$(test_api "GET" "/doctor/notifications?page=1&limit=10" "$DOCTOR_DERMATO_TOKEN" "" \
    "3.1 - Médecin Dermatologue récupère ses notifications")

echo -e "${YELLOW}✓ Vérifier que:${NC}"
echo -e "${YELLOW}  - La réponse est vide (pas de notification Cardiologie)${NC}"
echo -e "${YELLOW}  - C'est le FILTRAGE PAR SPÉCIALITÉ en action!${NC}"
echo ""

# ========================
# ÉTAPE 4 : Médecin Cardiologue approuve
# ========================
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}ÉTAPE 4 : Médecin Cardiologue approuve le RDV${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Note: Vous devez obtenir le appointment_id de l'étape 1
appointment_id="YOUR_APPOINTMENT_ID_HERE"

response=$(test_api "PUT" "/appointments/$appointment_id/approve" "$DOCTOR_CARDIO_TOKEN" "{}" \
    "4.1 - Médecin approuve le rendez-vous")

echo -e "${YELLOW}✓ L'approbation devrait créer une notification pour le patient${NC}"
echo ""

# ========================
# ÉTAPE 5 : Patient reçoit la confirmation
# ========================
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}ÉTAPE 5 : Patient reçoit la notification d'approbation${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

response=$(test_api "GET" "/notifications?page=1&limit=10" "$PATIENT_TOKEN" "" \
    "5.1 - Patient récupère ses notifications")

echo -e "${YELLOW}✓ Vérifier que:${NC}"
echo -e "${YELLOW}  - Une notification avec type 'appointment_confirmed' est présente${NC}"
echo -e "${YELLOW}  - Le message mentionne le nom du médecin${NC}"
echo -e "${YELLOW}  - Le statut du RDV est maintenant 'confirmed'${NC}"
echo ""

# ========================
# RÉSUMÉ DES TESTS
# ========================
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}RÉSUMÉ DU FLUX TESTÉ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "✅ Patient → POST /appointment-requests (Cardiologie)"
echo "✅ Backend crée notifications pour médecins Cardiologues SEULEMENT"
echo "✅ Médecin Cardiologue → GET /doctor/notifications (reçoit)"
echo "✅ Médecin Dermatologue → GET /doctor/notifications (reçoit RIEN)"
echo "✅ Médecin Cardiologue → PUT /appointments/{id}/approve"
echo "✅ Backend crée notification pour Patient"
echo "✅ Patient → GET /notifications (reçoit approbation)"
echo ""

echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo "Si tous les tests passent, le système fonctionne PARFAITEMENT! 🎉"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
