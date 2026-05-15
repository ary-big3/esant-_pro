# 📋 Documentation Complète des Routes API E-Santé

**Base URL**: `http://localhost/esante/backend/public`

**Version**: 1.0.0

**Authentification**: JWT Bearer Token (sauf endpoints publics marqués)

---

## 🔐 Routes Publiques (Sans Authentification)

### 1. Vérifier la Santé de l'API
```
GET /health
```

**Description**: Vérifie que l'API est en ligne

**Réponse**:
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

---

## 🔑 Routes Authentification

### 1. Inscription d'un Nouvel Utilisateur
```
POST /auth/register
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@esante.com",
  "password": "SecurePassword123",
  "full_name": "John Doe",
  "phone": "77123456",
  "role": "patient"
}
```

**Rôles disponibles**: `patient`, `medecin`, `infirmiere`, `laboratoire`, `admin`

**Réponse** (201):
```json
{
  "success": true,
  "message": "Utilisateur créé et token généré",
  "data": {
    "user_id": 1,
    "email": "user@esante.com",
    "full_name": "John Doe",
    "role": "patient",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### 2. Connexion
```
POST /auth/login
Content-Type: application/json
```

**Body**:
```json
{
  "email": "user@esante.com",
  "password": "SecurePassword123"
}
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Connexion réussie",
  "data": {
    "user_id": 1,
    "email": "user@esante.com",
    "full_name": "John Doe",
    "role": "patient",
    "patient_id": 1,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### 3. Vérifier la Validité du Token
```
GET /auth/verify-token
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Token valide",
  "data": {
    "user_id": 1,
    "email": "user@esante.com",
    "role": "patient",
    "is_valid": true
  }
}
```

---

### 4. Rafraîchir le Token
```
POST /auth/refresh-token
Authorization: Bearer <old_token>
Content-Type: application/json
```

**Body**:
```json
{}
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Token rafraîchi",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

## 👤 Routes Patient

### 1. Obtenir Mon Profil
```
GET /patient/profile
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Profil patient récupéré",
  "data": {
    "patient_id": 1,
    "first_name": "John",
    "last_name": "Doe",
    "date_of_birth": "1990-01-15",
    "gender": "M",
    "blood_group": "O+",
    "phone": "77123456",
    "email": "john@esante.com"
  }
}
```

---

### 2. Mettre à Jour Mon Profil
```
PUT /patient/profile
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**:
```json
{
  "phone": "77654321",
  "email": "newemail@esante.com",
  "blood_group": "A+"
}
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Profil mis à jour"
}
```

---

### 3. Obtenir la Liste de Mes Enfants
```
GET /patient/children
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Enfants récupérés",
  "data": [
    {
      "patient_id": 2,
      "first_name": "Jane",
      "last_name": "Doe",
      "date_of_birth": "2010-05-20",
      "gender": "F"
    }
  ]
}
```

---

### 4. Obtenir la Carte NFC
```
GET /patient/nfc-card
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Informations NFC",
  "data": {
    "nfc_card_number": "PAT-00001",
    "patient_id": 1,
    "full_name": "John Doe"
  }
}
```

---

### 5. Basculer vers un Compte Enfant
```
POST /patient/switch-to-child/{childPatientId}
Authorization: Bearer <parent_token>
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Basculé vers le compte enfant",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "is_child_account": true,
    "parent_patient_id": 1
  }
}
```

---

### 6. Retourner au Compte Parent
```
POST /patient/return-to-parent
Authorization: Bearer <child_token>
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Retourné au compte parent",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "is_child_account": false
  }
}
```

---

## 📋 Routes Dossier Médical

### 1. Obtenir le Résumé du Dossier Médical
```
GET /medical-dossier/{patientId}/summary
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Dossier médical récupéré",
  "data": {
    "patient_id": 1,
    "blood_group": "O+",
    "medical_conditions": "Asthme léger",
    "family_history": "Diabète chez la mère",
    "chronic_diseases": ["Asthme"],
    "known_allergies": ["Pénicilline"],
    "last_consultation": "2026-03-10"
  }
}
```

