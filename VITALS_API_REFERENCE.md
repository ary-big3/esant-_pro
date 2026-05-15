# 📚 Référence API - Constantes Vitales

## Base URL
```
http://192.168.8.105/esante/backend/public
```

## Authentification
Tous les endpoints nécessitent un token JWT dans le header :
```
Authorization: Bearer <token_jwt>
```

---

## 📋 Endpoints

### 1️⃣ Enregistrer les Constantes Vitales

**Endpoint:**
```
POST /nurse/vitals
Content-Type: application/json
Authorization: Bearer <token>
```

**Rôle requis:** Infirmière

**Body:**
```json
{
  "patient_id": 123,
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
}
```

**Réponse (201 Created):**
```json
{
  "success": true,
  "message": "Signes vitaux enregistrés avec succès",
  "data": {
    "vital_sign_id": 456,
    "status": "normal"
  }
}
```

**Erreurs possibles:**
- `400` - Données invalides
- `401` - Non authentifié
- `403` - Rôle insuffisant
- `500` - Erreur serveur

---

### 2️⃣ Récupérer l'Historique des Constantes

**Endpoint:**
```
GET /nurse/vitals/{patientId}?page=1&limit=10
Content-Type: application/json
Authorization: Bearer <token>
```

**Rôle requis:** Infirmière, Docteur, Patient (accès contrôlé)

**Paramètres Query:**
| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| page | int | 1 | Numéro de page |
| limit | int | 10 | Nombre de résultats par page |

**Réponse (200 OK):**
```json
{
  "success": true,
  "message": "Signes vitaux récupérés",
  "data": [
    {
      "vital_sign_id": 456,
      "patient_id": 123,
      "nurse_id": 1,
      "measurement_date": "2026-04-29 10:30:00",
      "temperature_celsius": 37.2,
      "systolic_pressure": 120,
      "diastolic_pressure": 80,
      "pulse_bpm": 72,
      "respiratory_rate": 16,
      "oxygen_saturation": 98.0,
      "weight_kg": 70,
      "height_cm": 175,
      "status": "normal",
      "notes": "Patient en bon état",
      "created_at": "2026-04-29 10:30:00",
      "updated_at": null,
      "nurse_first_name": "Marie",
      "nurse_last_name": "Dupont"
    }
  ],
  "pagination": {
    "total": 5,
    "page": 1,
    "limit": 10,
    "totalPages": 1
  }
}
```

---

### 3️⃣ Récupérer les Dernières Constantes

**Endpoint:**
```
GET /nurse/vitals/{patientId}/latest
Content-Type: application/json
Authorization: Bearer <token>
```

**Rôle requis:** Infirmière, Docteur, Patient (accès contrôlé)

**Réponse (200 OK):**
```json
{
  "success": true,
  "message": "Dernières constantes vitales",
  "data": {
    "vital_sign_id": 456,
    "patient_id": 123,
    "nurse_id": 1,
    "measurement_date": "2026-04-29 10:30:00",
    "temperature_celsius": 37.2,
    "systolic_pressure": 120,
    "diastolic_pressure": 80,
    "pulse_bpm": 72,
    "respiratory_rate": 16,
    "oxygen_saturation": 98.0,
    "weight_kg": 70,
    "height_cm": 175,
    "status": "normal",
    "notes": "Patient en bon état",
    "created_at": "2026-04-29 10:30:00",
    "updated_at": null,
    "nurse_first_name": "Marie",
    "nurse_last_name": "Dupont"
  }
}
```

---

### 4️⃣ Mettre à Jour les Constantes Vitales

**Endpoint:**
```
PUT /nurse/vitals/{vitalId}
Content-Type: application/json
Authorization: Bearer <token>
```

**Rôle requis:** Infirmière

**Body:**
```json
{
  "temperature_celsius": 37.5,
  "systolic_pressure": 125,
  "diastolic_pressure": 85,
  "pulse_bpm": 75,
  "respiratory_rate": 18,
  "oxygen_saturation": 97.5,
  "weight_kg": 70,
  "height_cm": 175,
  "status": "normal",
  "notes": "Patient stable"
}
```

**Réponse (200 OK):**
```json
{
  "success": true,
  "message": "Signes vitaux mis à jour avec succès",
  "data": {
    "vital_sign_id": 456,
    "status": "normal"
  }
}
```

**Restrictions:**
- Seule l'infirmière qui a créé la mesure peut la modifier
- Tous les champs sont optionnels (update partiel)

---

### 5️⃣ Supprimer les Constantes Vitales

**Endpoint:**
```
DELETE /nurse/vitals/{vitalId}
Content-Type: application/json
Authorization: Bearer <token>
```

**Rôle requis:** Infirmière

**Réponse (200 OK):**
```json
{
  "success": true,
  "message": "Signes vitaux supprimés avec succès",
  "data": {
    "vital_sign_id": 456
  }
}
```

**Restrictions:**
- Seule l'infirmière qui a créé la mesure peut la supprimer
- La suppression est définitive

---

## 🔍 Codes d'Erreur

| Code | Message | Signification |
|------|---------|---------------|
| 400 | Bad Request | Données invalides ou manquantes |
| 401 | Unauthorized | Token manquant ou invalide |
| 403 | Forbidden | Accès refusé (rôle insuffisant) |
| 404 | Not Found | Ressource non trouvée |
| 422 | Unprocessable Entity | Données invalides (validation) |
| 500 | Internal Server Error | Erreur serveur |

