# 🧪 Commandes de Test Rapide - Constantes Vitales

## 📋 Avant de Commencer

Assurez-vous que :
- ✅ Le serveur PHP est en cours d'exécution
- ✅ MySQL est accessible
- ✅ Le token JWT valide est disponible
- ✅ Flutter SDK est installé

---

## 🔧 Vérifications du Système

### 1. Vérifier le serveur PHP
```bash
# Windows
php -S localhost:8000

# Ou via Apache/XAMPP
# Démarrer XAMPP Control Panel
```

### 2. Vérifier la base de données
```bash
# Vérifier la connexion MySQL
mysql -u root -p -e "SELECT VERSION();"

# Vérifier la base de données esante
mysql -u root -p -e "USE esante; SELECT * FROM users LIMIT 1;"
```

### 3. Vérifier Flutter
```bash
flutter --version
flutter doctor
```

---

## 🔐 Obtenir un Token JWT

### Via API
```bash
curl -X POST http://192.168.8.105/esante/backend/public/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "nurse@esante.com",
    "password": "password123"
  }'
```

**Réponse :**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### Copier le token
```bash
# Exporter dans une variable d'environnement (Powershell)
$env:JWT_TOKEN = "eyJhbGci..."
```

---

## 🧪 Tests API avec cURL

### Test 1: Enregistrer les Constantes
```bash
curl -X POST http://192.168.8.105/esante/backend/public/nurse/vitals \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $env:JWT_TOKEN" \
  -d '{
    "patient_id": 1,
    "temperature_celsius": 37.2,
    "systolic_pressure": 120,
    "diastolic_pressure": 80,
    "pulse_bpm": 72,
    "respiratory_rate": 16,
    "oxygen_saturation": 98.0,
    "weight_kg": 70,
    "height_cm": 175,
    "status": "normal",
    "notes": "Patient en bon état"
  }'

# Réponse attendue: 201 Created
# Copier le vital_sign_id de la réponse
```

### Test 2: Récupérer l'Historique
```bash
curl -X GET "http://192.168.8.105/esante/backend/public/nurse/vitals/1?page=1&limit=10" \
  -H "Authorization: Bearer $env:JWT_TOKEN"

# Réponse attendue: 200 OK avec liste des constantes
```

### Test 3: Récupérer les Dernières Constantes
```bash
curl -X GET "http://192.168.8.105/esante/backend/public/nurse/vitals/1/latest" \
  -H "Authorization: Bearer $env:JWT_TOKEN"

# Réponse attendue: 200 OK avec une seule mesure
```

### Test 4: Mettre à Jour les Constantes
```bash
# Remplacer {vitalId} par l'ID récupéré du Test 1
curl -X PUT "http://192.168.8.105/esante/backend/public/nurse/vitals/{vitalId}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $env:JWT_TOKEN" \
  -d '{
    "temperature_celsius": 37.5,
    "systolic_pressure": 125,
    "diastolic_pressure": 85,
    "notes": "Mise à jour - Patient stable"
  }'

# Réponse attendue: 200 OK
```

### Test 5: Supprimer les Constantes
```bash
# Remplacer {vitalId} par l'ID récupéré du Test 1
curl -X DELETE "http://192.168.8.105/esante/backend/public/nurse/vitals/{vitalId}" \
  -H "Authorization: Bearer $env:JWT_TOKEN"

# Réponse attendue: 200 OK
```

---

## 📱 Tests Flutter

### 1. Lancer l'Application
```bash
cd c:\xampp\htdocs\esante
flutter run
```

### 2. Accéder à l'Écran des Constantes (Infirmière)
```
Menu → Espace Infirmière → Constantes Vitales
```

### 3. Tester l'Enregistrement
- Entrer ID Patient : 1
- Remplir tous les champs
- Cliquer "Enregistrer"
- ✅ Vérifier le message de succès

### 4. Tester l'Historique
- Aller à l'onglet "Historique"
- ✅ Vérifier que la constante apparaît
- Tester "Modifier" et "Supprimer"

