# Guide d'Utilisation: Système de Prescription par Sélection de Médicaments

## 📋 Résumé des Changements

Le système de prescription a été modifié pour permettre aux médecins de **sélectionner des médicaments prédéfinis** au lieu de les saisir manuellement. Cela améliore la cohérence et la rapidité de la prescription.

---

## 🔄 Flux de Travail

### 1. **Médecin ouvre le dossier patient** → Onglet "Ordonnance"

### 2. **Affichage des médicaments prédéfinis**
   - Liste de **tous les médicaments disponibles** groupés par **catégorie**
   - Chaque médicament affiche:
     - Nom complet
     - Dosage recommandé
     - Fréquence suggérée
     - Durée par défaut (en jours)
     - Description/génériques

### 3. **Médecin coche les médicaments**
   - ✅ Case à cocher pour chaque médicament
   - Les détails (dosage, fréquence, durée) sont **automatiquement remplis**
   - **Aucune saisie manuelle requise**

### 4. **Affichage en temps réel**
   - Section "Médicaments prescrits" montre:
     - ✓ Médicament
     - ✓ Dosage exact
     - ✓ Fréquence
     - ✓ Durée
   - Exactement comme s'il avait été saisi manuellement

### 5. **Option: Ajouter un médicament personnalisé**
   - Section en bas: "Ajouter un médicament personnalisé"
   - Pour les médicaments **non présents dans la liste**
   - Le médecin peut remplir les détails manuellement

### 6. **Validation et envoi**
   - Bouton "Prescrire l'ordonnance"
   - Affiche un dialogue de confirmation
   - Liste complète des médicaments prescrits
   - Sauvegarde en base de données
   - Notification au patient

---

## 🔧 Architecture Technique

### Frontend (Flutter - Dart)
**Fichier modifié:** `lib/screens/medecin/prescribe_ordonnance_screen.dart`

**Modifications principales:**
```dart
// Chargement des médicaments depuis l'API
Future<void> _loadMedications() async {
  final response = await _apiService.get('/medications?limit=100');
  _availableMedications = response['data']['medications'];
}

// Sélection/déselection d'un médicament
void _toggleMedicationSelection(Map<String, dynamic> medication) {
  if (selectedMedicationIds[medId]) {
    // Décocher: retirer de la prescription
  } else {
    // Cocher: ajouter avec détails prédéfinis
    _prescribedMedications.add({
      'medication_name': medication['medication_name'],
      'dosage': medication['dosage'],
      'frequency': medication['frequency'],
      'duration': medication['default_duration'],
      // ... autres détails
    });
  }
}
```

### Backend (PHP)
**Fichier existant:** `backend/controllers/MedicationController.php`

**Endpoint utilisé:**
```
GET /api/medications
Parameters:
  - category (optionnel): Filtrer par catégorie
  - search (optionnel): Chercher par nom
  - limit: Nombre de résultats (défaut: 50)
  - page: Numéro de page

Response:
{
  "success": true,
  "data": {
    "medications": [
      {
        "medication_id": 1,
        "medication_name": "Amoxicilline",
        "generic_name": "amoxicilline",
        "dosage": "500",
        "dosage_unit": "mg",
        "frequency": "3x/jour",
        "default_duration": 7,
        "route_of_administration": "oral",
        "category": "Antibiotique",
        "description": "..."
      }
    ],
    "total": 25
  }
}
```

### Base de Données
**Table existante:** `medication`

```sql
CREATE TABLE `medication` (
  `medication_id` int(11) NOT NULL,
  `medication_name` varchar(255) NOT NULL,
  `generic_name` varchar(255) DEFAULT NULL,
  `dosage` varchar(50) NOT NULL,
  `dosage_unit` varchar(20) NOT NULL DEFAULT 'mg',
  `frequency` varchar(50) NOT NULL DEFAULT '1x/jour',
  `default_duration` int(11) NOT NULL DEFAULT 7,
  `route_of_administration` varchar(50) NOT NULL DEFAULT 'oral',
  `category` varchar(100) NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
);
```

---

## ✨ Caractéristiques

### ✅ Sélection Simple
- Cases à cocher intuitives
- Regroupement par catégorie
- Filtres dynamiques

