## 🔍 GUIDE DE DEBUG - Demandes d'Accès en BD

### 📋 Flux Complet que vous devez vérifier:

```
MÉDECIN clique sur patient
    ↓
Frontend envoie POST /doctors/request-patient-access
    ↓
Backend insère dans TABLE access_requests
    ↓
Backend crée notification pour patient
    ↓
PATIENT reçoit notification
    ↓
PATIENT approuve → permission créée en TABLE access_permissions
```

---

### 🔧 LOGS À VÉRIFIER (en ordrechronologique)

#### 1️⃣ **FRONTEND - Quand le médecin clique sur patient:**
```
Look for in Flutter console:
🔵 [Access Request] Début
🟢 [Access Request] Envoi vers /doctors/request-patient-access
   patient_id: 6
   reason: Consultation cardiaque
🟢 [Access Request] Réponse reçue: true
   request_id: 42
✅ [Access Request] FIN - Succès
```

#### 2️⃣ **BACKEND - PHP Logs (dans C:\xampp\htdocs\esante\backend\logs\):**

**Si tout fonctionne:**
```
🔵 [sendAccessRequest] DÉBUT
🔵 [sendAccessRequest] User authentifié: user_id=22, role=medecin
🟢 [sendAccessRequest] Doctor trouvé: doctor_id=1
🔵 [sendAccessRequest] Données reçues: {"patient_id":6,"reason":"Consultation cardiaque",...}
🟢 [sendAccessRequest] Patient trouvé: patientId=6, patientUserId=16
🔵 [sendAccessRequest] Insertion dans access_requests: patientId=6, doctorId=1, requesterUserId=22
🟢 [sendAccessRequest] Demande créée avec request_id=42
🟢 [sendAccessRequest] Notification créée avec succès pour user_id=16
✅ [sendAccessRequest] FIN - request_id=42 créée dans access_requests
```

#### 3️⃣ **VÉRIFIER LA BASE DE DONNÉES:**

```sql
-- Voir la demande créée:
SELECT * FROM access_requests WHERE patient_id = 6 ORDER BY requested_at DESC;

-- Résultat attendu:
request_id: 42
patient_id: 6
doctor_id: 1
requester_user_id: 22
status: pending
reason_for_access: "Consultation cardiaque"
requested_at: 2026-04-19 22:35:00
```

---

### 🚨 PROBLÈMES POSSIBLES & SOLUTIONS:

#### ❌ **Les logs Frontend montrent ERROR au lieu de Succès:**
- Vérifier que l'API retourne HTTP 200
- Vérifier que la réponse contient `"success": true`
- Vérifier l'erreur dans le SnackBar (message affiché)

#### ❌ **Les logs Backend ne montrent rien (aucun log):**
- L'endpoint `/doctors/request-patient-access` n'est pas atteint
- Vérifier que la route est correcte en Router.php
- **Chercher:** `elseif ($this->matchRoute('POST', 'doctors/request-patient-access'))`

#### ❌ **Les logs Backend montrent "Médecin non trouvé":**
- L'utilisateur n'a pas de record en table `doctors`
- Vérifier: `SELECT * FROM doctors WHERE user_id = 22;`

#### ❌ **Les logs Backend montrent "Patient non trouvé":**
- Le patient_id envoyé n'existe pas
- Vérifier: `SELECT * FROM patients WHERE patient_id = 6;`

#### ❌ **Les logs Backend montrent erreur insertion:**
- Erreur SQL (colonnes/types incorrects)
- Vérifier structure: `DESCRIBE access_requests;`

---

### ✅ VÉRIFICATION RAPIDE EN SQL:

```sql
-- 1. Y a-t-il des demandes en BD ?
SELECT COUNT(*) as total FROM access_requests;

-- 2. Quelles sont les demandes récentes ?
SELECT * FROM access_requests ORDER BY requested_at DESC LIMIT 10;

-- 3. Quel statut ont-elles ?
SELECT status, COUNT(*) as count FROM access_requests GROUP BY status;

-- 4. Les notifications sont-elles créées ?
SELECT * FROM notifications WHERE notification_type = 'access_request' ORDER BY created_at DESC LIMIT 10;
```

---

### 📝 CHECKLIST DE DEBUG:

- [ ] Médecin peut chercher un patient
- [ ] Quand médecin clique sur patient → Dialog s'ouvre
- [ ] Médecin rentre une raison
- [ ] Clique "Envoyer" → Message "Demande envoyée" apparaît
- [ ] Console Flutter montre ✅ [Access Request] FIN
- [ ] Console PHP montre ✅ [sendAccessRequest] FIN
- [ ] Query SQL montre la demande en `access_requests`
- [ ] Statut de la demande est `pending`
- [ ] Notification est créée pour le patient
- [ ] Patient reçoit la notification

---

### 📞 FICHIERS CONCERNÉS:

**Backend:**
- `/backend/controllers/DoctorController.php` → Fonction `sendAccessRequest()`
- `/backend/routes/Router.php` → Route `POST /doctors/request-patient-access`
- `/backend/controllers/NotificationController.php` → Fonction `getMyNotifications()`

**Frontend:**
- `/lib/screens/medecin/search_patient_screen.dart` → Fonction `_submitAccessRequest()`
- `/lib/screens/patient/notifications_screen.dart` → Fonction `_loadNotifications()`

**Database:**
- Table `access_requests` - Stocke les demandes
- Table `notifications` - Stocke les notifications
- Table `access_permissions` - Créée après approbation
