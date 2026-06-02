#!/bin/bash
# Script de vérification de l'intégration
# Prescription par sélection de médicaments

echo "🔍 Vérification de l'intégration - Prescription par Sélection"
echo "==============================================="
echo ""

# 1. Vérifier les fichiers modifiés
echo "1️⃣  Vérification des fichiers..."
if [ -f "lib/screens/medecin/prescribe_ordonnance_screen.dart" ]; then
    echo "   ✅ prescribe_ordonnance_screen.dart trouvé"
    if grep -q "_loadMedications" "lib/screens/medecin/prescribe_ordonnance_screen.dart"; then
        echo "   ✅ Nouvelle méthode _loadMedications() présente"
    else
        echo "   ❌ Nouvelle méthode _loadMedications() manquante"
    fi
else
    echo "   ❌ prescribe_ordonnance_screen.dart manquant"
fi

# 2. Vérifier les imports
echo ""
echo "2️⃣  Vérification des imports..."
if grep -q "import '../../models/prescription_model.dart'" "lib/screens/medecin/prescribe_ordonnance_screen.dart"; then
    echo "   ✅ Import PrescriptionModel présent"
else
    echo "   ⚠️  Import PrescriptionModel manquant (optionnel)"
fi

# 3. Vérifier la base de données
echo ""
echo "3️⃣  Vérification de la base de données..."
if command -v mysql &> /dev/null; then
    # Vérifier qu'il y a des médicaments
    MEDICATION_COUNT=$(mysql -u root -e "SELECT COUNT(*) FROM esante.medication WHERE is_active = 1;" 2>/dev/null | tail -1)
    if [ ! -z "$MEDICATION_COUNT" ] && [ "$MEDICATION_COUNT" -gt 0 ]; then
        echo "   ✅ Table medication trouvée avec $MEDICATION_COUNT médicaments actifs"
    else
        echo "   ❌ Table medication vide ou manquante"
    fi
else
    echo "   ⚠️  MySQL non disponible, vérification manuelle requise"
fi

# 4. Vérifier les fichiers de documentation
echo ""
echo "4️⃣  Vérification de la documentation..."
if [ -f "PRESCRIPTION_MEDICATIONS_GUIDE.md" ]; then
    echo "   ✅ PRESCRIPTION_MEDICATIONS_GUIDE.md créé"
else
    echo "   ❌ PRESCRIPTION_MEDICATIONS_GUIDE.md manquant"
fi

if [ -f "PRESCRIPTION_SELECTION_QUICK_START.md" ]; then
    echo "   ✅ PRESCRIPTION_SELECTION_QUICK_START.md créé"
else
    echo "   ❌ PRESCRIPTION_SELECTION_QUICK_START.md manquant"
fi

# 5. Vérifier la syntaxe Dart (si dart analyzer est disponible)
echo ""
echo "5️⃣  Vérification de la syntaxe Dart..."
if command -v dart &> /dev/null; then
    dart analyze lib/screens/medecin/prescribe_ordonnance_screen.dart 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "   ✅ Syntaxe Dart valide"
    else
        echo "   ❌ Erreurs de syntaxe détectées"
    fi
else
    echo "   ⚠️  Dart analyzer non disponible"
fi

echo ""
echo "==============================================="
echo "✅ Vérification terminée!"
echo ""
echo "Prochaines étapes:"
echo "1. flutter pub get"
echo "2. flutter run"
echo "3. Naviguer vers: Dossier Patient → Ordonnance"
echo "4. Tester la sélection de médicaments"
echo ""