---

### 2. Mettre à Jour les Antécédents Médicaux
```
PUT /medical-dossier/medical-history
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**:
```json
{
  "patient_id": 1,
  "medical_conditions": "Asthme léger, Hypertension",
  "family_history": "Diabète chez la mère",
  "blood_group": "O+",
  "chronic_diseases": ["Asthme", "Hypertension"],
  "known_allergies": ["Pénicilline"]
}
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Antécédents médicaux mis à jour"
}
```

---

### 3. Obtenir les Consultations
```
GET /medical-dossier/{patientId}/consultations?page=1&limit=10
Authorization: Bearer <token>
```

**Paramètres de pagination**:
- `page`: Numéro de page (défaut: 1)
- `limit`: Nombre de résultats par page (défaut: 20, max: 100)

**Réponse** (200):
```json
{
  "success": true,
  "data": [
    {
      "consultation_id": 1,
      "doctor_id": 1,
      "doctor_name": "Dr. Smith",
      "consultation_date": "2026-03-10 10:30:00",
      "diagnosis": "Asthme",
      "treatment_plan": "Inhalateur quotidien"
    }
  ],
  "pagination": {
    "total": 5,
    "page": 1,
    "pageSize": 10,
    "totalPages": 1
  }
}
```

---

### 4. Obtenir les Examens
```
GET /medical-dossier/{patientId}/exams?page=1&limit=10
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "data": [
    {
      "exam_id": 1,
      "exam_type": "Prise de sang",
      "exam_date": "2026-03-10",
      "exam_status": "completed",
      "result_interpretation": "normal"
    }
  ],
  "pagination": { /* ... */ }
}
```

---

### 5. Obtenir les Vaccinations
```
GET /medical-dossier/{patientId}/vaccinations?page=1&limit=10
Authorization: Bearer <token>
```

---

### 6. Obtenir les Documents Médicaux
```
GET /medical-dossier/{patientId}/documents?page=1&limit=10
Authorization: Bearer <token>
```

---

## 📅 Routes Rendez-vous

### 1. Créer un Rendez-vous
```
POST /appointments
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**:
```json
{
  "patient_id": 1,
  "doctor_id": 1,
  "appointment_date": "2026-05-15 10:00:00",
  "reason_for_appointment": "Consultation générale"
}
```

**Réponse** (201):
```json
{
  "success": true,
  "message": "Rendez-vous créé",
  "data": {
    "appointment_id": 1,
    "status": "pending"
  }
}
```

---

### 2. Obtenir Mes Rendez-vous (Patient)
```
GET /appointments/patient?page=1&limit=10
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "data": [
    {
      "appointment_id": 1,
      "doctor_id": 1,
      "doctor_name": "Dr. Smith",
      "appointment_date": "2026-05-15 10:00:00",
      "status": "confirmed",
      "reason_for_appointment": "Consultation générale"
    }
  ],
  "pagination": { /* ... */ }
}
```

---

### 3. Obtenir les Rendez-vous d'un Médecin
```
GET /appointments/doctor/{doctorId}?page=1&limit=10
Authorization: Bearer <token>
```

---

### 4. Changer le Statut d'un Rendez-vous
```
PUT /appointments/{appointmentId}/status
Authorization: Bearer <token>
Content-Type: application/json
```

**Statuts valides**: `confirmed`, `pending`, `completed`, `cancelled`, `no_show`

**Body**:
```json
{
  "appointment_status": "confirmed"
}
```

---

## 💊 Routes Ordonnances

