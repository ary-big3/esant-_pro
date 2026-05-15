# Flux de Gestion des Examens et Laboratoires

## 📋 Vue d'ensemble

Ce système gère le flux complet : 
**Médecin → Demande d'Examen → Laboratoire → Résultats → Patient & Médecin**

---

## 🔄 Flux Complet

### 1️⃣ Prescription - Médecin demande un examen

**Acteur:** Médecin généraliste  
**Écran:** `PrescribeExamScreen` (`/medecin/prescribe-exam`)

#### Étapes:
1. Le médecin sélectionne la **spécialité** du patient (Biologie médicale, Radiologie, etc.)
2. Le système affiche automatiquement le **laboratoire assigné** pour cette spécialité
3. Le médecin sélectionne les **examens spécifiques** disponibles dans ce laboratoire
4. Le médecin définit l'**urgence** (Normal, Urgent, Très urgent)
5. Le médecin peut ajouter des **observations cliniques**
6. Le médecin valide la demande

#### Données créées:
```dart
ExamRequestModel {
  id: 'REF-2026-XXXXXXX',
  patientId: 'P123',
  patientNom: 'Aminata Sow',
  medecinId: 'M456',
  medecinNom: 'Dr. Fatou Diop',
  specialite: 'Biologie médicale',
  examensPrescrits: ['NFS', 'Glycémie', 'Bilan lipidique'],
  laboratoireId: 'LAB_Biologie',
  laboratoireNom: 'Laboratoire d\'analyses médicales',
  status: ExamRequestStatus.pending,
  urgence: 'normal'
}
```

---

### 2️⃣ Reception - Laboratoire reçoit la demande

**Acteur:** Technicien/Responsable du laboratoire  
**Écran:** `LaboratoryScreen` (`/laboratory`)  
**Tab:** "En attente"

#### Fonctionnement automatique:
- La demande apparaît automatiquement dans la section **"En attente"** du laboratoire
- Les infos du patient et du médecin prescripteur sont affichées
- La priorité (urgence) est visible

#### Actions du laboratoire:
- **Accepter la demande** → Change le statut à `inProgress`
- Le laboratoire **planifie un RDV** pour le patient (optionnel)

---

### 3️⃣ Execution - Réalisation de l'examen

**Acteur:** Technicien du laboratoire

#### Processus:
1. Le patient se présente au laboratoire
2. Le technicien réalise l'examen
3. Les resultats sont enregistrés directement dans le système

---

### 4️⃣ Transmission des Résultats - Laboratoire envoie les résultats

**Acteur:** Responsable laboratoire / Technicien  
**Écran:** `LaboratoryScreen` → Tab "En cours" → Bouton "Ajouter les résultats"

#### Processus:
1. Le responsable du laboratoire ouvre la demande en cours
2. Il clique sur **"Ajouter les résultats"**
3. Pour chaque examen, il saisit:
   - **Nom de l'examen**
   - **Résultat** (valeur numérique ou texte)
   - **Valeur min/max** (si applicable)
   - **Unité** (mg/dL, etc.)
4. Il valide

#### Données créées:
```dart
ExamResultModel {
  id: 'RES-XXX',
  examName: 'NFS',
  resultat: '4.5',
  valeurMin: '4.0',
  valeurMax: '5.5',
  unite: '10^9/L',
  interpretation: 'normal',
  dateResultat: DateTime.now()
}
```

#### Statut: `ExamRequestStatus.completed`

---

### 5️⃣ Notification et Consultation - Patient et Médecin reçoivent les résultats

**Acteurs:** Patient & Médecin  
**Localisation des résultats:**
- **Patient:** Dossier médical → Section "Examens"
- **Médecin:** Consultations patient → Historique → Résultats

#### Actions:
- Le patient reçoit une **notification** que ses résultats sont disponibles
- Le médecin reçoit une **notification** des résultats
- Les deux peuvent **consulter les résultats** au format PDF/image/texte
- Le médecin peut prescrire un **traitement** en fonction des résultats

---

## 📊 Mapping Spécialité → Laboratoire → Examens

Voir le fichier `LaboratoryExamMapping` dans `laboratory_model.dart` pour la liste complète.

### Exemple: Biologie médicale

```dart
'Biologie médicale' → {
  laboratoire: 'Laboratoire d\'analyses médicales',
  type: 'Biologie médicale',
  examens: [
    'NFS',
    'Glycémie',
    'Bilan lipidique',
    'Ionogramme',
    'Analyse d\'urine',
    'Bilan hépatique',
    'Bilan rénal'
  ]
}
```

