# 🔄 SYNCHRONISATION DOSSIER PATIENT - MÉDECIN ↔ PATIENT

## 📋 Résumé des Modifications Requises

Tout ce que le **MÉDECIN** crée/modifie doit être visible au **PATIENT** en temps réel.

---

## ✅ DONNÉES À SYNCHRONISER

### 1️⃣ **CONSULTATIONS** ✅ (À vérifier)

**Créé par:** Médecin
**Affichage patient:** Onglet "Consultations"

| Champ | Description |
|-------|-------------|
| `consultation_date` | Date de la consultation |
| `doctor_name` | Nom du médecin |
| `diagnosis` | Diagnostic |
| `treatment` | Traitement prescrit |
| `notes` | Notes/Observations |
| `status` | Statut (complétée, programmée) |

**Endpoint API Patient:** `GET /exams/patient` ou `/medical-dossier/0/consultations`
**Endpoint API Médecin:** `GET /consultations/{consultationId}`

---

### 2️⃣ **EXAMENS PRESCRITS** ✅ (Corrigé)

**Créé par:** Médecin via `/exams/prescribe`
**Affichage patient:** Onglet "Examens"

| Champ | Description |
|-------|-------------|
| `exam_type` | Type d'examen (Biochimie, etc) |
| `exam_request_number` | Numéro unique |
| `speciality_id` | Spécialité |
| `urgency_level` | Niveau d'urgence |
| `observations` | Observations |
| `exam_status` | Statut (pending, completed) |
| `created_at` | Date de prescription |

**Endpoint API Patient:** ✅ `GET /exams/patient`
**Endpoint API Médecin:** `POST /exams/prescribe`

**Status:** ✅ **CORRIGÉ** - L'onglet "Examens" affiche maintenant les examens

---

### 3️⃣ **DIAGNOSTICS** ❌ (À AJOUTER)

**Créé par:** Médecin lors de la consultation
**Affichage patient:** À ajouter dans dossier

| Champ | Description |
|-------|-------------|
| `diagnosis_text` | Diagnostic |
| `diagnostic_code` | Code diagnostic |
| `doctor_name` | Médecin qui a fait le diagnostic |
| `consultation_date` | Date |
| `severity` | Sévérité |

**Endpoint API Patient:** ❌ **À créer**
**Endpoint API Médecin:** `GET /consultations/{id}/diagnosis`

**Status:** ❌ **À IMPLÉMENTER**

---

### 4️⃣ **TRAITEMENTS/ORDONNANCES** ⚠️ (Partiellement)

**Créé par:** Médecin via `/prescribe-ordonnance`
**Affichage patient:** Onglet "Ordonnances" ?

| Champ | Description |
|-------|-------------|
| `medication_name` | Nom du médicament |
| `dosage` | Dosage |
| `frequency` | Fréquence (3x/jour) |
| `duration` | Durée du traitement |
| `instructions` | Instructions |
| `doctor_name` | Médecin prescripteur |
| `prescription_date` | Date |

**Endpoint API Patient:** ❌ **À vérifier**
**Endpoint API Médecin:** `POST /prescribe-ordonnance`

**Status:** ⚠️ **À VÉRIFIER**

---

### 5️⃣ **RÉSULTATS D'EXAMEN** ⚠️ (Partial)

**Créé par:** Laboratoire
**Affichage patient:** À ajouter

| Champ | Description |
|-------|-------------|
| `exam_type` | Type d'examen |
| `result_value` | Valeur du résultat |
| `result_unit` | Unité |
| `reference_range` | Valeurs de référence |
| `interpretation` | Interprétation |
| `test_date` | Date du test |
| `lab_name` | Nom du laboratoire |
| `lab_technician` | Technicien |

**Endpoint API Patient:** ❌ **À ajouter**
**Endpoint API Médecin:** `GET /exams/{id}/results`

**Status:** ❌ **À IMPLÉMENTER**

---

### 6️⃣ **SIGNES VITAUX** ⚠️ (Partial)

