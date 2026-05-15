# 📋 Guide Médecin - Accès Rapides aux Patients

## 🎯 Les 3 Actions Rapides (dans le détail patient)

Quand tu cliques sur un patient dans la liste du dashboard, un modal s'ouvre avec 3 boutons d'action rapide:

---

## 1️⃣ **CONSULTATION** 📝
**Icon:** Document avec un plus  
**Couleur:** Bleu primaire

### Qu'est-ce que c'est?
Créer une **nouvelle consultation complète** avec le patient:
- Motif de la visite
- Examen clinique
- Diagnostic
- Prescriptions générales

### Flux:
```
1. Clique "Consultation"
2. S'ouvre ConsultationScreen
3. Remplir tous les onglets:
   - Motif (symptômes, raison de visite)
   - Examen (constantes vitales)
   - Diagnostic (diagnostic médical)
   - Traitement (ordonnance OU examens complémentaires)
4. Clique "Valider et signer la consultation"
5. Consultation sauvegardée au dossier du patient
```

### Exemple d'utilisation:
- Patient vient pour une consultation générale
- Tu veux documenter la visite complète
- Inclure motif, diagnostic, et proposer examen ou médicament

---

## 2️⃣ **ORDONNANCE** 💊
**Icon:** Reçu  
**Couleur:** Violet secondaire

### Qu'est-ce que c'est?
Prescrire rapidement des **médicaments/traitement** au patient:
- Nom du médicament
- Dosage (ex: 500mg)
- Posologie (ex: 2x/jour)
- Durée (ex: 7 jours)

### Flux:
```
1. Clique "Ordonnance"
2. S'ouvre PrescribeOrdonnanceScreen
3. Ajouter médicaments (formulaire rapide)
4. Voir lista de médicaments ajoutés
5. Clique "Prescrire l'ordonnance"
6. Confirmation + notification au patient
7. Ordonnance sauvegardée
```

### Exemple d'utilisation:
- Patient a besoin d'un antibiotique
- Tu veux prescrire rapidement sans consultation complète
- Simple et rapide: ajouter médicament → prescrire → envoyé

---

## 3️⃣ **EXAMEN** 🔬
**Icon:** Beaker/éprouvette  
**Couleur:** Cyan info

### Qu'est-ce que c'est?
Prescrire rapidement des **examens/analyses** à faire au patient:
- Spécialité (Cardiologie, Radiologie, Biologie, etc.)
- Examens spécifiques
- Urgence (Normal, Urgent, Très urgent)
- Observations

### Flux:
```
1. Clique "Examen"
2. S'ouvre PrescribeExamScreen
3. Sélectionner spécialité
4. Laboratoire auto-assigné
5. Cocher examens voulus
6. Sélectionner urgence
7. Clique "Envoyer la demande"
8. Confirmation + notifications:
   - Patient notifié
   - Laboratoire reçoit demande
9. Examen visible dans LaboratoryScreen
```

### Exemple d'utilisation:
- Patient a besoin d'une analyse sanguine
- Tu veux ordonner rapidement sans consultation complète
- Spécialité Biologie → examens disponibles → prescrire

---

## 📊 Différences Clés

| Feature | Consultation | Ordonnance | Examen |
|---------|-------------|-----------|--------|
| **Objectif** | Visite complète | Traitement/Médocs | Analyses |
| **Durée** | 5-10 min | 2-3 min | 2-3 min |
| **Données** | Motif, diagnostic, tout | Juste médicaments | Juste examen |
| **Écran** | ConsultationScreen | PrescribeOrdonnanceScreen | PrescribeExamScreen |
| **Onglets** | 4 onglets | Formulaire unique | Formulaire unique |
| **Sauvegarde** | Consultation complète | Ordonnance | ExamRequest |

---

## ✅ Comment Accéder aux 3 Actions

### Depuis le Dashboard Médecin:
1. **Voyez vos patients** dans "Mes patients récents"
2. **Cliquez sur un patient** dans la liste
3. **Modal s'ouvre** avec 3 boutons:
   - 📝 Consultation
   - 💊 Ordonnance
   - 🔬 Examen

### Ou depuis Recherche:
1. **Cliquez le bouton recherche** (magnifying glass icon)
2. **Cherchez le patient** (par ID ou nom)
3. **Accédez son dossier complet** (DoctorPatientDossierScreen)
4. **Onglet Examens:** "+ Prescrire un examen"

---

## 🔔 Notifications

Après chaque action, le patient reçoit une notification:

### Consultation:
- ✓ Patient voit "Consultation créée"
- ✓ Historique mis à jour

### Ordonnance:
- ✓ Patient reçoit ordonnance
- ✓ Peut voir médicaments prescrits

### Examen:
- ✓ Patient notifié "Examen prescrit"
- ✓ Laboratoire reçoit demande immédiatement
- ✓ Patient peut voir examen en attente

---

## 🎯 Cas d'Usage Typiques

### Cas 1: Consultation de suivi complet
```
Patient: "Je viens pour suivi hypertension"
→ Action: CONSULTATION
→ Remplir motif, examen (tension), diagnostic
→ Prescrire médicament OU examen depuis consultation
```

### Cas 2: Prescrire rapide antibiotique
```
Patient: "J'ai une infection"
Toi: "Je dois prescrire antibiotique"
→ Action: ORDONNANCE
→ Ajouter Amoxicilline 500mg
→ Prescrire directement
```

### Cas 3: Ordonner analyse pour diagnostic
```
Patient: "Je ne me sens pas bien"
Toi: "J'ai besoin d'une prise de sang"
→ Action: EXAMEN
→ Sélectionner Biologie
→ Cocher "Bilan sanguin"
→ Prescrire
```

---

## ⚠️ Important

- **Les 3 actions sont INDÉPENDANTES**: tu peux faire une ordonnance SANS consultation
- **Notifications IMMÉDIATES**: patient reçoit tout de suite
- **Traçabilité**: tout est sauvegardé au dossier du patient
- **Peut être accédé DEPUIS le modal**: clique patient → bouton action
- **OU depuis le dossier**: recherche patient → onglet Examens → prescrire

---

## 🚀 Flux Général Médecin

```
DASHBOARD Médecin
    ↓
Clique sur patient
    ↓
MODAL Patient avec 3 Actions
    ├─→ 📝 CONSULTATION (visite complète)
    ├─→ 💊 ORDONNANCE (médicaments)
    └─→ 🔬 EXAMEN (analyses/imaging)

2° Alternative: RECHERCHE Patient
    ↓
Cherche patient (ID/Nom)
    ↓
Accès DOSSIER COMPLET
    ↓
Onglet "Examens"
    ↓
"+ Prescrire un examen"
```

---

**Tous les 3 flux sont maintenant 100% opérationnels! 🎉**
