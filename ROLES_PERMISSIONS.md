# 🔐 Rôles et Permissions - E-Santé

## 📋 Vue d'ensemble des Rôles

| Rôle | Description | Niveau d'Accès |
|------|-------------|----------------|
| **PATIENT** | Patient accédant à son dossier | 🟢 Limité |
| **MEDECIN** | Médecin prescripteur | 🟡 Moyen |
| **INFIRMIERE** | Infirmière - Consultations | 🟡 Moyen |
| **LABORATOIRE** | Laboratoire - Analyse | 🟠 Élevé |
| **ADMIN** | Administrateur système | 🔴 Complet |
| **MINISTERE** | Ministère - Supervision | 🟠 Élevé |

---

## 🔑 Permissions Détaillées par Rôle

### 👤 PATIENT (patient)
**Accès:** `Limité` - Consultation uniquement

| Action | Accès |
|--------|-------|
| Voir son dossier médical | ✅ OUI |
| Voir ses consultations | ✅ OUI |
| Voir ses examens prescrits | ✅ OUI |
| Voir ses ordonnances | ✅ OUI |
| Voir ses vaccinations | ✅ OUI |
| Télécharger documents | ✅ OUI |
| Accès rendez-vous | ✅ OUI |
| Modifier profil | ✅ OUI |
| Accès notifications | ✅ OUI |
| Accès requêtes d'accès | ✅ OUI (pour enfants) |
| Modifier dossier | ❌ NON |
| Prescrire examen | ❌ NON |
| Accès laboratoire | ❌ NON |
| Accès admin | ❌ NON |

---

### 👨‍⚕️ MEDECIN (medecin)
**Accès:** `Moyen` - Gestion consultations et prescriptions

| Action | Accès |
|--------|-------|
| Voir dossier patient | ✅ OUI (si consultation) |
| Créer consultation | ✅ OUI |
| Modifier consultation | ✅ OUI (propre consultation) |
| Prescrire examen | ✅ OUI |
| Prescrire ordonnance | ✅ OUI |
| Voir examens prescrits | ✅ OUI |
| Recevoir notifications examen | ✅ OUI |
| Gérer rendez-vous | ✅ OUI |
| Voir résultats examen | ✅ OUI |
| Supprimer consultation | ❌ NON |
| Accès laboratoire | ❌ NON |
| Accès admin | ❌ NON |
| Voir tous les patients | ❌ NON |

---

### 👩‍⚕️ INFIRMIERE (infirmiere)
**Accès:** `Moyen` - Support médical et suivi

| Action | Accès |
|--------|-------|
| Voir dossier patient | ✅ OUI (assigné) |
| Voir consultations | ✅ OUI |
| Voir examens | ✅ OUI |
| Voir signes vitaux | ✅ OUI |
| Enregistrer signes vitaux | ✅ OUI |
| Voir ordonnances | ✅ OUI |
| Créer examen (assistante) | ✅ OUI |
| Recevoir notifications | ✅ OUI |
| Modifier ordonnance | ❌ NON |
| Prescrire indépendamment | ❌ NON |
| Accès laboratoire | ❌ NON |
| Accès admin | ❌ NON |

---

### 🔬 LABORATOIRE (laboratoire)
**Accès:** `Élevé` - Gestion des analyses

| Action | Accès |
|--------|-------|
| Voir examens prescrits | ✅ OUI (assignés) |
| Voir détails examen | ✅ OUI |
| Modifier statut examen | ✅ OUI |
| Enregistrer résultats | ✅ OUI |
| Voir patient (examen) | ✅ OUI (limité) |
| Recevoir notifications | ✅ OUI |
| Voir historique examens | ✅ OUI |
| Imprimer résultats | ✅ OUI |
| Voir statistiques | ✅ OUI |
| Ajouter spécialité | ❌ NON |
| Modifier examen (médecin) | ❌ NON |
| Accès admin | ❌ NON |
| Voir tous les patients | ❌ NON |

**Routes Laboratoire:**
- `GET /laboratory/exams/pending` - Examens en attente
- `GET /laboratory/exams/completed` - Examens complétés
- `POST /laboratory/exams/{id}/start` - Démarrer examen
- `POST /laboratory/exams/{id}/record-results` - Enregistrer résultats

---

### 🔧 ADMIN (admin)
**Accès:** `Complet` - Contrôle total

| Action | Accès |
|--------|-------|
| Voir tous les dossiers | ✅ OUI |
| Gérer utilisateurs | ✅ OUI |
| Créer/Modifier/Supprimer utilisateur | ✅ OUI |
| Assigner rôles | ✅ OUI |
| Gérer spécialités | ✅ OUI |
| Gérer laboratoires | ✅ OUI |
| Gérer hôpitaux | ✅ OUI |
| Voir statistiques | ✅ OUI |
| Accès audit | ✅ OUI |
| Gérer paramètres | ✅ OUI |
| Supprimer données | ✅ OUI |
| Voir logs | ✅ OUI |
| Gérer permissions | ✅ OUI |

**Routes Admin:**
- `GET /admin/users` - Liste utilisateurs
- `POST /admin/users` - Créer utilisateur
- `PUT /admin/users/{id}` - Modifier utilisateur
- `DELETE /admin/users/{id}` - Supprimer utilisateur
- `GET /admin/specialities` - Gérer spécialités
- `GET /admin/statistics` - Voir statistiques