**Enregistré par:** Médecin/Infirmière
**Affichage patient:** À vérifier

| Champ | Description |
|-------|-------------|
| `temperature` | Température (°C) |
| `blood_pressure` | Tension artérielle |
| `heart_rate` | Fréquence cardiaque |
| `respiratory_rate` | Fréquence respiratoire |
| `oxygen_saturation` | SpO2 |
| `weight` | Poids |
| `recorded_at` | Date/Heure |
| `recorded_by` | Qui a enregistré |

**Endpoint API Patient:** ⚠️ `GET /patient/vitals` (à vérifier)
**Endpoint API Médecin:** `POST /vitals` ou `GET /patient/{id}/vitals`

**Status:** ⚠️ **À VÉRIFIER**

---

## 📊 TABLEAU DE SYNCHRONISATION

| Élément | Créé par | Visible Patient | Visible Médecin | Status |
|---------|----------|-----------------|-----------------|--------|
| **Consultations** | Médecin | ✅ OUI | ✅ OUI | Vérifier |
| **Examens prescrits** | Médecin | ✅ OUI (CORRIGÉ) | ✅ OUI | ✅ OK |
| **Diagnostics** | Médecin | ❌ NON | ✅ OUI | ❌ À ajouter |
| **Ordonnances** | Médecin | ❌ ? | ✅ OUI | ⚠️ Vérifier |
| **Résultats examen** | Laboratoire | ❌ NON | ✅ OUI | ❌ À ajouter |
| **Signes vitaux** | Médecin/Infirmière | ❌ ? | ✅ OUI | ⚠️ Vérifier |
| **Vaccinations** | Médecin/Infirmière | ✅ OUI ? | ✅ OUI | ⚠️ Vérifier |
| **Allergies** | Médecin/Infirmière | ✅ OUI | ✅ OUI | Vérifier |

---

## 🔧 ACTIONS À ACCOMPLIR

### URGENT (Haute Priorité)

#### 1. ✅ Examens Prescrits
**Status:** ✅ CORRIGÉ
- [x] Patient voit les examens prescrits
- [x] Affichage avec statut et détails

#### 2. ❌ Diagnostics
**À faire:**
- [ ] Créer champ `diagnosis` dans table `consultations`
- [ ] Ajouter endpoint API: `GET /patient/diagnostics`
- [ ] Créer onglet "Diagnostics" dans dossier patient
- [ ] Afficher diagnostic + date + médecin + sévérité

#### 3. ❌ Résultats d'Examen
**À faire:**
- [ ] Ajouter endpoint API: `GET /patient/exam-results`
- [ ] Ajouter dans onglet "Examens": affichage des résultats
- [ ] Afficher: type, valeur, référence, interprétation, date

#### 4. ⚠️ Ordonnances
**À vérifier:**
- [ ] Endpoint API patient: `/patient/ordonnances` existe?
- [ ] Frontend affiche les ordonnances?
- [ ] Affichage complet: médicament, dosage, fréquence, durée

#### 5. ⚠️ Signes Vitaux
**À vérifier:**
- [ ] Endpoint API patient existe?
- [ ] Affichage au patient?
- [ ] Synchronisation en temps réel?

---

## 📱 INTERFACE PATIENT - ONGLETS À CRÉER/COMPLÉTER

### Onglet "Examens" (Actuel)
```
Affiche: ✅ Examens prescrits
À ajouter: 
- ✅ Statut de chaque examen
- ❌ Résultats quand disponibles
- ❌ Historique des résultats
- ❌ Bouton pour voir détails
```

### Onglet "Diagnostics" (À CRÉER)
```
Affiche:
- Diagnostic
- Date
- Médecin
- Sévérité
- Notes
```

### Onglet "Traitements" (À VÉRIFIER)
```
Affiche:
- Ordonnances (médicaments)
- Dosage
- Fréquence
- Durée
- Instructions
- Date de prescription
```