**Exemple d'erreur :**
```json
{
  "success": false,
  "message": "Température invalide",
  "errors": {
    "temperature_celsius": "La valeur doit être entre 35 et 43"
  },
  "statusCode": 400
}
```

---

## 📊 Schéma des Données

### Tableau : vital_signs

```sql
CREATE TABLE vital_signs (
  vital_sign_id INT PRIMARY KEY AUTO_INCREMENT,
  patient_id INT NOT NULL,
  nurse_id INT NOT NULL,
  measurement_date DATETIME NOT NULL,
  temperature_celsius DECIMAL(4,2),
  systolic_pressure INT,
  diastolic_pressure INT,
  pulse_bpm INT,
  respiratory_rate INT,
  oxygen_saturation DECIMAL(4,2),
  weight_kg DECIMAL(6,2),
  height_cm DECIMAL(6,2),
  status VARCHAR(50),
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
  FOREIGN KEY (nurse_id) REFERENCES nurses(nurse_id),
  INDEX idx_patient (patient_id),
  INDEX idx_nurse (nurse_id),
  INDEX idx_measurement_date (measurement_date)
);
```

---

## 🧪 Exemples cURL

### Enregistrer
```bash
curl -X POST http://192.168.8.105/esante/backend/public/nurse/vitals \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGc..." \
  -d '{
    "patient_id": 123,
    "temperature_celsius": 37.2,
    "systolic_pressure": 120,
    "diastolic_pressure": 80,
    "pulse_bpm": 72,
    "respiratory_rate": 16,
    "oxygen_saturation": 98.0,
    "weight_kg": 70,
    "height_cm": 175,
    "notes": "Patient stable"
  }'
```

### Récupérer
```bash
curl -X GET "http://192.168.8.105/esante/backend/public/nurse/vitals/123?page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGc..."
```

### Mettre à jour
```bash
curl -X PUT http://192.168.8.105/esante/backend/public/nurse/vitals/456 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGc..." \
  -d '{
    "temperature_celsius": 37.5,
    "systolic_pressure": 125
  }'
```

### Supprimer
```bash
curl -X DELETE http://192.168.8.105/esante/backend/public/nurse/vitals/456 \
  -H "Authorization: Bearer eyJhbGc..."
```

---

## 🔐 Règles de Sécurité

### Authentification
- ✅ Token JWT obligatoire
- ✅ Token valide et non expiré
- ✅ Token dans le header Authorization

### Autorisation
- ✅ Rôle Infirmière requis pour POST/PUT/DELETE
- ✅ Rôle Patient, Docteur, Infirmière pour GET
- ✅ Vérification de l'accès aux données du patient

### Validation
- ✅ Température : 35°C - 43°C
- ✅ TA Systolique : 50 - 250 mmHg
- ✅ TA Diastolique : 30 - 150 mmHg
- ✅ FC : 30 - 250 bpm
- ✅ FR : 0 - 100 rpm
- ✅ O₂ : 0 - 100%
- ✅ Poids : 2 - 300 kg
- ✅ Taille : 50 - 250 cm

---

## 📈 Limits et Pagination

- **Limite par défaut :** 10 résultats
- **Limite maximale :** 100 résultats
- **Offset :** `(page - 1) * limit`
- **Total pages :** `ceil(total / limit)`

---

## 🕐 Format des Dates

Tous les champs de date/heure utilisent le format ISO 8601 :
```
YYYY-MM-DD HH:MM:SS
2026-04-29 10:30:45
```

Conversion depuis timestamp Unix :
```
new Date(timestamp * 1000).toISOString()
```

---

## 🧬 Paramètres Optionnels vs Requis

### POST (Enregistrement)
```
Requis : patient_id, temperature_celsius, systolic_pressure, 
         diastolic_pressure, pulse_bpm, respiratory_rate, 
         oxygen_saturation

Optionnels : weight_kg, height_cm, status, notes
```

### PUT (Modification)
```
Tous les paramètres sont optionnels
Seuls les champs fournis seront mis à jour
```

### GET (Récupération)
```
Requis : aucun (les données du user authentifié par défaut)

Paramètres Query : page, limit
```

---

## 📝 Notes sur l'API

1. **Horodatage :** Les timestamps sont générés par le serveur
2. **Idempotence :** POST n'est pas idempotent (crée un nouvel enregistrement)
3. **Atomicité :** Chaque opération est une transaction unique
4. **Cohérence :** Les données sont validées côté serveur

---

## 🔗 Ressources Associées

- Patient : `/patient/{patientId}/profile`
- Infirmière : `/nurse/profile`
- Dossier Médical : `/medical-dossier/{patientId}/summary`

---

## 📞 Support Technique

Pour les problèmes API :
1. Vérifier le token JWT
2. Vérifier les permissions du rôle
3. Vérifier les plages de valeurs
4. Consulter les logs du serveur

**Logs :** `/backend/logs/`
**Contact Support :** support@esante.com

---

**Dernière mise à jour :** 29 avril 2026
**Version API :** 1.0.0
**Status :** Production Ready
