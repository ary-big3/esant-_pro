# E-Santé Backend API

## Configuration

Assurez-vous que vos informations de base de données dans `config/database.php` sont correctes :

- **DB_HOST**: localhost
- **DB_USER**: root
- **DB_PASS**: (vide par défaut pour XAMPP)
- **DB_NAME**: esante_db
- **DB_PORT**: 3306

## Installation de la base de données

1. Ouvrez phpMyAdmin (http://localhost/phpmyadmin)
2. Importez le fichier `database.sql` fourni dans la racine du projet
3. Vérifiez que la base de données `esante_db` est créée

## Structure de l'API

```
backend/
├── config/           # Configuration et constantes
├── controllers/      # Contrôleurs métier
├── middleware/       # Middleware (authentification, sécurité)
├── models/          # Modèles de données (optionnel)
├── utils/           # Utilitaires (JWT, Response, Validator)
├── routes/          # Gestionnaire de routage
├── public/          # Point d'entrée principal
└── logs/            # Fichiers logs (créé automatiquement)
```

## Points d'accès API

**Base URL**: `http://localhost/esante/backend/public`

### Authentification

#### Inscription
```
POST /auth/register
```

**Payload**:
```json
{
    "email": "user@example.com",
    "password": "password123",
    "full_name": "Amadou Diallo",
    "phone": "+221771234567",
    "role": "patient",
    "first_name": "Amadou",
    "last_name": "Diallo",
    "date_of_birth": "1990-01-15",
    "gender": "M"
}
```

#### Connexion
```
POST /auth/login
```

**Payload**:
```json
{
    "email": "user@example.com",
    "password": "password123"
}
```

#### Rafraîchir le token
```
POST /auth/refresh-token
Authorization: Bearer <token>
```

#### Vérifier le token
```
GET /auth/verify-token
Authorization: Bearer <token>
```

### Patient

#### Obtenir son profil
```
GET /patient/profile
Authorization: Bearer <token>
```

#### Mettre à jour son profil
```
PUT /patient/profile
Authorization: Bearer <token>
Content-Type: application/json
```

#### Obtenir ses enfants
```
GET /patient/children
Authorization: Bearer <token>
```

#### Obtenir sa carte NFC
```
GET /patient/nfc-card
Authorization: Bearer <token>
```

#### Basculer vers un compte enfant
```
POST /patient/switch-to-child/{childPatientId}
Authorization: Bearer <token>
```

#### Retourner au compte parent
```
POST /patient/return-to-parent
Authorization: Bearer <token>
```

### Dossier Médical

#### Obtenir le résumé du dossier
```
GET /medical-dossier/{patientId}/summary
Authorization: Bearer <token>
```

#### Mettre à jour les antécédents médicaux
```
PUT /medical-dossier/medical-history
Authorization: Bearer <token>
Content-Type: application/json
```

**Payload**:
```json
{
    "patient_id": 1,
    "medical_conditions": "Hypertension, Diabète",
    "family_history": "Père: Hypertension",
    "blood_group": "A+",
    "chronic_diseases": ["Diabète Type 2", "Hypertension"],
    "known_allergies": ["Pénicilline", "Arachides"]
}
```

#### Obtenir les consultations
```
GET /medical-dossier/{patientId}/consultations?page=1&limit=20
Authorization: Bearer <token>
```

#### Obtenir les examens
```
GET /medical-dossier/{patientId}/exams?page=1&limit=20
Authorization: Bearer <token>
```

#### Obtenir les vaccinations
```
GET /medical-dossier/{patientId}/vaccinations?page=1&limit=20
Authorization: Bearer <token>
```

#### Obtenir les documents
```
GET /medical-dossier/{patientId}/documents?page=1&limit=20
Authorization: Bearer <token>
```

### Rendez-vous

#### Créer un rendez-vous
```
POST /appointments
Authorization: Bearer <token>
Content-Type: application/json
```

**Payload**:
```json
{
    "appointment_date": "2026-04-20 14:30:00",
    "doctor_id": 1,
    "patient_id": 1,
    "speciality_id": 1,
    "hospital_id": 1,
    "appointment_type": "consultation",
    "reason_for_appointment": "Consultation générale"
}
```

#### Obtenir les rendez-vous du patient
```
GET /appointments/patient?page=1&limit=20
Authorization: Bearer <token>
```

#### Obtenir les rendez-vous du médecin
```
GET /appointments/doctor/{doctorId}?page=1&limit=20
Authorization: Bearer <token>
```

#### Mettre à jour le statut
```
PUT /appointments/{appointmentId}/status
Authorization: Bearer <token>
Content-Type: application/json
```

**Payload**:
```json
{
    "status": "confirmed"
}
```

### Ordonnances

#### Créer une ordonnance
```
POST /prescriptions
Authorization: Bearer <token>
Content-Type: application/json
```

**Payload**:
```json
{
    "patient_id": 1,
    "consultation_id": 1,
    "medications": [
        {
            "medication_name": "Aspirine",
            "dosage": "500",
            "dosage_unit": "mg",
            "frequency": "3x par jour",
            "duration": "10 jours",
            "route_of_administration": "oral",
            "special_instructions": "Avec repas"
        }
    ],
    "notes": "Prendre avec de la nourriture",
    "expiry_date": "2026-07-14"
}
```

#### Obtenir les ordonnances
```
GET /prescriptions/patient?page=1&limit=20
Authorization: Bearer <token>
```

#### Obtenir une ordonnance
```
GET /prescriptions/{prescriptionId}
Authorization: Bearer <token>
```

#### Mettre à jour le statut
```
PUT /prescriptions/{prescriptionId}/status
Authorization: Bearer <token>
Content-Type: application/json
```

**Payload**:
```json
{
    "status": "completed"
}
```

### Examens

#### Prescrire un examen
```
POST /exams/prescribe
Authorization: Bearer <token>
Content-Type: application/json
```

**Payload**:
```json
{
    "patient_id": 1,
    "speciality_id": 1,
    "exam_type": "Analyse sanguine",
    "urgency_level": "normal",
    "observations": "Bilan de santé général"
}
```

#### Obtenir les examens du patient
```
GET /exams/patient?page=1&limit=20
Authorization: Bearer <token>
```

#### Obtenir un examen
```
GET /exams/{examId}
Authorization: Bearer <token>
```

#### Enregistrer les résultats
```
POST /exams/{examId}/record-results
Authorization: Bearer <token>
Content-Type: application/json
```

**Payload**:
```json
{
    "result_interpretation": "normal",
    "results": [
        {
            "test_name": "Hémoglobine",
            "measured_value": 14.5,
            "unit": "g/dL",
            "reference_min": 13.5,
            "reference_max": 17.5
        }
    ]
}
```

### Consultations

#### Créer une consultation
```
POST /consultations
Authorization: Bearer <token>
Content-Type: application/json
```

**Payload**:
```json
{
    "patient_id": 1,
    "consultation_date": "2026-04-20 14:30:00",
    "consultation_type": "en_personne",
    "reason_for_visit": "Suivi médical",
    "chief_complaint": "Malaise général",
    "diagnosis": "Infection respiratoire",
    "treatment_plan": "Repos et médicaments"
}
```

#### Obtenir les consultations
```
GET /consultations/patient?page=1&limit=20
Authorization: Bearer <token>
```

#### Obtenir une consultation
```
GET /consultations/{consultationId}
Authorization: Bearer <token>
```

#### Mettre à jour une consultation
```
PUT /consultations/{consultationId}
Authorization: Bearer <token>
Content-Type: application/json
```

### Médecin

#### Obtenir son profil
```
GET /doctor/profile
Authorization: Bearer <token>
```

#### Rechercher des patients
```
POST /doctor/search-patients
Authorization: Bearer <token>
Content-Type: application/json
```

**Payload**:
```json
{
    "search": "Amadou"
}
```

#### Obtenir les statistiques
```
GET /doctor/statistics
Authorization: Bearer <token>
```

#### Obtenir les spécialités
```
GET /doctor/specialities
Authorization: Bearer <token>
```

## Headers obligatoires

Tous les endpoints authentifiés nécessitent le header:

```
Authorization: Bearer <your_jwt_token>
```

## Réponse en cas de succès

```json
{
    "success": true,
    "message": "Message de succès",
    "data": { /* données */ },
    "timestamp": "2026-04-15 10:30:45"
}
```

## Réponse en cas d'erreur

```json
{
    "success": false,
    "message": "Message d'erreur",
    "statusCode": 400,
    "timestamp": "2026-04-15 10:30:45",
    "errors": { /* détail des erreurs */ }
}
```

## Codes HTTP

- `200`: Succès
- `201`: Créé
- `400`: Mauvaise requête
- `401`: Non autorisé
- `403`: Interdit
- `404`: Non trouvé
- `409`: Conflit
- `500`: Erreur serveur

## Dépannage

### Erreur de connexion à la base de données

1. Vérifiez que MySQL/XAMPP est démarré
2. Vérifiez les identifiants de la base de données dans `config/database.php`
3. Vérifiez que la base de données `esante_db` existe
4. Vérifiez les permissions de fichiers

### JWT invalide

Le token JWT est valide pendant 24 heures (86400 secondes).
Utilisez l'endpoint `/auth/refresh-token` pour obtenir un nouveau token.

### CORS error

Les headers CORS sont définis dans le middleware `AuthMiddleware`.
Assurez-vous que `FRONTEND_BASE_URL` dans `config/constants.php` est correct.
