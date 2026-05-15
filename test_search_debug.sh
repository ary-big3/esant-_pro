#!/bin/bash

# Script de test pour la recherche patient
# Teste l'API backend directement

BASE_URL="http://192.168.8.104/esante/backend/public"
ENDPOINT="/doctors/search-patients"

echo "🔍 Test de l'API de recherche patient"
echo "URL: $BASE_URL$ENDPOINT"
echo ""

# Test 1: Sans authentification (doit échouer avec "Token manquant")
echo "Test 1: Sans authentification"
curl -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d '{"search_query": "test"}' \
  -w "\nHTTP Status: %{http_code}\n\n" | jq . || echo "JSON parse error"

# Test 2: Avec un token invalide (doit échouer avec erreur JWT)
echo ""
echo "Test 2: Avec token invalide"
curl -X POST "${BASE_URL}${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer invalid_token_xyz" \
  -d '{"search_query": "test"}' \
  -w "\nHTTP Status: %{http_code}\n\n" | jq . || echo "JSON parse error"

echo ""
echo "✅ Tests API complétés"
echo "Vérifiez les réponses ci-dessus pour vérifier que:"
echo "  - Test 1 retourne: 'Token manquant'"
echo "  - Test 2 retourne: 'Erreur lors du décodage JWT'"