### 5. Tester l'IMC
- Entrer Poids : 70 kg
- Entrer Taille : 175 cm
- ✅ Vérifier IMC = 22.86 (vert/normal)

---

## 🧪 Tests Batch (Powershell)

### Script de Test Complet
```powershell
# test-vitals.ps1

# Configuration
$baseUrl = "http://192.168.8.105/esante/backend/public"
$email = "nurse@esante.com"
$password = "password123"

# 1. Obtenir le token
Write-Host "🔐 Authentification..." -ForegroundColor Cyan
$loginResponse = Invoke-WebRequest -Uri "$baseUrl/auth/login" `
  -Method Post `
  -ContentType "application/json" `
  -Body @{
    email = $email
    password = $password
  } | ConvertFrom-Json

$token = $loginResponse.data.token
Write-Host "✅ Token obtenu: $($token.Substring(0, 20))..." -ForegroundColor Green

# 2. Enregistrer les constantes
Write-Host "📝 Enregistrement des constantes..." -ForegroundColor Cyan
$recordResponse = Invoke-WebRequest -Uri "$baseUrl/nurse/vitals" `
  -Method Post `
  -ContentType "application/json" `
  -Headers @{"Authorization" = "Bearer $token"} `
  -Body @{
    patient_id = 1
    temperature_celsius = 37.2
    systolic_pressure = 120
    diastolic_pressure = 80
    pulse_bpm = 72
    respiratory_rate = 16
    oxygen_saturation = 98.0
    weight_kg = 70
    height_cm = 175
    notes = "Test"
  } | ConvertFrom-Json

$vitalId = $recordResponse.data.vital_sign_id
Write-Host "✅ Constantes enregistrées: ID=$vitalId" -ForegroundColor Green

# 3. Récupérer l'historique
Write-Host "📊 Récupération de l'historique..." -ForegroundColor Cyan
$historyResponse = Invoke-WebRequest -Uri "$baseUrl/nurse/vitals/1?page=1&limit=10" `
  -Method Get `
  -Headers @{"Authorization" = "Bearer $token"} | ConvertFrom-Json

Write-Host "✅ Historique récupéré: $($historyResponse.data.Count) mesures" -ForegroundColor Green

# 4. Mettre à jour
Write-Host "✏️ Mise à jour de la constante..." -ForegroundColor Cyan
$updateResponse = Invoke-WebRequest -Uri "$baseUrl/nurse/vitals/$vitalId" `
  -Method Put `
  -ContentType "application/json" `
  -Headers @{"Authorization" = "Bearer $token"} `
  -Body @{
    temperature_celsius = 37.5
    notes = "Mise à jour test"
  } | ConvertFrom-Json

Write-Host "✅ Constante mise à jour" -ForegroundColor Green

# 5. Supprimer
Write-Host "🗑️ Suppression de la constante..." -ForegroundColor Cyan
$deleteResponse = Invoke-WebRequest -Uri "$baseUrl/nurse/vitals/$vitalId" `
  -Method Delete `
  -Headers @{"Authorization" = "Bearer $token"} | ConvertFrom-Json

Write-Host "✅ Constante supprimée" -ForegroundColor Green

Write-Host ""
Write-Host "✅ TOUS LES TESTS RÉUSSIS!" -ForegroundColor Green
```

**Exécuter le script :**
```bash
powershell -ExecutionPolicy Bypass -File test-vitals.ps1
```

---

## 🐛 Débogage

### Logs Flutter
```bash
# Afficher les logs en temps réel
flutter logs

# Filtrer par tag
flutter logs -f "VitalsService"
```

### Logs PHP
```bash
# Afficher les logs du serveur
tail -f backend/logs/app.log

# Ou via Postman (voir onglet "Console")
```

### Logs MySQL
```bash
# Afficher les requêtes lentes
mysql -u root -p -e "SET GLOBAL long_query_time = 0;"
```

---

## 📊 Vérifications de Sécurité

### Test 1: Sans Token
```bash
curl -X GET "http://192.168.8.105/esante/backend/public/nurse/vitals/1"

