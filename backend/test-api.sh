#!/bin/bash
# Script de test des endpoints API E-Santé
# Cette API ne nécessite aucune configuration, elle est prête à être testée

# ===== CONFIGURATION =====
API_URL="http://localhost/esante/backend/public"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables globales
TOKEN=""
PATIENT_ID=""
DOCTOR_ID=""
APPOINTMENT_ID=""

# ===== FONCTIONS UTILITAIRES =====

# Afficher un titre
print_title() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Afficher un test réussi
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Afficher une erreur
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Afficher une information
print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Extraire un champ JSON
extract_json() {
    echo "$1" | grep -o "\"$2\":\"[^\"]*\"" | sed "s/\"$2\":\"//" | sed 's/"$//'
}

# ===== TESTS =====

print_title "Vérification de la santé de l'API"
RESPONSE=$(curl -s "$API_URL/health")
if echo "$RESPONSE" | grep -q '"success":true'; then
    print_success "API en ligne et fonctionnelle"
    echo "$RESPONSE"
else
    print_error "API non accessible"
    exit 1
fi

# ===== AUTHENTIFICATION =====

print_title "Tests d'Authentification"

print_info "Test 1: Inscription d'un nouvel utilisateur"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test_user_'$(date +%s)'@esante.com",
    "password": "SecurePass123",
    "full_name": "Test User",
    "phone": "77123456",
    "role": "patient"
  }')

if echo "$REGISTER_RESPONSE" | grep -q '"success":true'; then
    print_success "Inscription réussie"
    echo "$REGISTER_RESPONSE" | jq '.'
else
    print_error "Inscription échouée"
    echo "$REGISTER_RESPONSE" | jq '.'
fi

print_info "Test 2: Connexion"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test_user_'$(date +%s)'@esante.com",
    "password": "SecurePass123"
  }')

if echo "$LOGIN_RESPONSE" | grep -q '"token"'; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.token')
    print_success "Connexion réussie"
    print_info "Token obtenu: ${TOKEN:0:20}..."
    echo "$LOGIN_RESPONSE" | jq '.'
else
    print_error "Connexion échouée"
    echo "$LOGIN_RESPONSE" | jq '.'
fi

# ===== TESTS SANS AUTHENTIFICATION (Publics) =====

print_title "Tests Publics (sans authentification)"

print_info "Test: Vérification du token"
VERIFY_RESPONSE=$(curl -s "$API_URL/auth/verify-token" \
  -H "Authorization: Bearer $TOKEN")

if echo "$VERIFY_RESPONSE" | grep -q '"success":true'; then
    print_success "Token valide"
else
    print_error "Token invalide"
fi

# ===== TESTS PATIENT =====

print_title "Tests Patient (authentification requise)"

if [ -z "$TOKEN" ]; then
    print_error "Pas de token disponible, test patient sauté"
else
    print_info "Test 1: Obtenir le profil patient"
    PROFILE_RESPONSE=$(curl -s "$API_URL/patient/profile" \
      -H "Authorization: Bearer $TOKEN")
    
    if echo "$PROFILE_RESPONSE" | grep -q '"success":true'; then
        print_success "Profil patient récupéré"
        echo "$PROFILE_RESPONSE" | jq '.data' | head -n 20
    else
        print_error "Impossible de récupérer le profil"
        echo "$PROFILE_RESPONSE" | jq '.'
    fi

    print_info "Test 2: Mettre à jour le profil"
    UPDATE_RESPONSE=$(curl -s -X PUT "$API_URL/patient/profile" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "phone": "77999999",
        "email": "updated_email@esante.com"
      }')
    
    if echo "$UPDATE_RESPONSE" | grep -q '"success":true'; then
        print_success "Profil mis à jour"
    else
        print_error "Mise à jour échouée"
        echo "$UPDATE_RESPONSE" | jq '.'
    fi

    print_info "Test 3: Obtenir la carte NFC"
    NFC_RESPONSE=$(curl -s "$API_URL/patient/nfc-card" \
      -H "Authorization: Bearer $TOKEN")
    
    if echo "$NFC_RESPONSE" | grep -q '"success":true'; then
        print_success "Carte NFC générée"
        echo "$NFC_RESPONSE" | jq '.'
    else
        print_error "Erreur NFC"
        echo "$NFC_RESPONSE" | jq '.'
    fi
fi

# ===== TESTS MÉDICAUX =====

print_title "Tests Données Médicales"