### Onglet "Résultats" (À CRÉER)
```
Affiche:
- Type d'examen
- Date du test
- Valeur mesurée
- Valeur de référence
- Interprétation
- Laboratoire
```

### Onglet "Signes Vitaux" (À VÉRIFIER)
```
Affiche (if exists):
- Température
- Tension artérielle
- FC
- SpO2
- Date/heure
- Qui a mesuré
```

---

## 🔌 ENDPOINTS API À CRÉER/VÉRIFIER

### Patient (Endpoints manquants)

```php
// ❌ À CRÉER
GET  /patient/diagnostics
GET  /patient/exam-results
GET  /patient/exam-results/{examId}
GET  /patient/vitals
GET  /patient/medications
GET  /patient/vaccinations

// ✅ À VÉRIFIER
GET  /patient/ordonnances
GET  /exams/patient (✅ EXISTE)
GET  /patient/profile (✅ EXISTE)
```

### Médecin (À vérifier qu'ils créent les données)

```php
// ✅ EXISTANTS
POST /exams/prescribe
POST /consultations
POST /prescribe-ordonnance
POST /vitals

// À ajouter à consultations:
PUT  /consultations/{id}  (inclure diagnosis)
```

### Laboratoire

```php
// ✅ EXISTANTS
POST /laboratory/exams/{examId}/record-results
GET  /laboratory/exams/pending
GET  /laboratory/exams/completed
```

---

## 💾 MODÈLES DE DONNÉES À VÉRIFIER

### Consultations
```sql
SELECT * FROM consultations LIMIT 1;
-- Doit avoir: diagnosis, treatment, notes
```

### Exams
```sql
SELECT * FROM exams LIMIT 1;
-- Doit avoir: exam_status, result_interpretation
```

### Notifications
```sql
SELECT * FROM notifications 
WHERE patient_id = 1 
ORDER BY created_at DESC;
-- Patient reçoit notification quand médecin crée consultation?
-- Patient reçoit notification quand labo enregistre résultats?
```

---

## 🔔 SYSTÈME DE NOTIFICATIONS

**À implémenter:**
- ✅ Notification patient quand examen prescrit
- ❌ Notification patient quand diagnostic créé
- ❌ Notification patient quand résultats disponibles
- ❌ Notification patient quand ordonnance créée
- ⚠️ Notification patient quand signes vitaux enregistrés (optionnel)

---

## 📋 SCRIPT DE VÉRIFICATION

```sql
-- Vérifier structures existantes
DESCRIBE consultations;  -- Vérifier champ diagnosis
DESCRIBE exams;          -- Vérifier champs résultats
DESCRIBE notifications;  -- Vérifier types

-- Vérifier données
SELECT COUNT(*) FROM consultations;
SELECT COUNT(*) FROM exams;
SELECT COUNT(*) FROM exam_results;  -- Cette table existe?
SELECT COUNT(*) FROM patient_vitals; -- Cette table existe?
```

---

## ✅ RÉSUMÉ DES CORRECTIONS

| # | Action | Priorité | Status |
|---|--------|----------|--------|
| 1 | Examens affichés au patient | 🔴 Haute | ✅ FAIT |
| 2 | Diagnostics visibles patient | 🔴 Haute | ❌ À faire |
| 3 | Résultats visibles patient | 🔴 Haute | ❌ À faire |
| 4 | Ordonnances visibles patient | 🟡 Moyenne | ⚠️ Vérifier |
| 5 | Signes vitaux visibles patient | 🟡 Moyenne | ⚠️ Vérifier |
| 6 | Notifications en temps réel | 🔴 Haute | ⚠️ Vérifier |
| 7 | API endpoints patients | 🔴 Haute | ⚠️ Vérifier |

---

## 🎯 PROCHAINES ÉTAPES

1. **Vérifier** les endpoints API actuels
2. **Identifier** ce qui existe vs ce qui manque
3. **Créer** les onglets manquants au patient
4. **Ajouter** les endpoints API manquants
5. **Implémenter** les notifications
6. **Tester** la synchronisation complète