### ✅ Détails Prédéfinis
- Tous les champs remplis automatiquement
- Dosages conformes aux normes médicales
- Fréquences recommandées

### ✅ Affichage Uniforme
- Les médicaments cochés s'affichent **exactement** comme s'ils avaient été saisis
- Même format, même structure
- Patient voit les mêmes informations

### ✅ Flexibilité
- Option pour ajouter des médicaments non présents dans la liste
- Saisie manuelle restante pour cas spéciaux
- Mélange de médicaments prédéfinis + personnalisés

### ✅ Performance
- Chargement une seule fois au démarrage
- Cache local des médicaments
- Filtrage instantané par catégorie

---

## 🧪 Test de l'Intégration

### 1. **Prérequis**
- ✅ Table `medication` créée avec données
- ✅ Endpoint `/medications` fonctionnel
- ✅ Authentification active

### 2. **Scénario de Test**

**Étape 1:** Ouvrir le dossier d'un patient
```
Menu médecin → Patients → Sélectionner patient → Ordonnance
```

**Étape 2:** Observer la liste de médicaments
```
Devrait voir:
- Filtres par catégorie (Antibiotique, Antalgique, etc.)
- Liste de 25+ médicaments
- Chacun avec case à cocher
```

**Étape 3:** Cocher 3-4 médicaments
```
- Amoxicilline 500mg
- Paracétamol 500mg  
- Ibuprofen 200mg
```

**Étape 4:** Observer la section "Médicaments prescrits"
```
Devrait voir:
✓ Amoxicilline 500 mg • 3x/jour • 7 jours
✓ Paracétamol 500 mg • 3x/jour • 3 jours
✓ Ibuprofen 200 mg • 3x/jour • 5 jours
```

**Étape 5:** Prescrire l'ordonnance
```
- Affiche dialogue de confirmation
- Voir tous les médicaments sélectionnés
- Cliquer OK → Sauvegarde réussie
```

**Étape 6:** Patient voit l'ordonnance
```
Identique au format manuel, avec:
- Chaque médicament avec dosage exact
- Fréquence
- Durée
```

---

## 🐛 Dépannage

### Problème: Liste vide
**Cause:** Endpoint `/medications` non accessible
**Solution:** 
- Vérifier que `MedicationController::getAllMedications()` est actif
- Vérifier l'authentification

### Problème: Checkboxes ne se cochent pas
**Cause:** Erreur dans `_toggleMedicationSelection()`
**Solution:** 
- Vérifier la console Dart/Flutter
- Vérifier que `_selectedMedicationIds` est initialisé

### Problème: Les détails ne s'affichent pas
**Cause:** Champs vides dans la base de données
**Solution:** 
- Vérifier que la table `medication` contient les données
- Exécuter les INSERT fournis

---

## 📊 Données de Référence

**25 médicaments prédéfinis inclus:**
1. **Antibiotiques** (5): Amoxicilline, Azithromycine, Ciprofloxacine, Ceftriaxone, Amoxicilline-Ac. clavulanique
2. **Antalgiques** (3): Paracétamol, Ibuprofène, Acide acétylsalicylique
3. **Anti-inflammatoires** (2): Ibuprofène, Diclofénac
4. **Antihistaminiques** (2): Cétirizine, Loratadine
5. **Autres catégories** (13): Corticostéroïdes, Anti-nausées, Digestifs, Antiviraux, Antidiabétiques, Antihypertenseurs, etc.

---

## 🚀 Prochaines Étapes Possibles

1. **Importer plus de médicaments** depuis une pharmacopée
2. **Ajouter des interactions médicamenteuses** 
3. **Mémoriser les préférences** du médecin
4. **Historique des prescriptions** par patient
5. **Alertes d'allergies** lors de la sélection
6. **Intégration avec la pharmacie** pour le stock

---

## 📞 Support

Pour toute question ou problème, consultez:
- Documentation: `PRESCRIPTION_MEDICATIONS_GUIDE.md` (ce fichier)
- Code: `lib/screens/medecin/prescribe_ordonnance_screen.dart`
- API: `backend/controllers/MedicationController.php`