---

### 🏛️ MINISTERE (ministere)
**Accès:** `Élevé` - Supervision et rapport

| Action | Accès |
|--------|-------|
| Voir statistiques nationales | ✅ OUI |
| Voir rapports | ✅ OUI |
| Voir audit trail | ✅ OUI |
| Voir performance | ✅ OUI |
| Voir KPIs | ✅ OUI |
| Générer rapports | ✅ OUI |
| Voir données agrégées | ✅ OUI |
| Modifier paramètres | ❌ NON |
| Voir patient individuel | ❌ NON |
| Accès admin complet | ❌ NON |

---

## 🔐 Matrice de Contrôle d'Accès (ACL)

```
Ressource                   | Patient | Médecin | Infirmière | Labo | Admin | Ministère
-----------------------------|---------|---------|------------|------|-------|----------
/patient/profile            |    R    |    -    |     -      |  -   |   R   |    -
/patient/consultations      |    R    |    RW   |     R      |  -   |   R   |    -
/patient/exams              |    R    |    R    |     R      |  R   |   R   |    -
/patient/ordonnances        |    R    |    R    |     R      |  -   |   R   |    -
/consultations              |    -    |    RW   |     R      |  -   |   R   |    -
/exams/prescribe            |    -    |    C    |     -      |  -   |   R   |    -
/exams/{id}/results         |    R    |    R    |     -      |  RW  |   R   |    -
/laboratory/exams           |    -    |    -    |     -      |  RW  |   R   |    -
/admin/users                |    -    |    -    |     -      |  -   |   RW  |    -
/admin/statistics           |    -    |    -    |     -      |  -   |   R   |    R
/ministry/reports           |    -    |    -    |     -      |  -   |   R   |    R

R = Read (Lecture)
W = Write (Écriture)
C = Create (Création)
RW = Read + Write
```

---

## 📱 Écrans Accessibles par Rôle

| Écran | Patient | Médecin | Infirmière | Labo | Admin | Ministère |
|-------|---------|---------|------------|------|-------|-----------|
| Accueil | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Dossier Médical | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Consultations | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Examens | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Rendez-vous | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| Profil | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Laboratoire | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| Admin Panel | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Statistiques | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Rapports | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |

---

## 🚀 FLUX DE PRESCRIPTION D'EXAMEN

```
MÉDECIN Prescrit Examen
    ↓
API POST /exams/prescribe
    ↓
Examen inséré en base de données (status: pending)
    ↓
✅ Notification PATIENT: "Examen prescrit"
✅ Notification LABORATOIRE: "Examen à traiter"
    ↓
LABORATOIRE reçoit notification
    ↓
Laboratoire voit l'examen en: GET /laboratory/exams/pending
    ↓
Laboratoire démarre: POST /laboratory/exams/{id}/start
    ↓
Laboratoire enregistre résultats: POST /laboratory/exams/{id}/record-results
    ↓
✅ Notification MÉDECIN: "Résultats disponibles"
✅ Notification PATIENT: "Résultats de votre examen"
    ↓
PATIENT voit résultat dans son dossier /exams/patient
```

---

## 📧 Système de Notifications

### Types de Notifications par Rôle

**PATIENT:**
- Examen prescrit
- Résultats examen disponibles
- Nouvelle consultation
- Ordonnance disponible
- Rendez-vous confirmé/modifié
- Message du médecin

**MÉDECIN:**
- Rendez-vous confirmé
- Consultation effectuée
- Résultats examen disponibles
- Demande d'accès au dossier
- Message du patient

**INFIRMIÈRE:**
- Nouvelle consultation assignée
- Examen à effectuer
- Message du médecin
- Mise à jour signes vitaux

**LABORATOIRE:**
- Nouvel examen prescrit
- Examen urgent
- Demande d'information
- Rappel examen en attente

**ADMIN:**
- Nouvel utilisateur créé
- Erreur système
- Rapport journalier
- Alerte sécurité

---

## 🔒 Middleware d'Authentification

```php
// Vérification du rôle requise
AuthMiddleware::verifyRole(ROLE_MEDECIN, $user['role']);

// Cas spéciaux:
- Patient ne peut voir que SON dossier
- Médecin ne peut voir que ses patients (consultations)
- Infirmière ne peut voir que ses patients assignés
- Laboratoire ne peut voir que ses examens
```

---

## ⚠️ Niveaux de Sécurité

- **Public:** Pas d'authentification requise (Login, Register)
- **Authentifié:** Token JWT requis
- **Rôle:** Rôle spécifique requis
- **Propriétaire:** Accès aux propres données uniquement
- **Superviseur:** Accès aux données de l'équipe

---

## 🎯 Coordonnées de Support

**Administrateur Système:**
- Email: admin@esante.com
- Tél: +1 555-0123
- Support: support@esante.com

**Centre d'Aide:**
- Documentation: /docs
- FAQ: /faq
- Support 24/7: support@esante.com

**Équipe de Développement:**
- Email: dev@esante.com
- GitLab: https://gitlab.esante.com
- Issues: https://issues.esante.com
