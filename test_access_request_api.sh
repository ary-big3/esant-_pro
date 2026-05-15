#!/bin/bash

# =====================================================
# GUIDE DE TEST MANUEL - SYSTÈME DE DEMANDES D'ACCÈS
# =====================================================

# Configuration
BASE_URL="http://localhost/esante/backend/public"
DOCTOR_TOKEN="your_doctor_token_here"
PATIENT_TOKEN="your_patient_token_here"

echo "🚀 GUIDE DE TEST COMPLET"
echo "======================="

# =====================================================
# ÉTAPE 1: MÉDECIN DEMANDE L'ACCÈS
# =====================================================
echo ""
echo "📋 ÉTAPE 1: Médecin demande accès"
echo "===================================="

curl -X POST "$BASE_URL/doctors/request-patient-access" \
  -H "Authorization: Bearer $DOCTOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": 1,
    "reason": "Consultation cardiaque",
    "permission_type": "view_only"
  }' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "✅ Une demande d'accès doit être créée"
echo "✅ Une notification doit être envoyée au patient"
echo ""

# =====================================================
# ÉTAPE 2: PATIENT RÉCUPÈRE SES DEMANDES
# =====================================================
echo "📋 ÉTAPE 2: Patient récupère ses demandes"
echo "=========================================="

curl -X GET "$BASE_URL/patients/pending-requests?page=1&limit=50" \
  -H "Authorization: Bearer $PATIENT_TOKEN" \
  -H "Content-Type: application/json" \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "✅ La demande doit apparaître dans la liste"
echo ""

# =====================================================
# ÉTAPE 3: PATIENT APPROUVE LA DEMANDE
# =====================================================
echo "📋 ÉTAPE 3: Patient approuve la demande"
echo "========================================"

REQUEST_ID=1  # Récupéré à partir de l'étape 2

curl -X POST "$BASE_URL/patients/requests/$REQUEST_ID/approve" \
  -H "Authorization: Bearer $PATIENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "✅ La demande doit être marquée comme approuvée"
echo "✅ Une permission d'accès doit être créée"
echo "✅ Le médecin doit recevoir une notification"
echo ""

# =====================================================
# ÉTAPE 4: VÉRIFIER LA NOTIFICATION DU MÉDECIN
# =====================================================
echo "📋 ÉTAPE 4: Médecin consulte les notifications"
echo "=============================================="

curl -X GET "$BASE_URL/notifications?page=1&limit=50" \
  -H "Authorization: Bearer $DOCTOR_TOKEN" \
  -H "Content-Type: application/json" \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "✅ Notification 'access_approved' doit apparaître"
echo ""

# =====================================================
# ÉTAPE 5: VÉRIFIER QUE LE MÉDECIN A ACCÈS
# =====================================================
echo "📋 ÉTAPE 5: Vérifier l'accès du médecin"
echo "======================================"

PATIENT_ID=1

curl -X GET "$BASE_URL/access-requests/check/$PATIENT_ID" \
  -H "Authorization: Bearer $DOCTOR_TOKEN" \
  -H "Content-Type: application/json" \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "✅ Réponse: has_access=true, permission_type=view_only"
echo ""

# =====================================================
# ÉTAPE 6: VÉRIFIER LES LOGS D'ACCÈS
# =====================================================
echo "📋 ÉTAPE 6: Vérifier les logs en base de données"
echo "==============================================="

cat <<'EOF'

Exécuter cette requête SQL:

SELECT 
  al.log_id,
  u.full_name as user,
  p.patient_id,
  al.action_type,
  al.access_status,
  al.ip_address,
  al.access_timestamp
FROM access_logs al
JOIN users u ON al.user_id = u.user_id
LEFT JOIN patients p ON al.accessed_patient_id = p.patient_id
ORDER BY al.log_id DESC
LIMIT 10;

✅ Vous devriez voir les logs d'accès du médecin

EOF

echo ""

# =====================================================
# ÉTAPE 7: TESTER LE REJET (ALTERNATIVE)
# =====================================================
echo "📋 ÉTAPE 7 (Alternative): Tester le rejet"
echo "========================================="

NEW_REQUEST_ID=2

curl -X POST "$BASE_URL/patients/requests/$NEW_REQUEST_ID/reject" \
  -H "Authorization: Bearer $PATIENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Je n'\''accepte pas de partager"}' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "✅ La demande doit être marquée comme rejetée"
echo "✅ Le médecin doit recevoir une notification de rejet"
echo ""

# =====================================================
# RÉSUMÉ
# =====================================================
echo ""
echo "🎯 RÉSUMÉ DE LA VÉRIFICATION"
echo "============================="
cat <<'EOF'

✅ Médecin crée une demande d'accès
✅ Patient reçoit une notification
✅ Patient voit la demande dans son écran
✅ Patient approuve ou rejette
✅ Médecin reçoit une notification
✅ Accès accordé ou refusé
✅ Tous les logs sont enregistrés en BD

BASE DE DONNÉES À VÉRIFIER:
- access_requests (statut updated)
- access_permissions (créée si approuvée)
- notifications (créées)
- access_logs (journalisées)

EOF

echo ""
echo "📝 Notes:"
echo "- Remplacer DOCTOR_TOKEN et PATIENT_TOKEN par de vrais tokens"
echo "- Remplacer patient_id par un ID réel"
echo "- Remplacer request_id par un ID réel issu de la réponse"
echo ""
