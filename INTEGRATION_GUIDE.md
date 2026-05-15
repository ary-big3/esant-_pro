# 🔗 Intégration Frontend-Backend E-Santé

**Date**: 15 Avril 2026  
**Status**: ✅ Intégration Complète

---

## 📋 Vue d'Ensemble

L'application Flutter E-Santé est maintenant intégrée avec le backend PHP. Tous les appels API passent par un service centralisé qui gère l'authentification JWT et la gestion des tokens.

---

## 🏗️ Architecture d'Intégration

```
┌─────────────────────────────────────────────────────┐
│        ÉCRANS FLUTTER (UI Widgets)                  │
│     LoginScreen, PatientScreen, etc.                │
└──────────────────────┬──────────────────────────────┘
                       │ Utilisent
                       ▼
┌─────────────────────────────────────────────────────┐
│        SERVICES (lib/services/)                     │
│  ├─ AuthService (ChangeNotifier)                    │
│  ├─ ApiService (HTTP centralisé)                    │
│  ├─ TokenStorageService (Persistance)               │
│  └─ PatientService (Métier patient)                 │
└──────────────────────┬──────────────────────────────┘
                       │ Appellent
                       ▼
┌─────────────────────────────────────────────────────┐
│        API BACKEND PHP (HTTP)                       │
│  http://localhost/esante/backend/public             │
│  ├─ /auth/login                                     │
│  ├─ /auth/register                                  │
│  ├─ /patient/profile                                │
│  ├─ /medical-dossier/{id}/summary                   │
│  └─ ... 50+ autres endpoints                        │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│        BASE DE DONNÉES MySQL (esante_db)            │
│  ┌─────────────────────────────────────────────┐   │
│  │ 25 tables:                                  │   │
│  │ - users, patients, doctors, nurses          │   │
│  │ - consultations, appointments, exams        │   │
│  │ - prescriptions, vital_signs, etc.          │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

---

## 📦 Services Créés

### 1. `ApiService` (api_service.dart)
Service HTTP centralisé pour tous les appels API.

**Utilisation**:
```dart
final ApiService apiService = ApiService();

// GET request
final response = await apiService.get('/patient/profile', requireAuth: true);

// POST request
final response = await apiService.post(
  '/auth/login',
  body: {'email': 'user@test.com', 'password': 'password'},
  requireAuth: false,
);

// PUT request
final response = await apiService.put(
  '/patient/profile',
  body: {'phone': '77123456'},
  requireAuth: true,
);
```

**Features**:
- ✅ Gestion automatique des headers
- ✅ Token JWT automatique (Bearer)
- ✅ Gestion des erreurs standard
- ✅ Timeout configurable (30s)
- ✅ Logging en debug

---

### 2. `AuthService` (auth_service.dart)
Service d'authentification avec ChangeNotifier pour réactivité UI.

**Utilisation**:
```dart
// Dans main.dart avec Provider
ChangeNotifierProvider(
  create: (_) => AuthService(),
  child: const ESanteApp(),
)

// Dans les widgets
final authService = Provider.of<AuthService>(context);

// Inscription
try {
  await authService.register(
    email: 'user@test.com',
    password: 'SecurePass123',
    fullName: 'Nom Complet',
    phone: '77123456',
    role: 'patient', // ou medecin, infirmiere, etc.
  );
} catch (e) {
  print('Erreur: ${authService.errorMessage}');
}

// Connexion
try {
  await authService.login(
    email: 'user@test.com',
    password: 'password',
  );
  if (authService.isAuthenticated) {
    // Naviguer vers la page d'accueil
  }
} catch (e) {
  print('Erreur: ${authService.errorMessage}');
}

// Déconnexion
await authService.logout();

// Vérifier l'état
if (authService.isAuthenticated) {
  print('Utilisateur: ${authService.currentUser?.fullName}');
}
```

**Properties**:
- `currentUser` - UserModel actuellement connecté
- `currentToken` - Token JWT (null si non connecté)
- `isAuthenticated` - Boolean d'authentification
- `isLoading` - Pendant une requête API
- `errorMessage` - Message d'erreur s'il y en a

---

### 3. `TokenStorageService` (token_storage_service.dart)
Service de persistance sécurisée des données utilisateur.

**Utilisation**:
```dart
final tokenStorage = TokenStorageService();

// Initialiser
await tokenStorage.initialize();

// Sauvegarder le token
await tokenStorage.saveToken(jwtToken);

// Récupérer le token
final token = await tokenStorage.getToken();

// Vérifier si connecté
final isLogged = await tokenStorage.isLoggedIn();

// Déconnexion totale
await tokenStorage.clearAll();
```

**Features**:
- ✅ Stockage SharedPreferences
- ✅ Gestion des tokens JWT
- ✅ Persistance des données utilisateur
- ✅ Vérification d'expiration
- ✅ Nettoyage sécurisé

---

### 4. `PatientService` (patient_service.dart) - MIS À JOUR
Service métier pour les patients connectés à l'API.

**Utilisation**:
```dart
// Récupérer mon profil
final profile = await PatientService.getMyProfile();

