# 🚀 QUICKSTART - Démarrer avec E-Santé

**Dernière mise à jour**: 15 Avril 2026  
**Status**: ✅ Production Ready

---

## ⚡ Démarrage en 5 Étapes

### 1️⃣ Vérifier la Base de Données
```bash
# Ouvrir phpMyAdmin
http://localhost/phpmyadmin

# Importer la base de données
1. Créer une nouvelle base: "esante_db"
2. Importer le fichier: esante/database.sql
3. Vérifier: 25 tables créées
```

### 2️⃣ Configurer l'Environnement
```bash
# Créer le fichier .env (optionnel)
cp esante/backend/.env.example esante/backend/.env

# Vérifier la configuration
# Dans backend/config/database.php:
DB_HOST=localhost
DB_USER=root
DB_PASS=(empty ou votre password)
DB_NAME=esante_db
```

### 3️⃣ Vérifier l'Installation
```bash
# Ouvrir dans le navigateur
http://localhost/esante/backend/public/setup-check.php

# Vérifier les statuts:
✅ PHP Version: 7.2+
✅ MySQLi Extension: Installée
✅ Database: Connectée
✅ Tables: 25/25 présentes
✅ File Permissions: OK
```

### 4️⃣ Tester l'API (Santé)
```bash
# Vérifier que l'API répond
curl http://localhost/esante/backend/public/health

# Réponse attendue:
{
  "success": true,
  "message": "API saine",
  "data": {
    "status": "API en ligne",
    "timestamp": "2026-04-15 10:30:45"
  }
}
```

### 5️⃣ Tester Authentification
```bash
# Inscription
curl -X POST http://localhost/esante/backend/public/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@esante.com",
    "password": "SecurePass123",
    "full_name": "Test User",
    "phone": "77123456",
    "role": "patient"
  }'

# Connexion
curl -X POST http://localhost/esante/backend/public/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@esante.com",
    "password": "SecurePass123"
  }'

# Réponse: Token JWT
```

---

## 📖 Documentation Rapide

| Document | Durée | Contenu |
|----------|-------|---------|
| [ACCOMPLISHMENT.md](ACCOMPLISHMENT.md) | 10 min | Vue d'ensemble complète |
| [STRUCTURE.md](STRUCTURE.md) | 10 min | Arborescence du projet |
| [FILE_INDEX.md](FILE_INDEX.md) | 10 min | Index des fichiers |
| [backend/INSTALLATION.md](backend/INSTALLATION.md) | 20 min | Guide d'installation |
| [backend/README.md](backend/README.md) | 15 min | Configuration & Structure |
| [backend/API_ROUTES.md](backend/API_ROUTES.md) | 30 min | 50+ routes détaillées |

---

## 🔑 Endpoints Principaux

### Authentification
```
POST /auth/register          # Inscription
POST /auth/login             # Connexion
GET /auth/verify-token       # Vérifier token
POST /auth/refresh-token     # Rafraîchir token
```

### Patient
```
GET /patient/profile         # Mon profil
PUT /patient/profile         # Mettre à jour
GET /patient/children        # Mes enfants
```

### Médical
```
GET /medical-dossier/{id}/summary          # Dossier
GET /medical-dossier/{id}/consultations    # Consultations
GET /medical-dossier/{id}/exams            # Examens
GET /medical-dossier/{id}/vaccinations     # Vaccinations
```

### Rendez-vous
```
POST /appointments                         # Créer
GET /appointments/patient                  # Mes RDV
GET /appointments/doctor/{id}              # RDV médecin
```

**Pour tous les 50+ endpoints**: Voir [API_ROUTES.md](backend/API_ROUTES.md)

---

## 🧪 Tester avec Postman

### Importer Collection
1. Télécharger: [E-Sante-API-Collection.postman_collection.json](backend/E-Sante-API-Collection.postman_collection.json)
2. Ouvrir Postman
3. Cliquer: Import → Sélectionner le fichier → Import

### Workflow de Test
```
1. Auth / Connexion
   ├── Note le token obtenu
   └── Définir variable: token
2. Patient / Obtenir Profil
   ├── Clique: Obtenir Profil
   └── Headers: Authorization: Bearer {token}
3. Dossier Médical / Résumé
4. Rendez-vous / Créer RDV
5. Et ainsi de suite...
```

