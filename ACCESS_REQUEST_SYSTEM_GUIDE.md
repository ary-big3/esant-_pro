# 📋 Guide Complet du Système de Demandes d'Accès au Dossier Patient

## 🎯 Vue d'ensemble
Ce système gère les demandes d'accès au dossier médical des patients par les médecins. Tout est enregistré en base de données sans données fictives.

---

## 📊 Flux Complet

### 1️⃣ MÉDECIN : Recherche et Demande d'Accès

**Écran:** `search_patient_screen.dart`

**Actions:**
1. Le médecin ouvre "Rechercher un patient"
2. Tape le nom ou ID du patient
3. Clique sur le patient dans les résultats
4. Une boîte de dialogue s'affiche pour entrer la **raison de la demande**
5. Clique sur "Envoyer la demande"

**Requête API:**
```
POST /doctors/request-patient-access
{
  "patient_id": 1,
  "reason": "Consultation médicale",
  "permission_type": "view_only"
}
```

**Données enregistrées en BD:**
- Table `access_requests` : nouvelle ligne avec status = "pending"
- Table `notifications` : notification envoyée au patient

---

### 2️⃣ PATIENT : Reçoit une Notification

**Écran:** `notifications_screen.dart`

**Événement:**
- Le patient reçoit une notification 🔐 "Demande d'accès à votre dossier médical"
- Le message indique: "Dr. [NOM] demande l'accès à votre dossier médical. Raison: [raison]"

**Actions:**
- Clique sur la notification → Navigue automatiquement vers "Demandes d'accès"

---

### 3️⃣ PATIENT : Approuve ou Rejette la Demande

**Écran:** `access_requests_screen.dart`

**Affichage:**
- Liste des demandes en attente
- Pour chaque demande:
  - Nom et spécialité du médecin
  - Raison de la demande
  - Date de la demande
  - Boutons: "✅ Approuver" ou "❌ Rejeter"

**Requête Approver:**
```
POST /access-requests/{request_id}/approve
```

**Requête Rejeter:**
```
POST /access-requests/{request_id}/reject
{
  "reason": "Je préfère ne pas partager" (optionnel)
}
```

**Données enregistrées en BD:**
- Table `access_requests` : status = "approved" ou "rejected"
- Table `access_permissions` : si approuvée
  - Crée une nouvelle ligne avec `expiry_date` = +1 an
- Table `access_logs` : enregistre l'action
- Table `notifications` : notification envoyée au médecin

---

### 4️⃣ MÉDECIN : Reçoit une Réponse

**Notification:** ✅ "Accès autorisé" ou ❌ "Demande refusée"

**Accès Direct:**
- Si approuvée, le médecin peut **immédiatement** voir le dossier complet du patient
- La vérification d'accès se fait via l'API:
  ```
  GET /access-requests/check/{patient_id}
  ```

---

## 🗄️ Tables de Base de Données

### 1. `access_requests`
```sql
request_id (PK)
patient_id (FK)
doctor_id (FK)
requester_user_id (FK) -- user_id du médecin
reason_for_access (TEXT)
permission_type (view_only, view_and_download, full_access)
status (pending, approved, rejected)
requested_at (DATETIME)
responded_at (DATETIME)
response_reason (TEXT) -- si rejeté
```

### 2. `access_permissions`
```sql
permission_id (PK)
patient_id (FK)
authorized_user_id (FK) -- user_id du médecin autorisé
permission_type
granted_date
expiry_date (NULL = sans limite)
granted_by (user_id du patient)
is_revoked (BOOLEAN)
revoked_date
revoked_by
```

### 3. `access_logs`
```sql
log_id (PK)
user_id (FK) -- qui accède
accessed_patient_id (FK)
action_type (view, download, modify, delete, create)
resource_type (patient_record, medical_document, prescription, exam, appointment, message)
resource_id
access_status (success, denied, failed)
ip_address
user_agent
access_timestamp
```

### 4. `notifications`
```sql
notification_id (PK)
user_id (FK)
notification_type (access_request, access_approved, access_rejected, etc.)
title
message
is_read (BOOLEAN)
read_at (DATETIME)
created_at (DATETIME)
```

---

## 🔒 Vérification d'Accès

### Middleware: `hasAccess($patient_id)`

Vérifie si un utilisateur a le droit d'accéder au dossier d'un patient:

1. **Patient lui-même** ✅ Accès toujours autorisé (son dossier)
2. **Médecin** ✅ Accès autorisé si:
   - Une `access_permission` existe
   - Pas révoquée (`is_revoked = FALSE`)
   - Pas expirée (`expiry_date IS NULL OR expiry_date > NOW()`)
3. **Autres rôles** ✅ Même vérification

### Réponse API:
```json
{
  "has_access": true,
  "reason": "granted_permission|own_record",
  "permission_type": "view_only",
  "expiry_date": "2027-04-19"
}
```

---

## 📌 Points Clés d'Implémentation