// Récupérer le profil d'un patient
final patientProfile = await PatientService.getPatientProfile(patientId);

// Mettre à jour mon profil
final updated = await PatientService.updateMyProfile({
  'phone': '+221771234567',
});

// Récupérer le dossier médical
final dossier = await PatientService.getMedicalDossier(patientId);

// Récupérer les consultations
final consultations = await PatientService.getPatientConsultations(
  patientId,
  page: 1,
  limit: 10,
);

// Récupérer les examens
final exams = await PatientService.getPatientExams(patientId);

// Récupérer les vaccinations
final vaccinations = await PatientService.getPatientVaccinations(patientId);

// Mettre à jour les allergies
await PatientService.updatePatientAllergies(patientId, ['Pénicilline']);
```

---

## 🔑 Configuration

### URL de Base
```dart
// Dans ApiService
static const String baseUrl = 'http://localhost/esante/backend/public';
```

**Pour le déploiement en production**, modifier en:
```dart
static const String baseUrl = 'https://api.hopital.gov.sn/esante/backend/public';
```

### Dépendances Ajoutées
```yaml
dependencies:
  http: ^1.1.0                    # Requêtes HTTP
  shared_preferences: ^2.2.2      # Stockage local
  flutter_secure_storage: ^9.0.0  # Stockage sécurisé (optionnel)
```

---

## 🔄 Flux d'Authentification

### 1. Inscription
```
LoginScreen → AuthService.register()
    ↓
POST /auth/register
    ↓
Serveur crée user + patient profile
    ↓
Retourne token JWT
    ↓
TokenStorage.saveToken(token)
    ↓
isAuthenticated = true
    ↓
Redirection vers HomeScreen
```

### 2. Connexion
```
LoginScreen → AuthService.login()
    ↓
POST /auth/login
    ↓
Serveur vérifie password
    ↓
Retourne token JWT
    ↓
TokenStorage.saveToken(token)
    ↓
isAuthenticated = true
    ↓
Redirection selon rôle
```

### 3. Requête Authentifiée
```
Widget → PatientService.getMyProfile()
    ↓
ApiService.get('/patient/profile', requireAuth: true)
    ↓
Ajoute header: Authorization: Bearer {token}
    ↓
POST http://localhost/esante/backend/public/patient/profile
    ↓
Serveur vérifie token
    ↓
Retourne data + {success: true}
    ↓
Afficher résultats
```

### 4. Déconnexion
```
Widget → AuthService.logout()
    ↓
TokenStorage.clearAll()
    ↓
isAuthenticated = false
    ↓
ApiService.clearToken()
    ↓
Redirection vers LoginScreen
```

---

## 📱 Points d'Accès API

### Authentification (Sans Token)
```
POST /auth/register                # Inscription
POST /auth/login                   # Connexion
GET /auth/verify-token             # Vérifier token
POST /auth/refresh-token           # Rafraîchir token
GET /health                        # Vérifier santé de l'API
```

### Patient (Avec Token)
```
GET /patient/profile               # Mon profil
PUT /patient/profile               # Mettre à jour mon profil
GET /patient/{id}/profile          # Profil d'un patient
GET /patient/children              # Mes enfants (parent)
POST /patient/switch-to-child/{id} # Basculer sur enfant
```

### Dossier Médical (Avec Token)
```
GET /medical-dossier/{id}/summary
GET /medical-dossier/{id}/consultations
GET /medical-dossier/{id}/exams
GET /medical-dossier/{id}/vaccinations
GET /medical-dossier/{id}/documents
PUT /medical-dossier/medical-history
```

### Rendez-vous (Avec Token)
```
POST /appointments
GET /appointments/patient
GET /appointments/doctor/{id}
PUT /appointments/{id}/status
```

### Mandecin (Avec Token)
```
GET /doctor/profile
POST /doctor/search-patients
GET /doctor/statistics
GET /doctor/specialities
```

**Pour tous les endpoints**: Consulter [backend/API_ROUTES.md](../backend/API_ROUTES.md)

---

## ✅ Checklist Intégration

- [ ] **Backend PHP démarré**
  - [ ] MySQL running (esante_db importée)
  - [ ] Apache avec mod_rewrite activé
  - [ ] http://localhost/esante/backend/public/health répond

- [ ] **Frontend Flutter configuté**
  - [ ] Dépendances installées (`flutter pub get`)
  - [ ] pubspec.yaml avec `http` et `shared_preferences`
  - [ ] URL de base correctement configurée

- [ ] **Tests Basiques**
  - [ ] Inscription fonctionne
  - [ ] Connexion fonctionne
  - [ ] Token sauvegardé localement
  - [ ] Récupération profil avec token
  - [ ] Déconnexion efface le token

- [ ] **Gestion Erreurs**
  - [ ] Token expiré → Redirect vers login
  - [ ] 401 Unauthorized → Logout
  - [ ] Pas de réseau → Afficher message
  - [ ] 500 Erreur serveur → Retry option

- [ ] **UI Réactive**
  - [ ] Loading spinner pendant requête
  - [ ] Messages d'erreur clairs
  - [ ] Désactiver boutons pendant requête
  - [ ] Afficher données actualisées

---

## 🧪 Tester l'Intégration

### 1. Test d'Inscription
```dart
// Dans LoginScreen ou widget test
final authService = Provider.of<AuthService>(context, listen: false);