---

## 🏥 Laboratoires Disponibles

| Spécialité | Laboratoire | Examens Principaux |
|-----------|------------|-------------------|
| Biologie médicale | Laboratoire d'analyses médicales | NFS, Glycémie, Bilan lipidique, ... |
| Biochimie | Laboratoire de biochimie | Urée, Créatinine, ALAT, ASAT, CRP, ... |
| Hématologie | Laboratoire d'hématologie | NFS, VS, Groupe sanguin, TP/TCA |
| Microbiologie | Laboratoire microbiologique | ECBU, Hémoculture, Coproculture, ... |
| Radiologie / Imagerie | Service d'imagerie médicale | Radiographie, Scanner, IRM, Échographie, ... |
| Cardiologie | Explorations fonctionnelles | ECG, Échocardiographie, Holter ECG, ... |
| Neurologie | Neurophysiologie | EEG, EMG, IRM cérébrale |
| Et 24 autres spécialités... | ... | ... |

---

## 📱 Écrans et Routes

### Écrans Médecin:
- **Prescrire un examen:** `/medecin/prescribe-exam`
  - Classe: `PrescribeExamScreen`
  - Action: Médecin crée une demande d'examen
  
### Écrans Laboratoire:
- **Laboratoire (Accueil):** `/laboratory`
  - Classe: `LaboratoryScreen`
  - Tabs:
    - **En attente**: Nouvelles demandes à accepter
    - **En cours**: Demandes acceptées en cours de traitement
    - **Complétées**: Examens finalisés
    - **Historique**: Tous les anciens examens

---

## 🔐 Statuts d'une Demande d'Examen

```dart
enum ExamRequestStatus {
  pending,      // ⏳ En attente (vient d'être créée)
  inProgress,   // 🔄 En cours (le laboratoire traite)
  completed,    // ✅ Complétée (résultats disponibles)
  cancelled,    // ❌ Annulée
}
```

---

## 📨 Notifications Prévisionnelles

À implémenter ultérieurement:

1. **Patient recoit notification:** "Vos résultats d'examen sont disponibles"
2. **Médecin reçoit notification:** "Résultats de l'examen du patient [Nom]"
3. **Laboratoire reçoit notification:** "Nouvelle demande d'examen de Dr. [Nom]"

---

## 🗂️ Fichiers et Classes Clés

### Models:
- **`exam_request_model.dart`**
  - `ExamRequestModel`: Représente une demande d'examen
  - `ExamRequestStatus`: États de la demande
  - `ExamResultModel`: Représente un résultat d'examen

- **`laboratory_model.dart`**
  - `LaboratoryExamMapping`: Mapping spécialité → laboratoire → examens
  - `LaboratoryInfo`: Infos sur un laboratoire
  - `LaboratoryModel`: Modèle complet d'un laboratoire

### Écrans:
- **`prescribe_exam_screen.dart`** (`lib/screens/medecin/`)
  - Interface de prescription pour les médecins

- **`laboratory_screen.dart`** (`lib/screens/laboratory/`)
  - Interface de gestion du laboratoire

### Constants:
- **`app_constants.dart`**
  - `AppConstants.specialites`: Toutes les spécialités
  - `AppRoutes.laboratoryHome`: Routes du laboratoire
  - `AppRoutes.medecinPrescribeExam`: Route prescription

---

## 🚀 À Faire

- [ ] Implémenter la persistence en base de données
- [ ] Ajouter les notifications push
- [ ] Créer des rapports pour le laboratoire
- [ ] Implémenter l'export PDF des résultats
- [ ] Ajouter les alertes critiques (résultats anormaux)
- [ ] Système de traçabilité complète
- [ ] Interface d'authentification pour le laboratoire
- [ ] Intégration des dispositifs de laboratoire (lecteurs de codes-barres, etc.)
- [ ] Historique d'audit complet

---

## 🔗 Intégration Dossier Médical

L'ensemble des examens et résultats sont intégrés dans le `DossierMedicalModel`:

```dart
class DossierMedicalModel {
  final List<ExamenModel> examens; // Examens réalisés
  final List<OrdonnanceModel> ordonnances; // Traitements prescrits
  ...
}
```

Chaque résultat d'examen est stocké dans `ExamenModel` et disponible dans l'historique du patient.
