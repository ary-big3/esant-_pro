# 🐛 Guide Diagnostic - Vitales Ne S'Affichent Pas

## Problème
Les vitales s'enregistrent en base ✅ mais ne s'affichent pas chez le patient ❌ ni dans l'historique ❌

## 🔍 Diagnostic en 5 étapes

### **ÉTAPE 1 : Vérifier la base de données**

1. Ouvrez **phpMyAdmin** : `http://localhost/phpmyadmin`
2. Sélectionnez la DB : `esante_db`
3. Exécutez le script diagnostic :
   - Ouvrez l'onglet **SQL**
   - Copiez le contenu de `DIAGNOSTIC_VITALS.sql`
   - Exécutez

**Que vérifier :**
- Les vitales existent dans `vital_signs` ✅
- Chaque vitale a un `patient_id` non NULL ✅
- Chaque vitale a un `nurse_id` non NULL ✅
- Les `patient_id` correspondent à des patients réels ✅

### **ÉTAPE 2 : Vérifier l'API Backend**

Testez manuellement les endpoints avec **Postman** ou **curl** :

```bash
# Remplacez TOKEN et PATIENT_ID par vos valeurs

# Test 1: Récupérer l'historique
GET http://192.168.8.105/esante/backend/public/nurse/vitals/1?page=1&limit=10
Authorization: Bearer YOUR_TOKEN_HERE

# Réponse attendue:
{
  "success": true,
  "data": [
    {
      "vital_sign_id": 1,
      "patient_id": 1,
      "temperature_celsius": 36.8,
      ...
    }
  ]
}

# Test 2: Récupérer la dernière vitale
GET http://192.168.8.105/esante/backend/public/nurse/vitals/1/latest
Authorization: Bearer YOUR_TOKEN_HERE
```

**Que vérifier :**
- L'API retourne `"success": true` ✅
- Les données ne sont pas vides ✅
- Les valeurs correspondent à la base de données ✅

### **ÉTAPE 3 : Vérifier Flutter (Appel Service)**

Utilisez la **page de debug** fournie : `/lib/screens/debug_vitals_screen.dart`

1. Intégrez-la au main.dart (voir ÉTAPE 4)
2. Entrez le Patient ID
3. Cliquez sur "Test: Historique Vitales"
4. Vérifiez les logs

**Que vérifier :**
- Les appels API réussissent ✅
- Les données sont reçues ✅

### **ÉTAPE 4 : Intégrer la page de debug**

Ajoutez à `lib/main.dart` :

```dart
import 'screens/debug_vitals_screen.dart';

// Dans MaterialApp routes:
routes: {
  '/debug-vitals': (context) => const DebugVitalsScreen(),
  // ... autres routes
}

// Pour y accéder: Navigator.pushNamed(context, '/debug-vitals');
```

Ou ajouter un bouton dans le menu principal.

### **ÉTAPE 5 : Vérifier le flux NurseHomeScreen**

Les historiques peuvent ne pas se charger parce que :

1. ❌ Le `patientId` du formulaire est vide après enregistrement
2. ❌ L'API ne retourne rien
3. ❌ Le widget ne rafraîchit pas après l'enregistrement

## 🔧 Corrections Possibles

### Problème A: Vitales en base mais API ne retourne rien

**Vérifier :** `backend/controllers/NurseController.php` ligne ~135

```php
$stmt = $this->db->prepare(
    'SELECT v.*, n.first_name as nurse_first_name, n.last_name as nurse_last_name
     FROM vital_signs v
     LEFT JOIN nurses n ON v.nurse_id = n.nurse_id  // ✅ Correct
     WHERE v.patient_id = ?
     ORDER BY v.measurement_date DESC
     LIMIT ? OFFSET ?'
);
```

**Si erreur:** Doit référencer `nurses.nurse_id`, pas `users.user_id`

### Problème B: Historique ne se recharge pas

**Vérifier :** `lib/screens/nurse/nurse_home_screen.dart` ligne ~60

```dart
Future<void> _loadVitalsHistory() async {
  final patientId = _patientIdController.text.trim(); // ✅ Correct
  if (patientId.isEmpty) {
    setState(() => _vitalsHistory = []);
    return;
  }
  final vitals = await VitalsService.getPatientVitalsHistory(patientId);
  setState(() => _vitalsHistory = vitals);
}
```

### Problème C: PatientVitalsScreen a un patientId vide

**Vérifier :** Comment on navigue vers cette page

```dart
// ❌ Mauvais
Navigator.push(context, MaterialPageRoute(
  builder: (context) => PatientVitalsScreen(patientId: ''),
));

// ✅ Correct
Navigator.push(context, MaterialPageRoute(
  builder: (context) => PatientVitalsScreen(patientId: patientId),
));
```

## 📋 Checklist Diagnostic

- [ ] Vitales existent en base (query DIAGNOSTIC_VITALS.sql)
- [ ] Vitales ont `patient_id` et `nurse_id` non NULL
- [ ] API `/nurse/vitals/{patientId}` retourne les données
- [ ] API `/nurse/vitals/{patientId}/latest` retourne les données
- [ ] Flutter reçoit les données (vérifier avec DebugVitalsScreen)
- [ ] NurseHomeScreen utilise le bon patientId
- [ ] PatientVitalsScreen reçoit le patientId correct

## 🚨 Next Steps

1. Exécutez `DIAGNOSTIC_VITALS.sql` et envoyez les résultats
2. Testez les endpoints API avec Postman
3. Intégrez et testez `DebugVitalsScreen`
4. Vérifiez les logs Flutter (console)

**Qu'allez-vous voir en premier ?**
