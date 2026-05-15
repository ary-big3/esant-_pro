# 🔧 GUIDE D'INTÉGRATION - ÉCRAN INFIRMIÈRE

## 📋 Fichiers créés

### 1. **Modèles** (`lib/models/`)
- ✅ `vitals_model.dart` - Modèle des constantes vitales

### 2. **Services** (`lib/services/`)
- ✅ `vitals_service.dart` - Service de gestion des constantes vitales
- ✅ `vitals_database.sql` - Schéma SQL pour la base de données

### 3. **Écrans** (`lib/screens/nurse/`)
- ✅ `nurse_screen.dart` - Interface complète infirmière

### 4. **Documentation**
- ✅ `NURSE_ACCESS_GUIDE.md` - Guide utilisateur pour les infirmières
- ✅ Cette page

---

## 🚀 Comment intégrer dans l'application

### Étape 1: Importer l'écran dans le système de navigation

Dans `lib/main.dart` ou votre fichier de navigation principal:

```dart
import 'screens/nurse/nurse_screen.dart';
```

### Étape 2: Ajouter une route pour l'écran infirmière

Exemple avec Firebase Authentication:

```dart
// Dans MaterialApp ou GoRouter
routes: {
  '/nurse': (context) => const NurseScreen(),
  // ... autres routes
},
```

### Étape 3: Ajouter un bouton d'accès pour les infirmières

Dans votre écran d'accueil ou menu principal:

```dart
// Pour les utilisateurs avec le rôle infirmière
if (currentUser?.role == UserRole.nurse) {
  ElevatedButton.icon(
    onPressed: () => Navigator.of(context).pushNamed('/nurse'),
    icon: const Icon(Icons.health_and_safety),
    label: const Text('Constantes Vitales'),
  ),
}
```

### Étape 4: Configurer la base de données

Exécutez le schéma SQL (`vitals_database.sql`) sur votre base de données:

```sql
-- Dans votre structure de base de données
-- Exécutez le contenu de vitals_database.sql
```

### Étape 5: Mettre à jour l'authentification

Ajoutez le rôle infirmière à votre énumération UserRole:

```dart
enum UserRole {
  admin,
  doctor,
  nurse,           // ← NOUVEAU
  patient,
  laboratory,
  pharmacist,
}
```

### Étape 6: Adapter le VitalsService pour votre API

Remplacez les données simulées par vos appels API réels:

```dart
// Dans lib/services/vitals_service.dart

static Future<VitalsModel> recordVitals({...}) async {
  try {
    // TODO: Implémenter l'appel API réel
    final response = await http.post(
      Uri.parse('https://api.hopital.local/api/vitals/record'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'patient_id': patientId,
        'nurse_id': nurseId,
        'temperature': temperature,
        // ... autres champs
      }),
    );
    
    if (response.statusCode == 201) {
      return VitalsModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erreur lors de l\'enregistrement: $e');
  }
}
```

---

## 🎯 Cas d'utilisation

### 1. Infirmière enregistre les constantes
```
1. Infirmière se connecte avec son compte (rôle: nurse)
2. Clique sur "Constantes Vitales"
3. Saisit l'ID du patient
4. Remplit le formulaire avec les mesures
5. Clique sur "Enregistrer"
6. Les données sont sauvegardées et visibles dans le dossier patient
```

### 2. Correction d'une erreur
```
1. Infirmière voit l'historique
2. Identifie l'erreur
3. Clique sur "Modifier"
4. Corrige la valeur
5. Clique sur "Mettre à jour"
```

### 3. Consultation par le médecin
```
1. Médecin accède au dossier patient
2. Voit les constantes vitales enregistrées
3. Analyse les tendances sur 24h
4. Utilise les données pour son diagnostic
```

---

## 🔒 Sécurité et permissions

### Contrôle d'accès recommandé

```dart
// Dans nurse_screen.dart, ajouter verification
@override
void initState() {
  super.initState();
  
  // Vérifier que l'utilisateur a le rôle infirmière
  if (currentUser?.role != UserRole.nurse) {
    Navigator.of(context).pop();
    throw Exception('Accès refusé: vous n\'êtes pas infirmière');
  }
}
```