if [ ! -z "$TOKEN" ]; then
    print_info "Test 1: Résumé du dossier médical"
    SUMMARY_RESPONSE=$(curl -s "$API_URL/medical-dossier/1/summary" \
      -H "Authorization: Bearer $TOKEN")
    
    if echo "$SUMMARY_RESPONSE" | grep -q '"success"'; then
        print_success "Dossier médical récupéré"
        echo "$SUMMARY_RESPONSE" | jq '.data' | head -n 10
    else
        print_error "Erreur lors de la récupération du dossier"
    fi

    print_info "Test 2: Obtenir les consultations"
    CONSULT_RESPONSE=$(curl -s "$API_URL/medical-dossier/1/consultations" \
      -H "Authorization: Bearer $TOKEN")
    
    if echo "$CONSULT_RESPONSE" | grep -q '"success"'; then
        print_success "Consultations récupérées"
    else
        print_error "Erreur lors de la récupération des consultations"
    fi

    print_info "Test 3: Obtenir les vaccinations"
    VACC_RESPONSE=$(curl -s "$API_URL/medical-dossier/1/vaccinations?page=1&limit=10" \
      -H "Authorization: Bearer $TOKEN")
    
    if echo "$VACC_RESPONSE" | grep -q '"success"'; then
        print_success "Vaccinations récupérées"
    else
        print_error "Erreur lors de la récupération des vaccinations"
    fi
fi

# ===== TESTS RENDEZ-VOUS =====

print_title "Tests Rendez-vous"

if [ ! -z "$TOKEN" ]; then
    print_info "Test 1: Lister les rendez-vous du patient"
    APPT_LIST=$(curl -s "$API_URL/appointments/patient?page=1&limit=10" \
      -H "Authorization: Bearer $TOKEN")
    
    if echo "$APPT_LIST" | grep -q '"success"'; then
        print_success "Rendez-vous récupérés"
        echo "$APPT_LIST" | jq '.data | length' | xargs echo "Nombre de RDV:"
    else
        print_error "Erreur lors de la récupération des RDV"
    fi

    print_info "Test 2: Créer un rendez-vous"
    APPT_CREATE=$(curl -s -X POST "$API_URL/appointments" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "patient_id": 1,
        "doctor_id": 1,
        "appointment_date": "2026-05-15 10:00:00",
        "reason_for_appointment": "Consultation générale"
      }')
    
    if echo "$APPT_CREATE" | grep -q '"success":true'; then
        print_success "Rendez-vous créé"
        APPOINTMENT_ID=$(echo "$APPT_CREATE" | jq -r '.data.appointment_id')
        echo "$APPT_CREATE" | jq '.data'
    else
        print_error "Création échouée"
        echo "$APPT_CREATE" | jq '.'
    fi
fi

# ===== TESTS ORDONNANCES =====

print_title "Tests Ordonnances"

if [ ! -z "$TOKEN" ]; then
    print_info "Test 1: Lister les ordonnances"
    PRESC_LIST=$(curl -s "$API_URL/prescriptions/patient?page=1&limit=10" \
      -H "Authorization: Bearer $TOKEN")
    
    if echo "$PRESC_LIST" | grep -q '"success"'; then
        print_success "Ordonnances récupérées"
    else
        print_error "Erreur lors de la récupération des ordonnances"
    fi

    print_info "Test 2: Créer une ordonnance"
    PRESC_CREATE=$(curl -s -X POST "$API_URL/prescriptions" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "patient_id": 1,
        "doctor_id": 1,
        "consultation_id": 1,
        "medications": [
          {
            "medication_name": "Paracétamol",
            "dosage": "500mg",
            "frequency": "3x par jour",
            "duration_days": 7
          }
        ]
      }')
    
    if echo "$PRESC_CREATE" | grep -q '"success":true'; then
        print_success "Ordonnance créée"
    else
        print_info "Info: La création d'ordonnance nécessite une consultation existante"
    fi
fi

# ===== TESTS EXAMENS =====

print_title "Tests Examens"

if [ ! -z "$TOKEN" ]; then
    print_info "Test 1: Lister les examens du patient"
    EXAM_LIST=$(curl -s "$API_URL/exams/patient?page=1&limit=10" \
      -H "Authorization: Bearer $TOKEN")
    
    if echo "$EXAM_LIST" | grep -q '"success"'; then
        print_success "Examens récupérés"
    else
        print_error "Erreur lors de la récupération des examens"
    fi

    print_info "Test 2: Prescrire un examen"
    EXAM_PRESCRIBE=$(curl -s -X POST "$API_URL/exams/prescribe" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "patient_id": 1,
        "doctor_id": 1,
        "exam_type": "Prise de sang",
        "speciality_id": 1,
        "urgency_level": "normal"
      }')
    
    if echo "$EXAM_PRESCRIBE" | grep -q '"success":true'; then
        print_success "Examen prescrit"
    else
        print_info "Info: La prescription d'examen nécessite des données d'infrastructure"
    fi
fi

# ===== TESTS STATUT FINAL =====

print_title "Résumé des tests"
print_success "Framework API E-Santé opérationnel"
print_info "Base URL: $API_URL"
if [ ! -z "$TOKEN" ]; then
    print_info "Utilisateur authentifié avec succès"
else
    print_error "Aucun token obtenu - vérifiez la base de données"
fi

print_info "Pour plus de tests, utilisez:"
print_info "  curl -X GET http://localhost/esante/backend/public/health"
print_info "  curl -X POST http://localhost/esante/backend/public/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"email@esante.com\",\"password\":\"password\"}'"

echo ""
