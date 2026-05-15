# 🔗 Guide d'Accès - Section Laboratoire

## 📱 Comment Accéder à la Section Laboratoire

---

### **1. Pour l'ADMINISTRATEUR** ✅

#### Via l'application web/mobile:
1. **Se connecter** avec le rôle **Administrator**
2. Dans le bas de l'écran, cliquer sur l'onglet **Laboratoire** (nouvel onglet avec icône 🧪)
3. Vous verrez l'interface de gestion du laboratoire

#### Ou directement:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const LaboratoryScreen(),
  ),
);
```

**Emplacement:** `lib/screens/admin/admin_home_screen.dart`  
**Route:** `/laboratory`  
**Navigation:** Tab #3 (après Stock, avant Rapports)

---

### **2. Pour le MÉDECIN GÉNÉRALISTE** ✅

#### Via l'application:
1. **Se connecter** avec le rôle **Médecin**
2. Dans le Dashboard (page d'accueil), vous verrez une carte **"Prescrire un examen"**
3. Cliquer sur cette carte pour prescrire un examen
4. Remplir le formulaire et envoyer la demande

#### Ou naviguer directement:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => PrescribeExamScreen(
      patientId: 'P123',
      patientNom: 'Aminata Sow',
      medecinId: 'M456',
      medecinNom: 'Dr. Fatou Diop',
    ),
  ),
);
```

**Emplacement:** `lib/screens/medecin/prescribe_exam_screen.dart`  
**Route:** `/medecin/prescribe-exam`  
**Accès:** Carte d'accès rapide dans le Dashboard

---

## 🎯 Les Deux Interfaces Principales

### \`\`🏥 INTERFACE LABORATOIRE\`\`

**Qui y accède:** Administrateur / Responsable Laboratoire  
**Pour:** Gérer les demandes d'examens

**Fonctionnalités:**
- **Tab 1: En attente** 
  - Voir les nouvelles demandes
  - Bouton "Accepter la demande"
  
- **Tab 2: En cours**
  - Voir les demandes acceptées
  - Bouton "Ajouter les résultats"
  
- **Tab 3: Complétées**
  - Voir les examens finalisés
  
- **Tab 4: Historique**
  - Rechercher d'anciens examens

---

### 👨‍⚕️ **INTERFACE PRESCRIPTION**

**Qui y accède:** Médecin généraliste  
**Pour:** Prescrire des examens au laboratoire

**Étapes:**
1. **Sélectionner spécialité** (ex: Biologie médicale)
2. **Laboratoire s'affiche automatiquement** (Laboratoire d'analyses médicales)
3. **Sélectionner les examens** (NFS, Glycémie, etc.)
4. **Définir l'urgence** (Normal, Urgent, Très urgent)
5. **Ajouter des observations** (optionnel)
6. **Envoyer la demande** (Laboratoire reçoit automatiquement)

---

## 📊 Flux Complet de Données

```
Médecin Généraliste
     ↓ (Prescrit examen)
PrescribeExamScreen
     ↓ (Crée demande)
ExamRequestModel (Status: pending)
     ↓ (Saumise automatique)
Administrateur voit dans "En attente"
     ↓ (Accepte)
Status: inProgress
     ↓ (Laboratoire réalise examen)
     ↓ (Saisit résultats)
ExamResultModel
     ↓ (Marque complétée)
Status: completed
     ↓ (Notification)
Patient + Médecin voient résultats
```

---

## 🔐 Accès Selon le Rôle

| Rôle | Accès | Interface |
|------|-------|-----------|
| **Patient** | ❌ Pas d'accès (Consultation seulement) | Dossier médical → Examens |
| **Médecin** | ✅ Prescrire | PrescribeExamScreen |
| **Admin** | ✅ Gérer | LaboratoryScreen (Tab) |
| **Laboratoire** | ✅ Gérer | LaboratoryHomeScreen |

---

## 📋 Utilisation Rapide

### **Médecin - Prescrire un examen:**

```dart
// 1. Naviguer vers l'écran
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => PrescribeExamScreen(
      patientId: patient.id,
      patientNom: patient.nom,
      medecinId: medecin.id,
      medecinNom: medecin.nom,
    ),
  ),
);

// 2. L'écran affiche:
// - Dropdown des 35 spécialités
// - Laboratoire automatique (ex: "Laboratoire d'analyses médicales")
// - Checkboxes des examens disponibles
// - Bouton "Envoyer la demande"
```

### **Admin - Voir les demandes:**

```dart
// L'écran LaboratoryScreen s'affiche automatiquement
// - Tab "En attente": 5 demandes en attente
// - Tab "En cours": 3 demandes en traitement
// - Tab "Complétées": 12 examens terminés
// - Tab "Historique": Tous les anciens examens
```

---

## 🚀 Tests Rapides

### Test 1: Médecin prescrit un examen
1. Connexion avec rôle **Médecin**
2. Dashboard → Cliquer "Prescrire un examen"
3. Sélectionner "Biologie médicale"
4. Sélectionner: NFS, Glycémie
5. Urgence: Normal
6. Envoyer → Message de confirmation

### Test 2: Admin reçoit la demande
1. Connexion avec rôle **Admin**
2. Cliquer tab **Laboratoire**
3. Tab "En attente" → Voir la demande
4. Cliquer "Accepter la demande"
5. Demande passe en "En cours"

### Test 3: Admin ajoute résultats
1. Dans tab "En cours"
2. Cliquer "Ajouter les résultats"
3. Saisir: NFS = 4.5, Glycémie = 1.10
4. Enregistrer
5. Demande passe en "Complétée"

---

## 📁 Fichiers Impliqués

**Modèles:**
- `lib/models/exam_request_model.dart` - Demande d'examen
- `lib/models/laboratory_model.dart` - Laboratoire & Mapping

**Écrans:**
- `lib/screens/laboratory/laboratory_screen.dart` - Interface admin
- `lib/screens/medecin/prescribe_exam_screen.dart` - Interface médecin
- `lib/screens/admin/admin_home_screen.dart` - Integration tab laboratoire
- `lib/screens/medecin/medecin_home_screen.dart` - Accès rapide

**Constants:**
- `lib/core/constants/app_constants.dart` - Routes & spécialités

---

## ❓ Questions Fréquentes

**Q: Comment accéder au laboratoire si je suis patient?**  
A: Les patients ne voient que leurs résultats dans leur Dossier Médical. Ils ne gèrent pas les examens.

**Q: Où vont les résultats après que le laboratoire les ajoute?**  
A: Ils vont dans le Dossier Médical du patient, section "Examens".

**Q: Comment changer l'urgence?**  
A: Pendant la prescription, sélectionner Normal/Urgent/Très urgent avant d'envoyer.

**Q: Puis-je modifier une demande après l'envoi?**  
A: Non, il faut l'annuler et en créer une nouvelle.

---

## 📞 Support

Pour des questions sur l'implémentation:
- Consultez: `doc/EXAM_LABORATORY_FLOW.md`
- Ou: `IMPLEMENTATION_SUMMARY.md`