---

## 🔒 Authentification

### Obtenir un Token
```bash
curl -X POST http://localhost/esante/backend/public/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@esante.com","password":"password"}'

# Réponse:
{
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### Utiliser le Token
```bash
curl -H "Authorization: Bearer {token}" \
  http://localhost/esante/backend/public/patient/profile
```

### Token Expiré?
```bash
# Rafraîchir le token
curl -X POST http://localhost/esante/backend/public/auth/refresh-token \
  -H "Authorization: Bearer {old_token}"

# Nouveau token obtenu
```

---

## 📊 Cas d'Utilisation

### Scénario 1: Patient Consulte son Dossier
```
1. POST /auth/login
   └── Obtient token
2. GET /patient/profile
   └── Voir son profil
3. GET /medical-dossier/{patientId}/summary
   └── Voir dossier médical
4. GET /medical-dossier/{patientId}/consultations?page=1&limit=10
   └── Voir consultations
```

### Scénario 2: Médecin Crée une Consultation
```
1. POST /auth/login (avec rôle: medecin)
   └── Obtient token
2. POST /doctor/search-patients
   └── Cherche le patient
3. POST /consultations
   └── Crée une consultation
4. POST /prescriptions
   └── Ajoute une ordonnance
5. POST /exams/prescribe
   └── Prescrit un examen
```

### Scénario 3: Laboratoire Enregistre Résultats
```
1. POST /auth/login (avec rôle: laboratoire)
   └── Obtient token
2. GET /laboratory/exams/pending
   └── Voir examens en attente
3. POST /laboratory/exams/{examId}/start
   └── Marquer comme en cours
4. POST /laboratory/exams/{examId}/record-results
   └── Enregistrer résultats
```

---

## ⚠️ Erreurs Courantes

### "Cannot connect to database"
```
Solution:
1. Vérifier que MySQL est démarré
2. Vérifier DB_HOST, DB_USER, DB_PASS dans config/database.php
3. Vérifier que la base esante_db existe
4. Exécuter setup-check.php
```

### "Token invalid or expired"
```
Solution:
1. Vérifier que le token est dans le header: Authorization: Bearer {token}
2. Token valide 24 heures seulement
3. Utiliser /auth/refresh-token pour obtenir un nouveau
```

### "404 - Not Found"
```
Solution:
1. Vérifier que mod_rewrite est activé dans Apache
2. Vérifier que .htaccess existe dans backend/public/
3. Vérifier l'URL: doit être /esante/backend/public/...
4. Consulter setup-check.php
```

### "CORS error from frontend"
```
Solution:
1. Vérifier FRONTEND_BASE_URL dans config/constants.php
2. Header Content-Type doit être: application/json
3. Préflight OPTIONS requests doivent être acceptées
```

---

## 🎓 Architecture Résumée

```
┌─────────────────────────────────────────────────────┐
│                    FLUTTER FRONTEND                 │
│              (Appelle les endpoints API)             │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP Requests
                       ▼
┌─────────────────────────────────────────────────────┐
│                    APACHE SERVER                    │
│                  .htaccess Rewriting                │
│            Rewriting /... to index.php              │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│                   index.php (Entry)                 │
│              Auto-loader + Router Init              │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│              AuthMiddleware (Sécurité)              │
│          Vérification JWT + Headers CORS            │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│            Router (Pattern Matching)                │
│     Extrait paramètres et appelle contrôleur        │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│     Controllers (AuthController, PatientController) │
│          Logic + Database Queries                   │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│              MySQL Database (25 tables)             │
│         Prepared Statements (Sécurisé)              │
└─────────────────────────────────────────────────────┘
```

---

## 📱 Tester depuis la Ligne de Commande

### Test Santé
```bash
curl http://localhost/esante/backend/public/health
```

### Test Inscription
```bash
curl -X POST http://localhost/esante/backend/public/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email":"test@test.com",
    "password":"TestPass123",
    "full_name":"Test User",
    "phone":"77123456",
    "role":"patient"
  }' | jq .