try {
  await authService.register(
    email: 'test@esante.com',
    password: 'TestPass123',
    fullName: 'Test User',
    phone: '77123456',
    role: 'patient',
  );
  
  if (authService.isAuthenticated) {
    print('✅ Inscription réussie');
    // Naviguer vers home
  }
} catch (e) {
  print('❌ Erreur: ${authService.errorMessage}');
}
```

### 2. Test de Connexion
```dart
final authService = Provider.of<AuthService>(context, listen: false);

try {
  await authService.login(
    email: 'test@esante.com',
    password: 'TestPass123',
  );
  
  if (authService.isAuthenticated) {
    print('✅ Connexion réussie');
    print('Utilisateur: ${authService.currentUser?.fullName}');
  }
} catch (e) {
  print('❌ Erreur: ${authService.errorMessage}');
}
```

### 3. Test Requête Authentifiée
```dart
try {
  final profile = await PatientService.getMyProfile();
  print('✅ Profil récupéré: ${profile.email}');
} catch (e) {
  print('❌ Erreur: $e');
}
```

### 4. Test Offline
```dart
// Arrêter le serveur et tenter:
try {
  final profile = await PatientService.getMyProfile();
} catch (e) {
  // Doit afficher: "Erreur: Connection refused"
  print(e);
}
```

---

## 🐛 Dépannage

### "Connection refused"
```
Problème: Le backend PHP ne répond pas
Solution:
1. Vérifier que MySQL est démarré
2. Vérifier que Apache est démarré
3. Naviguer vers http://localhost/esante/backend/public/health
4. Vérifier les logs PHP: /backend/logs/error.log
```

###  "Unauthorized (401)"
```
Problème: Token invalide ou expiré
Solution:
1. Vérifier que le token est sauvegardé (TokenStorageService)
2. Vérifier que le header est correct: Authorization: Bearer {token}
3. Rafraîchir le token: AuthService.refreshToken()
4. Déconnecter et reconnecter
```

### "CORS error"
```
Problème: Requête bloquée par CORS
Solution:
1. Vérifier que FRONTEND_BASE_URL est correct dans le backend
2. Vérifier que Content-Type: application/json est défini
3. Les requêtes OPTIONS doivent retourner 200
4. Voir middleware/AuthMiddleware.php du backend
```

### "Token Expiration"
```
Problème: Token expiré après 24h
Solution:
1. Implémenter le refresh automatique:
   if (await authService.refreshToken()) {
     // Continuer
   } else {
     // Logout
   }
2. Ou rediriger vers login pour reconnecter
```

---

## 📚 Ressources

| Document | Description |
|----------|-------------|
| [api_service.dart](lib/services/api_service.dart) | Service HTTP avec gestion d'erreurs |
| [auth_service.dart](lib/services/auth_service.dart) | Authentification et gestion tokens |
| [token_storage_service.dart](lib/services/token_storage_service.dart) | Persistance sécurisée |
| [../backend/API_ROUTES.md](../backend/API_ROUTES.md) | Tous les 50+ endpoints |
| [../backend/INSTALLATION.md](../backend/INSTALLATION.md) | Installation backend |
| [../QUICKSTART.md](../QUICKSTART.md) | Démarrage rapide |

---

## 📞 Support

### Questions Fréquentes

**Q: Comment changer l'URL de base de l'API?**  
R: Modifier `ApiService.baseUrl` dans `api_service.dart`

**Q: Comment ajouter un nouvel endpoint?**  
R: 
1. L'endpoint doit être dans l'API backend (voir API_ROUTES.md)
2. Utiliser `_apiService.get()`, `.post()`, `.put()` dans le service
3. Gérer les erreurs avec try-catch

**Q: Comment tester sans connexion Internet?**  
R: Implémenter un `MockApiService` pour les tests

**Q: Comment rafraîchir automatiquement le token?**  
R: Implémenter un interceptor HTTP ou vérifier l'expiration avant chaque requête

**Q: Puis-je utiliser flutter_secure_storage pour les tokens?**  
R: Oui, modifier `TokenStorageService` pour utiliser `flutter_secure_storage` au lieu de `shared_preferences` pour plus de sécurité

---

**✅ Intégration Complète et Prête pour le Développement!**

Frontend Flutter ↔️ Backend PHP = 🚀 Système de Santé Complet!