### 1. Créer une Ordonnance
```
POST /prescriptions
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**:
```json
{
  "patient_id": 1,
  "doctor_id": 1,
  "consultation_id": 1,
  "medications": [
    {
      "medication_name": "Paracétamol",
      "dosage": "500mg",
      "frequency": "3x par jour",
      "duration_days": 7,
      "sequence_order": 1
    }
  ]
}
```

**Réponse** (201):
```json
{
  "success": true,
  "message": "Ordonnance créée",
  "data": {
    "prescription_id": 1,
    "prescription_number": "RX-1681380645"
  }
}
```

---

### 2. Obtenir Mes Ordonnances
```
GET /prescriptions/patient?page=1&limit=10
Authorization: Bearer <token>
```

---

### 3. Obtenir les Détails d'une Ordonnance
```
GET /prescriptions/{prescriptionId}
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "data": {
    "prescription_id": 1,
    "prescription_number": "RX-1681380645",
    "patient_id": 1,
    "doctor_id": 1,
    "status": "active",
    "issue_date": "2026-03-10",
    "expiry_date": "2026-04-10",
    "medications": [
      {
        "medication_name": "Paracétamol",
        "dosage": "500mg",
        "frequency": "3x par jour"
      }
    ]
  }
}
```

---

### 4. Changer le Statut d'une Ordonnance
```
PUT /prescriptions/{prescriptionId}/status
Authorization: Bearer <token>
Content-Type: application/json
```

**Statuts valides**: `active`, `expired`, `completed`, `cancelled`

**Body**:
```json
{
  "prescription_status": "completed"
}
```

---

## 🔬 Routes Examens

### 1. Prescrire un Examen
```
POST /exams/prescribe
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**:
```json
{
  "patient_id": 1,
  "doctor_id": 1,
  "exam_type": "Prise de sang",
  "speciality_id": 1,
  "urgency_level": "normal",
  "clinical_indication": "Bilan de santé"
}
```

**Niveaux d'urgence**: `normal`, `urgent`, `tres_urgent`

**Réponse** (201):
```json
{
  "success": true,
  "message": "Examen prescrit",
  "data": {
    "exam_id": 1,
    "exam_request_number": "EXM-1681380645"
  }
}
```

---

### 2. Obtenir Mes Examens
```
GET /exams/patient?page=1&limit=10
Authorization: Bearer <token>
```

---

### 3. Obtenir les Détails d'un Examen
```
GET /exams/{examId}
Authorization: Bearer <token>
```

---

### 4. Enregistrer les Résultats d'un Examen
```
POST /exams/{examId}/record-results
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**:
```json
{
  "results": [
    {
      "test_name": "Glucose",
      "measured_value": 105,
      "unit": "mg/dL",
      "reference_min": 70,
      "reference_max": 100,
      "interpretation": "Légèrement élevé"
    }
  ],
  "result_interpretation": "abnormal"
}
```

---

## 👨‍⚕️ Routes Médecin

### 1. Obtenir Mon Profil de Médecin
```
GET /doctor/profile
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "data": {
    "doctor_id": 1,
    "full_name": "Dr. Smith",
    "email": "doctor@esante.com",
    "phone": "77987654",
    "hospital_name": "Hôpital Central",
    "license_number": "LIC123456"
  }
}
```

---

### 2. Rechercher des Patients
```
POST /doctor/search-patients
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**:
```json
{
  "search_query": "John Doe"
}
```

**Réponse** (200):
```json
{
  "success": true,
  "data": [
    {
      "patient_id": 1,
      "first_name": "John",
      "last_name": "Doe",
      "phone": "77123456"
    }
  ]
}
```

---

### 3. Obtenir Mes Statistiques
```
GET /doctor/statistics
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "data": {
    "consultations_today": 3,
    "distinct_patients": 25,
    "active_prescriptions": 12,
    "urgent_exams": 2
  }
}
```

---

### 4. Obtenir Mes Spécialités
```
GET /doctor/specialities
Authorization: Bearer <token>
```

---

## 👩‍⚕️ Routes Infirmière

### 1. Obtenir Mon Profil d'Infirmière
```
GET /nurse/profile
Authorization: Bearer <token>
```

---