### Backend Controllers Modifiés
1. **DoctorController::sendAccessRequest()** ✅
   - Crée une demande dans `access_requests`
   - Envoie une notification au patient
   - Vérifie qu'aucune demande en attente n'existe

2. **PatientController::getPendingRequests()** ✅
   - Récupère les demandes en attente du patient

3. **PatientController::approveAccessRequest()** ✅
   - Approuve la demande
   - Crée une `access_permission`
   - Envoie une notification au médecin
   - Journalise l'action

4. **PatientController::rejectAccessRequest()** ✅
   - Rejette la demande
   - Envoie une notification au médecin

5. **AccessRequestController::hasAccess()** ✅
   - Vérifie l'accès en temps réel
   - Journalise chaque tentative d'accès

### Frontend Widgets Modifiés
1. **search_patient_screen.dart** ✅
   - Dialog amélioré pour entrer la raison
   - Messages de succès/erreur
   - Validation de la raison obligatoire

2. **notifications_screen.dart** ✅
   - Affiche les demandes d'accès avec emoji 🔐
   - Lien direct vers l'écran des demandes

3. **access_requests_screen.dart** ✅
   - Affiche les demandes en attente
   - Boutons Approver/Rejeter
   - Affichage des détails du médecin

---

## 🧪 Scénario de Test

### Test 1: Flux Complet Approuvé

1. **Médecin A** recherche "Patient B"
2. Clique sur Patient B, entre raison: "Consultation cardiaque"
3. **Patient B** reçoit notification 🔐
4. **Patient B** clique sur notification → Va à "Demandes d'accès"
5. **Patient B** voit la demande avec "Dr. [Médecin A] - Consultation cardiaque"
6. **Patient B** clique "✅ Approuver"
7. **Médecin A** reçoit notification "✅ Accès autorisé"
8. **Médecin A** peut maintenant voir le dossier complet du Patient B
9. **Vérifier BD:**
   - `access_requests`: status = "approved"
   - `access_permissions`: nouvelle ligne avec Patient B et Médecin A
   - `access_logs`: log de succès

### Test 2: Flux Rejeté

1. Même jusqu'à l'étape 4
2. **Patient B** clique "❌ Rejeter"
3. Entre une raison: "Je n'accepte pas"
4. **Médecin A** reçoit notification "❌ Demande refusée"
5. **Vérifier BD:**
   - `access_requests`: status = "rejected", response_reason rempli
   - Pas de ligne dans `access_permissions`
   - `access_logs`: log de refus

---

## 🛡️ Sécurité & Conformité

✅ **Toutes les données sont réelles** (enregistrées en BD)
✅ **Audit trail** (journalisation complète dans `access_logs`)
✅ **Consentement explicite** (patient approuve/rejette)
✅ **Traçabilité** (qui, quand, raison, IP, user-agent)
✅ **RGPD compliant** (droit d'accès, traçabilité)

---

## 📱 Routes API

| Méthode | Route | Qui | Description |
|---------|-------|-----|-------------|
| POST | `/doctors/request-patient-access` | Médecin | Créer une demande |
| GET | `/patients/pending-requests` | Patient | Voir ses demandes |
| POST | `/patients/requests/{id}/approve` | Patient | Approuver |
| POST | `/patients/requests/{id}/reject` | Patient | Rejeter |
| POST | `/access-requests/{id}/approve` | Patient | Alternative approuver |
| POST | `/access-requests/{id}/reject` | Patient | Alternative rejeter |
| GET | `/access-requests/check/{patientId}` | Médecin | Vérifier l'accès |
| GET | `/access-requests` | Patient | Lister les demandes |

---

## 📝 Notes Importantes

1. **Raison obligatoire** : Le médecin doit entrer une raison pour sa demande
2. **Notification en temps réel** : Les patients reçoivent une notification immédiate
3. **Expiration automatique** : Les permissions expirent après 1 an
4. **Revocation possible** : Un patient peut révoquer l'accès à tout moment
5. **Journal d'audit** : Chaque accès est enregistré (IP, user-agent, etc.)

---

## 🔧 Troubleshooting

### Problème: Patient ne reçoit pas la notification
- Vérifier que `notifications` a une ligne
- Vérifier que `notification_type = 'access_request'`
- Vérifier que le `user_id` du patient est correct

### Problème: Médecin ne peut pas accéder au dossier
- Vérifier `access_permissions` existe
- Vérifier `is_revoked = FALSE`
- Vérifier `expiry_date IS NULL OR expiry_date > NOW()`

### Problème: Demande dupliquée
- Vérifier s'il existe une demande "pending" pour le même médecin-patient
- Le système rejette les demandes en attente

---

## 🎉 Résumé du Système

Ce système garantit:
1. ✅ Le patient **contrôle totalement** l'accès à son dossier
2. ✅ Le médecin doit **justifier** sa demande
3. ✅ **Audit complet** de chaque accès
4. ✅ **Zéro données fictives** - tout en BD
5. ✅ **Notifications en temps réel**
6. ✅ **Flux transparent** et intuitif

---

*Système complètement implémenté et testé - 19 avril 2026*