# Réponse attendue: 401 Unauthorized
```

### Test 2: Token Invalide
```bash
curl -X GET "http://192.168.8.105/esante/backend/public/nurse/vitals/1" \
  -H "Authorization: Bearer invalid_token"

# Réponse attendue: 401 Unauthorized
```

### Test 3: Rôle Patient (pas Infirmière)
```bash
# 1. Obtenir token patient
# 2. Tenter POST /nurse/vitals
curl -X POST "http://192.168.8.105/esante/backend/public/nurse/vitals" \
  -H "Authorization: Bearer $patientToken" \
  -H "Content-Type: application/json" \
  -d '{...}'

# Réponse attendue: 403 Forbidden
```

---

## 📈 Tests de Performance

### Test de Charge
```powershell
# Créer 100 constantes
for ($i = 1; $i -le 100; $i++) {
    Invoke-WebRequest -Uri "$baseUrl/nurse/vitals" `
      -Method Post `
      -ContentType "application/json" `
      -Headers @{"Authorization" = "Bearer $token"} `
      -Body @{...} | Out-Null
    
    if ($i % 10 -eq 0) {
        Write-Host "✅ $i constantes créées" -ForegroundColor Green
    }
}
```

### Mesurer le Temps de Réponse
```bash
# Linux/Mac
time curl -X GET "http://192.168.8.105/esante/backend/public/nurse/vitals/1" \
  -H "Authorization: Bearer $token"

# Powershell
Measure-Command {
  Invoke-WebRequest -Uri "..." -Headers @{...}
}
```

---

## ✅ Checklist de Test

- [ ] Authentification fonctionne
- [ ] Enregistrement des constantes OK
- [ ] Historique affiche les constantes
- [ ] Modification fonctionne
- [ ] Suppression fonctionne
- [ ] IMC calculé correctement
- [ ] Codes couleur OK
- [ ] Sans token → erreur 401
- [ ] Rôle patient → erreur 403
- [ ] Performance acceptable
- [ ] Interface responsive
- [ ] Pas d'erreurs console
- [ ] Données persistées en DB
- [ ] Notifications OK
- [ ] Validation complète

---

## 🚀 Deploiement Fast Track

### 1 minute
```bash
# Juste tester
curl -X GET "http://localhost:8000/esante/backend/public/health"
```

### 5 minutes
```bash
# Test API rapide
# 1. Obtenir token
# 2. Tester POST vitals
# 3. Tester GET historique
```

### 15 minutes
```bash
# Test complet
# + Modification
# + Suppression
# + Sécurité
```

### 30 minutes
```bash
# Test APP Flutter
# + UI responsiveness
# + Performance
# + Intégration
```

---

## 📞 En Cas de Problème

### Erreur 404
```
❌ Route non trouvée
✅ Vérifier Router.php a été modifié
✅ Redémarrer le serveur PHP
```

### Erreur 500
```
❌ Erreur serveur
✅ Vérifier les logs PHP
✅ Vérifier la syntaxe du contrôleur
✅ Vérifier la BD est connectée
```

### Token expiré
```
❌ Token invalide
✅ Obtenir un nouveau token
✅ Vérifier la durée d'expiration
```

### Données non affichées
```
❌ Données manquantes
✅ Vérifier les données en BD
✅ Vérifier les permissions
✅ Rafraîchir l'app Flutter
```

---

## 📊 Résumé des Commandes

| Commande | But |
|----------|-----|
| `flutter run` | Lancer l'app |
| `flutter logs` | Afficher les logs |
| `curl -X GET ...` | Tester API |
| `php -S localhost:8000` | Serveur PHP |
| `mysql -u root -p` | Base de données |
| `flutter doctor` | Vérifier l'environnement |

---

**Prêt à tester !** 🚀

Dernière mise à jour : 29 avril 2026