### 2. Enregistrer les Signes Vitaux
```
POST /nurse/vitals
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**:
```json
{
  "patient_id": 1,
  "temperature_celsius": 36.5,
  "systolic_pressure": 120,
  "diastolic_pressure": 80,
  "pulse_bpm": 72,
  "respiratory_rate": 16,
  "oxygen_saturation": 98.5,
  "weight_kg": 75,
  "height_cm": 180,
  "status": "normal",
  "notes": "Signes vitaux normaux"
}
```

---

### 3. Obtenir les Signes Vitaux d'un Patient
```
GET /nurse/vitals/{patientId}?page=1&limit=10
Authorization: Bearer <token>
```

---

## 🧪 Routes Laboratoire

### 1. Obtenir Mon Profil de Laboratoire
```
GET /laboratory/profile
Authorization: Bearer <token>
```

---

### 2. Obtenir les Examens en Attente
```
GET /laboratory/exams/pending?page=1&limit=10
Authorization: Bearer <token>
```

---

### 3. Marquer un Examen comme En Cours
```
POST /laboratory/exams/{examId}/start
Authorization: Bearer <token>
```

---

### 4. Enregistrer les Résultats d'un Examen
```
POST /laboratory/exams/{examId}/record-results
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**: Même format que `/exams/{examId}/record-results`

---

### 5. Obtenir les Examens Complétés
```
GET /laboratory/exams/completed?page=1&limit=10
Authorization: Bearer <token>
```

---

## 🔧 Routes Administration

### 1. Obtenir Mon Profil d'Admin
```
GET /admin/profile
Authorization: Bearer <token>
```

---

### 2. Obtenir les Statistiques du Système
```
GET /admin/statistics
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "data": {
    "total_users": 150,
    "total_patients": 100,
    "total_doctors": 20,
    "total_nurses": 15,
    "total_laboratories": 5,
    "total_consultations": 450,
    "appointments_last_30_days": 75,
    "active_prescriptions": 120,
    "exams_in_progress": 8
  }
}
```

---

### 3. Obtenir la Liste des Utilisateurs
```
GET /admin/users?page=1&limit=20
Authorization: Bearer <token>
```

---

### 4. Désactiver un Utilisateur
```
POST /admin/users/{userId}/deactivate
Authorization: Bearer <token>
```

---

### 5. Réactiver un Utilisateur
```
POST /admin/users/{userId}/activate
Authorization: Bearer <token>
```

---

### 6. Obtenir les Logs Système
```
GET /admin/logs?page=1&limit=50
Authorization: Bearer <token>
```

---

### 7. Obtenir l'Historique des Activités
```
GET /admin/activities?page=1&limit=20
Authorization: Bearer <token>
```

---
## 📅 Routes Agenda (Médecin)

### 1. Obtenir l'Agenda du Médecin
```
GET /doctor/agenda?page=1&limit=20
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Agenda récupéré",
  "data": [
    {
      "agenda_id": 1,
      "appointment_id": 1,
      "patient_id": 1,
      "patient_name": "John Doe",
      "appointment_date": "2026-05-15 10:00:00",
      "duration_minutes": 30,
      "status": "confirmed",
      "reason": "Consultation générale",
      "notes": "Patient avec antécédent d'asthme"
    }
  ],
  "pagination": {
    "total": 15,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  }
}
```

---

### 2. Obtenir les Jours Disponibles
```
GET /doctor/agenda/available-slots?month=2026-05&duration=30
Authorization: Bearer <token>
```

**Paramètres**:
- `month`: Format YYYY-MM (ex: 2026-05)
- `duration`: Durée de la consultation en minutes (ex: 30)

**Réponse** (200):
```json
{
  "success": true,
  "data": {
    "available_dates": [
      {
        "date": "2026-05-15",
        "slots": [
          {
            "time": "09:00",
            "available": true
          },
          {
            "time": "09:30",
            "available": false
          },
          {
            "time": "10:00",
            "available": true
          }
        ]
      }
    ]
  }
}
```

---

