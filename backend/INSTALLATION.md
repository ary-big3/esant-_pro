# Configuration d'installation du Backend E-Santé

## Prérequis

- **PHP**: 7.2 ou supérieur
- **MySQL**: 5.7 ou supérieur (ou MariaDB 10.2+)
- **Apache**: Avec mod_rewrite activé
- **XAMPP**: Recommandé pour le développement

## Installation

### 1. Cloner ou télécharger le projet

```bash
cd /xampp/htdocs/esante
```

### 2. Importer la base de données

1. Ouvrez phpMyAdmin: `http://localhost/phpmyadmin`
2. Créez une nouvelle base de données ou sélectionnez `esante_db`
3. Importez le fichier `database.sql` depuis la racine du projet

### 3. Configurer les paramètres de connexion

Éditez `backend/config/database.php` et mettez à jour:

```php
define('DB_HOST', 'localhost');
define('DB_PORT', 3306);
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'esante_db');
```

### 4. Vérifier l'installation

Accédez à: `http://localhost/esante/backend/public/setup-check.php`

Vous devriez voir:
- Version PHP: OK
- Extension MySQLi: OK
- Base de données: Connectée
- Toutes les tables: Présentes

### 5. Tester l'API

Pour vérifier que l'API fonctionne:

```bash
curl http://localhost/esante/backend/public/health
```

Réponse attendue:
```json
{
    "success": true,
    "message": "API saine",
    "data": {
        "status": "API en ligne",
        "timestamp": "2026-04-15 10:30:45"
    }
}
```

## Structure des dossiers

```
backend/
├── config/              # Configuration (DB, constantes)
├── controllers/         # Logique métier
│   ├── AuthController.php
│   ├── PatientController.php
│   ├── DoctorController.php
│   ├── NurseController.php
│   ├── LaboratoryController.php
│   ├── AppointmentController.php
│   ├── PrescriptionController.php
│   ├── ExamController.php
│   ├── ConsultationController.php
│   └── MedicalDossierController.php
├── middleware/          # Middlewares (authentification, etc)
├── utils/               # Utilitaires (JWT, Response, Validator)
├── routes/              # Routeur API
├── public/              # Point d'entrée (.htaccess pour rewriting)
└── logs/                # Fichiers logs (créés automatiquement)
```

## Connexions de test

Utilisez les compte de test créés lors de l'import de `database.sql`:

### Patient
- **Email**: test_patient@esante.com
- **Mot de passe**: hashed_password_patient
**Remarque**: Les mots de passe dans la BD sont hashés. Utilisez `/auth/login` avec les identifiants

### Médecin
- **Email**: test_doctor@esante.com
- **Mot de passe**: hashed_password_doctor

### Admin
- **Email**: admin@esante.com
- **Mot de passe**: hashed_password_admin

## Endpoints principaux

### Authentification
- `POST /auth/register` - Inscription
- `POST /auth/login` - Connexion
- `POST /auth/refresh-token` - Rafraîchir le token
- `GET /auth/verify-token` - Vérifier le token

### Patient
- `GET /patient/profile` - Voir son profil
- `PUT /patient/profile` - Modifier son profil
- `GET /patient/children` - Voir ses enfants
- `GET /patient/nfc-card` - Obtenir sa carte NFC
- `POST /patient/switch-to-child/{childPatientId}` - Basculer vers compte enfant
- `POST /patient/return-to-parent` - Retourner au compte parent

### Dossier Médical
- `GET /medical-dossier/{patientId}/summary` - Résumé du dossier
- `PUT /medical-dossier/medical-history` - Mettre à jour antécédents
- `GET /medical-dossier/{patientId}/consultations` - Consultations
- `GET /medical-dossier/{patientId}/exams` - Examens
- `GET /medical-dossier/{patientId}/vaccinations` - Vaccinations
- `GET /medical-dossier/{patientId}/documents` - Documents médicaux

### Rendez-vous
- `POST /appointments` - Créer un RDV
- `GET /appointments/patient` - Mes RDV
- `GET /appointments/doctor/{doctorId}` - RDV du médecin
- `PUT /appointments/{appointmentId}/status` - Changer le statut

### Ordonnances
- `POST /prescriptions` - Créer une ordonnance
- `GET /prescriptions/patient` - Mes ordonnances
- `GET /prescriptions/{prescriptionId}` - Détails ordonnance
- `PUT /prescriptions/{prescriptionId}/status` - Changer le statut