### Audit et traçabilité

Chaque enregistrement inclut:
- ✅ `nurse_id` - Identifie qui a entré les données
- ✅ `created_at` - Timestamp de la création
- ✅ `updated_at` - Timestamp des modifications
- ✅ `recorded_at` - Heure de la mesure réelle

---

## 📊 API Endpoints nécessaires

### POST /api/vitals/record
Créer un nouvel enregistrement de constantes
```json
{
  "patient_id": "PAT-123",
  "nurse_id": "NURSE-001",
  "temperature": 37.2,
  "tension_systolique": 120,
  "tension_diastolique": 80,
  "frequence_cardiaque": 72,
  "frequence_respiratoire": 16,
  "satur_oxygene": 98.5,
  "poids": 75,
  "taille": 180,
  "notes": "Patient stable"
}
```

### GET /api/vitals/patient/{patientId}
Récupérer l'historique des constantes d'un patient

### GET /api/vitals/{vitalsId}
Récupérer un enregistrement spécifique

### PUT /api/vitals/{vitalsId}
Mettre à jour un enregistrement

### DELETE /api/vitals/{vitalsId}
Supprimer un enregistrement

---

## 🧪 Tests

### Test en mode démo
```dart
// Les données sont simulées, pas de base de données requise
// Parfait pour tester l'interface utilisateur
```

### Test avec API réelle
```dart
// Remplacer les TODO dans VitalsService
// Implémenter les vrais appels HTTP
// Configurer l'authentification Token
```

### Test unitaire
```dart
test('recordVitals should return VitalsModel', () async {
  final vitals = await VitalsService.recordVitals(
    patientId: 'PAT-123',
    nurseId: 'NURSE-001',
    temperature: 37.2,
    tensionSystolique: 120,
    tensionDiastolique: 80,
    frequenceCardiaque: 72,
    frequenceRespiratoire: 16,
    saturOxygene: 98.5,
  );
  
  expect(vitals.id, isNotEmpty);
  expect(vitals.temperature, 37.2);
});
```

---

## 🐛 Troubleshooting

| Problème | Solution |
|----------|----------|
| Import error: NurseScreen not found | Vérifier le chemin: `screens/nurse/nurse_screen.dart` |
| VitalsService not recognized | Importer: `import '../../services/vitals_service.dart';` |
| Compilation error: undefined symbol | S'assurer que VitalsModel est créé dans `models/vitals_model.dart` |
| API 404 Not Found | Implémenter les endpoints API côté serveur |
| Données non persistées | Vérifier que la table `patient_vitals` existe dans la DB |

---

## 📈 Évolutions futures

### Phase 2:
- [ ] Graphiques de tendances (température, FC sur 7 jours)
- [ ] Exportation en PDF des rapports de constantes
- [ ] Alertes automatiques si constantes anormales
- [ ] Synchronisation mobile avec serveur

### Phase 3:
- [ ] Intégration avec capteurs IoT
- [ ] Recommandations IA basées sur les constantes
- [ ] Partage sécurisé avec le médecin
- [ ] Comparaison des tendances

### Phase 4:
- [ ] Application infirmière mobile native
- [ ] Biométrie offline pour urgences
- [ ] Intégration avec montres connectées
- [ ] Notifications push pour alertes

---

## 📞 Support développement

### Ressources:
- Flutter Documentation: https://flutter.dev/docs
- SQLite Docs: https://www.sqlite.org/docs.html
- REST API Best Practices: https://restfulapi.net/

### Checklist d'intégration:
- [ ] Fichiers créés dans les bons répertoires
- [ ] Imports corrects dans tous les fichiers
- [ ] Schéma SQL exécuté dans la base de données
- [ ] Route ajoutée à la navigation principale
- [ ] Rôle "nurse" défini dans UserRole enum
- [ ] API endpoints implémentés
- [ ] Tests effectués en mode démo
- [ ] Tests avec API réelle
- [ ] Documentation mise à jour

---

**État**: ✅ Prêt pour intégration  
**Version**: 1.0.0  
**Dernière mise à jour**: 13 avril 2026