### 3. Créer un Créneau Horaire Indisponible
```
POST /doctor/agenda/unavailable-slot
Authorization: Bearer <token>
Content-Type: application/json
```

**Body**:
```json
{
  "start_date": "2026-05-15 14:00:00",
  "end_date": "2026-05-15 17:00:00",
  "reason": "Congé personnel"
}
```

**Réponse** (201):
```json
{
  "success": true,
  "message": "Créneau indisponible créé"
}
```

---

### 4. Obtenir les Créneaux Indisponibles
```
GET /doctor/agenda/unavailable-slots?month=2026-05
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "data": [
    {
      "unavailable_slot_id": 1,
      "start_date": "2026-05-15 14:00:00",
      "end_date": "2026-05-15 17:00:00",
      "reason": "Congé personnel"
    }
  ]
}
```

---

### 5. Supprimer un Créneau Indisponible
```
DELETE /doctor/agenda/unavailable-slot/{slotId}
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "message": "Créneau indisponible supprimé"
}
```

---

### 6. Obtenir les Rendez-vous du Jour
```
GET /doctor/agenda/today
Authorization: Bearer <token>
```

**Réponse** (200):
```json
{
  "success": true,
  "data": [
    {
      "appointment_id": 1,
      "patient_name": "John Doe",
      "appointment_time": "10:00",
      "status": "confirmed",
      "duration_minutes": 30
    }
  ]
}
```

---

### 7. Obtenir l'Agenda par Date
```
GET /doctor/agenda/by-date/{date}
Authorization: Bearer <token>
```

**Paramètres**:
- `date`: Format YYYY-MM-DD

**Réponse** (200):
```json
{
  "success": true,
  "data": [
    {
      "appointment_id": 1,
      "patient_id": 1,
      "patient_name": "John Doe",
      "start_time": "10:00",
      "end_time": "10:30",
      "status": "confirmed"
    }
  ]
}
```

---
## 📊 Codes de Statut HTTP

| Code | Signification |
|------|---------------|
| 200 | OK - Requête réussie |
| 201 | Created - Ressource créée |
| 400 | Bad Request - Données invalides |
| 401 | Unauthorized - Token invalide ou manquant |
| 403 | Forbidden - Accès refusé (permissions) |
| 404 | Not Found - Ressource non trouvée |
| 409 | Conflict - Conflit (ex: email existe déjà) |
| 500 | Internal Server Error - Erreur serveur |

---

## 🔒 Format du Token JWT

Le token JWT contient les informations suivantes:

```json
{
  "user_id": 1,
  "email": "user@esante.com",
  "full_name": "John Doe",
  "role": "patient",
  "iat": 1681380645,
  "exp": 1681467045
}
```

- **iat**: Issued At (horodatage de création)
- **exp**: Expiration (horodatage d'expiration) - 24 heures après création

---

## 📝 Notes Importantes

1. **Authentification**: Toutes les routes sauf `/health`, `/auth/register`, `/auth/login` et `/auth/verify-token` nécessitent un header `Authorization: Bearer <token>`

2. **Pagination**: Utilise les paramètres `page` et `limit`:
   - Page par défaut: 1
   - Limite par défaut: 20 résultats
   - Limite maximale: 100 résultats

3. **Gestion d'erreurs**: Les erreurs incluent un champ `errors` avec les détails:
   ```json
   {
     "success": false,
     "message": "Description de l'erreur",
     "statusCode": 400,
     "errors": {
       "field_name": "Message d'erreur spécifique"
     }
   }
   ```

4. **Timestamps**: Tous les timestamps sont au format ISO 8601: `YYYY-MM-DD HH:MM:SS`

5. **Validations**:
   - Email: Format email valide
   - Téléphone: Format sénégalais (77/78/70/76 suivi de 7 chiffres)
   - Date: Format YYYY-MM-DD
   - Groupe sanguin: A+, A-, B+, B-, AB+, AB-, O+, O-
   - Genre: M ou F