### Examens
- `POST /exams/prescribe` - Prescrire un examen
- `GET /exams/patient` - Mes examens
- `GET /exams/{examId}` - Détails examen
- `POST /exams/{examId}/record-results` - Enregistrer résultats

### Consultations
- `POST /consultations` - Créer une consultation
- `GET /consultations/patient` - Mes consultations
- `GET /consultations/{consultationId}` - Détails consultation
- `PUT /consultations/{consultationId}` - Mettre à jour

### Médecin
- `GET /doctor/profile` - Mon profil
- `POST /doctor/search-patients` - Rechercher patients
- `GET /doctor/statistics` - Mes statistiques
- `GET /doctor/specialities` - Mes spécialités

### Infirmière
- `GET /nurse/profile` - Mon profil
- `POST /nurse/vitals` - Enregistrer signes vitaux
- `GET /nurse/vitals/{patientId}` - Signes vitaux d'un patient

### Laboratoire
- `GET /laboratory/profile` - Mon profil
- `GET /laboratory/exams/pending` - Examens en attente
- `POST /laboratory/exams/{examId}/start` - Marquer comme en cours
- `POST /laboratory/exams/{examId}/record-results` - Enregistrer résultats
- `GET /laboratory/exams/completed` - Examens complétés

## Authentification JWT

Tous les endpoints (sauf `/auth/register` et `/auth/login`) nécessitent un header:

```
Authorization: Bearer <token_jwt>
```

Le token JWT:
- Valide pendant 24 heures
- Contient: user_id, email, role, full_name, iat, exp
- À rafraîchir avec `/auth/refresh-token` quand expiré

## Formats de réponse

### Succès
```json
{
    "success": true,
    "message": "Message de succès",
    "data": { /* données */ },
    "timestamp": "2026-04-15 10:30:45"
}
```

### Pagination
```json
{
    "success": true,
    "message": "Message",
    "data": [ /* array */ ],
    "pagination": {
        "total": 100,
        "page": 1,
        "pageSize": 20,
        "totalPages": 5
    },
    "timestamp": "2026-04-15 10:30:45"
}
```

### Erreur
```json
{
    "success": false,
    "message": "Message d'erreur",
    "statusCode": 400,
    "timestamp": "2026-04-15 10:30:45",
    "errors": { /* détails */ }
}
```

## Codes de statut HTTP

- `200 OK` - Succès
- `201 Created` - Créé avec succès
- `400 Bad Request` - Données invalides
- `401 Unauthorized` - Non autorisé (token invalide)
- `403 Forbidden` - Accès interdit
- `404 Not Found` - Ressource non trouvée
- `409 Conflict` - Conflit (ex: email déjà utilisé)
- `500 Internal Server Error` - Erreur serveur

## Dépannage

### Erreur de connexion à la base de données

1. Vérifiez que MySQL/XAMPP est démarré
2. Vérifiez les identifiants dans `config/database.php`
3. Vérifiez que la base `esante_db` existe
4. Exécutez `setup-check.php` pour diagnostiquer

### Erreur 404 sur les routes

1. Activez `mod_rewrite` dans Apache:
   ```bash
   # Windows: a2enmod rewrite
   ```
2. Vérifiez que `.htaccess` existe dans `backend/public/`
3. Redémarrez Apache

### CORS error depuis le frontend

1. Vérifiez `FRONTEND_BASE_URL` dans `config/constants.php`
2. Les headers CORS sont définis dans `AuthMiddleware.php`
3. Assurez-vous que le backend accepte les requêtes du frontend

### Token JWT invalide

1. Le token n'est valide que 24 heures
2. Utilisez `/auth/refresh-token` pour obtenir un nouveau
3. Vérifiez que le header `Authorization` est correctement formaté

## Sécurité

- Les mots de passe sont hashés avec `password_hash()` (BCRYPT)
- Les tokens JWT sont signés avec `HS256`
- Les données sensibles sont loggées de manière sécurisée
- Les headers de sécurité sont définis dans `AuthMiddleware`
- Les requêtes SQL utilisent des requêtes préparées

## Performance

- Les requêtes sont paginées (par défaut 20 résultats)
- Les index sur les colonnes frequently searched
- Cache des données: À implémenter
- Compression GZIP: À configurer dans Apache

## Prochaines étapes

1. Implémenter le caching (Redis)
2. Ajouter les logs détaillés
3. Implémenter les tests unitaires
4. Ajouter la documentation Swagger complète
5. Optimiser les performances des requêtes