```

### Test Connexion
```bash
curl -X POST http://localhost/esante/backend/public/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email":"test@test.com",
    "password":"TestPass123"
  }' | jq .
```

### Test Profil (avec token)
```bash
TOKEN="votre_token_ici"

curl -H "Authorization: Bearer $TOKEN" \
  http://localhost/esante/backend/public/patient/profile | jq .
```

---

## 🔍 Débogage

### Voir les Logs d'Erreur
```bash
# Afficher les 50 dernières erreurs
tail -50 esante/backend/logs/error.log

# Suivre les erreurs en temps réel
tail -f esante/backend/logs/error.log
```

### Vérifier l'Installation
```bash
# Naviguer vers la page de vérification
http://localhost/esante/backend/public/setup-check.php

# Chercher ✅ pour vérifier que c'est OK
```

### Bearer Token Vérification
```bash
curl -I http://localhost/esante/backend/public/patient/profile \
  -H "Authorization: Bearer invalid_token"

# Doit retourner 401 Unauthorized
```

---

## 💡 Tips & Tricks

### Générer un Token Valide
```bash
# Utilisez Postman ou exécutez:
curl -X POST http://localhost/esante/backend/public/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@esante.com","password":"password"}'

# Copier le token du champ "data.token"
```

### Parser une Réponse JSON
```bash
# Avec jq (à installer)
curl ... | jq .data

# Ou avec grep
curl ... | grep -o '"user_id":[0-9]*'
```

### Paginer les Résultats
```bash
# Page 2 avec 10 résultats par page
http://localhost/esante/backend/public/endpoints?page=2&limit=10
```

### Tester avec Insomnia (Alternative Postman)
```bash
1. Télécharger Insomnia
2. Créer un nouveau requête
3. Importer la collection: E-Sante-API-Collection.postman_collection.json
4. Tester les endpoints
```

---

## 🎯 Prochaines Étapes

1. **Lire la Documentation**:
   ```
   1. ACCOMPLISHMENT.md (vue d'ensemble)
   2. backend/INSTALLATION.md (installation)
   3. backend/API_ROUTES.md (endpoints détaillés)
   ```

2. **Configuration Personnalisée**:
   ```
   1. Modifier DATABASE settings dans config/database.php
   2. Modifier JWT secret dans config/constants.php
   3. Modifier FRONTEND_BASE_URL pour CORS
   ```

3. **Intégration Frontend**:
   ```
   1. Pointer vers http://localhost/esante/backend/public
   2. Implémenter /auth/login pour authentification
   3. Utiliser les tokens JWT pour les autres endpoints
   ```

4. **Déploiement**:
   ```
   1. Configurer HTTPS/SSL
   2. Mettre à jour les URLs de base
   3. Configurer les backups de base de données
   4. Activer le monitoring des logs
   ```

---

## 📞 Support Rapide

| Question | Réponse |
|----------|---------|
| **Où est l'API?** | http://localhost/esante/backend/public |
| **Comment s'authentifier?** | POST /auth/login + Bearer token |
| **Les routes?** | 50+ endpoints dans backend/API_ROUTES.md |
| **Tests?** | Postman Collection fournie |
| **Erreurs?** | Voir backend/logs/error.log |
| **Configuration?** | backend/config/constants.php |
| **Base de données?** | database.sql (25 tables) |

---

## ✅ Checklist Rapide

- [ ] Base de données importée (25 tables)
- [ ] setup-check.php passe tous les tests
- [ ] API /health répond
- [ ] Inscription fonctionne
- [ ] Connexion fonctionne
- [ ] Profil patient accessible
- [ ] Dossier médical visible
- [ ] Rendez-vous créable
- [ ] Postman tests OK
- [ ] Frontend intégré

---

**🎉 Vous êtes Prêt!**

L'API E-Santé est **complète et prête à l'emploi**. 

Commencez par lire **[ACCOMPLISHMENT.md](ACCOMPLISHMENT.md)** puis consultez **[backend/API_ROUTES.md](backend/API_ROUTES.md)** pour les détails techniques.

Bon développement! 🚀

---

**Version**: 1.0.0  
**Status**: ✅ Production Ready
