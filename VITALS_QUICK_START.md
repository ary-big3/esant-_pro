# 🚀 Guide de Démarrage Rapide - Constantes Vitales

## 👩‍⚕️ Pour l'Infirmière

### 1️⃣ Accéder à la Gestion des Constantes

```
Menu Principal → Espace Infirmière → Constantes Vitales
```

### 2️⃣ Enregistrer les Constantes d'un Patient

**Onglet : Saisie des constantes**

| Champ | Comment remplir | Exemple |
|-------|-----------------|---------|
| **ID Patient** | Numéro unique du patient | 123 |
| **Température** | En Celsius | 37.2 |
| **TA Systolique** | Chiffre supérieur (mmHg) | 120 |
| **TA Diastolique** | Chiffre inférieur (mmHg) | 80 |
| **Fréquence Cardiaque** | Battements par minute | 72 |
| **Fréquence Respiratoire** | Respirations par minute | 16 |
| **Saturation O₂** | Pourcentage | 98 |
| **Poids** | En kilogrammes | 70 |
| **Taille** | En centimètres | 175 |
| **Notes** | Observations personnelles | "Patient stable" |

✅ L'**IMC sera calculé automatiquement**

🎨 **Codes couleur de l'IMC :**
- 🔵 Bleu : Insuffisant (< 18.5)
- 🟢 Vert : Normal (18.5 - 25)
- 🟠 Orange : Surpoids (25 - 30)
- 🔴 Rouge : Obésité (> 30)

### 3️⃣ Actions après Enregistrement

```
✅ Cliquer "Enregistrer" 
   ↓
💚 Message de confirmation 
   ↓
🔄 Constantes apparaissent dans l'Historique
```

### 4️⃣ Consulter l'Historique

**Onglet : Historique**

- Voir toutes les mesures enregistrées
- 📅 Triées par date (plus récente d'abord)
- 👀 Affichage en tableau + cartes détaillées

### 5️⃣ Modifier une Constante

```
1. Aller à l'onglet "Historique"
2. Cliquer sur ✏️ "Modifier" sur une mesure
3. Le formulaire se remplira automatiquement
4. Modifier les valeurs souhaitées
5. Cliquer "Valider"
```

### 6️⃣ Supprimer une Constante

```
1. Aller à l'onglet "Historique"
2. Cliquer sur 🗑️ "Supprimer" sur une mesure
3. Confirmer la suppression
✅ Mesure supprimée définitivement
```

---

## 👤 Pour le Patient

### 1️⃣ Consulter mes Constantes Vitales

**Via le Dossier Médical :**
```
Menu → Dossier Médical → Constantes Vitales
```

### 2️⃣ Comprendre les Constantes

| Constante | Signification | Plage Normale |
|-----------|---------------|---------------|
| **Température** | Chaleur du corps | 36.5 - 37.5°C |
| **TA (Tension Artérielle)** | Pression du sang | 90-140 / 60-90 |
| **FC (Fréquence Cardiaque)** | Battements/minute | 60 - 100 bpm |
| **FR (Fréquence Respiratoire)** | Respirations/minute | 12 - 20 rpm |
| **O₂ (Oxygène)** | Saturation en O₂ | ≥ 95% |

### 3️⃣ Voir les Dernières Constantes

La section **"Dernières Constantes"** affiche :
- ⏰ Date et heure
- 📊 Tous les paramètres en un coup d'œil
- 📝 Notes de l'infirmière (le cas échéant)

### 4️⃣ Consulter l'Historique

La section **"Historique"** montre :
- 📈 Toutes les mesures précédentes
- 📅 Organisées par date
- 🔄 Cliquer "Voir détails" pour plus d'info

### 5️⃣ Interpréter les Couleurs

```
🟢 VERT = Normal ✅
🟠 ORANGE = À surveiller ⚠️
🔴 ROUGE = Anormal ❌
```

---

## 👨‍⚕️ Pour le Docteur

### 1️⃣ Accéder aux Constantes d'un Patient

```
Menu → Patients → Sélectionner patient 
   → Constantes Vitales
```

### 2️⃣ Analyser les Constantes

**Vue Synthétique :**
- Dernière mesure mise en évidence
- Codes couleur pour identification rapide
- ⚠️ Anomalies évidentes

**Vue Détaillée :**
- Historique complet
- Tendances (augmentation/diminution)
- Notes de l'infirmière

### 3️⃣ Actions Possibles

- ✅ Consulter l'historique
- 📊 Analyser les tendances
- 📝 Ajouter notes médicales
- 🚨 Alerter si anomalies

---

## ⚡ Raccourcis Clavier

| Raccourci | Action |
|-----------|--------|
| `Enter` | Enregistrer / Valider |
| `Esc` | Annuler / Fermer |
| `Tab` | Aller au champ suivant |
| `F5` | Rafraîchir les données |

---

## 🆘 Aide Rapide

### Erreur : "ID Patient invalide"
- ✅ Vérifier que l'ID patient existe
- ✅ Entrer un numérique valide
- ✅ Pas d'espaces avant/après

### Erreur : "Température invalide"
- ✅ Plage acceptable : 35°C à 43°C
- ✅ Utiliser les décimales si nécessaire (37.2)

### Erreur : "Vous n'avez pas accès"
- ✅ Vérifier votre rôle (doit être Infirmière)
- ✅ Vous ne pouvez modifier que vos propres mesures

### Les données ne s'affichent pas
- 🔄 Rafraîchir la page (F5)
- 📡 Vérifier la connexion Internet
- 🔑 Vérifier l'authentification

### La modification n'a pas marché
- ✅ Vérifier que c'est votre mesure
- ✅ Vérifier les valeurs (plages valides)
- 🔄 Réessayer après rafraîchissement

---

## 📋 Checklist Infirmière

Avant d'enregistrer, vérifier :

- [ ] **ID Patient valide**
- [ ] **Température prise correctement**
- [ ] **TA mesurée aux deux bras**
- [ ] **FC prise en repos (si possible)**
- [ ] **Saturation O₂ à doigt propre**
- [ ] **Poids et taille vérifiés**
- [ ] **Notes claires et précises**
- [ ] **Tous les champs requis remplis**

---

## 🎯 Normes de Santé

### Valeurs Normales

| Paramètre | Enfant | Adulte | Personne Âgée |
|-----------|--------|--------|---------------|
| **Température** | 37-38°C | 36.5-37.5°C | 36.5-37°C |
| **TA Systolique** | 95-105 | 90-120 | 120-140 |
| **TA Diastolique** | 60-70 | 60-80 | 60-90 |
| **FC** | 70-100 | 60-100 | 60-80 |
| **FR** | 20-30 | 12-20 | 12-18 |

### Drapeaux Rouges ⚠️

- Température > 38.5°C ou < 35°C
- TA Systolique > 160 ou < 80
- FC > 120 ou < 50
- FR > 30 ou < 8
- O₂ < 92%

---

## 📱 Interface Responsive

L'application fonctionne sur :
- 📱 Téléphone
- 📱 Tablette
- 💻 Ordinateur de bureau

Toutes les fonctionnalités sont accessibles sur tous les appareils.

---

## 🔐 Sécurité des Données

- ✅ Données chiffrées en transit (HTTPS)
- ✅ Authentification par token JWT
- ✅ Accès contrôlé par rôle
- ✅ Journalisation de toutes les actions
- ✅ Conformité RGPD

---

## 📞 Support

**Besoin d'aide ?**

1. Consultez la section **Aide Rapide**
2. Vérifiez votre rôle et permissions
3. Contactez le Support IT
4. Envoyez un rapport d'erreur

**Informations utiles à donner au support :**
- Date/heure du problème
- Message d'erreur exact
- Navigateur utilisé
- Version de l'application

---

## 🎓 Formation Rapide

### Pour l'Infirmière (5 min)
1. Accéder à l'interface (1 min)
2. Enregistrer une constante (2 min)
3. Modifier une constante (1 min)
4. Supprimer une constante (1 min)

### Pour le Patient (3 min)
1. Accéder à ses constantes (1 min)
2. Comprendre les paramètres (1 min)
3. Interpréter les résultats (1 min)

### Pour le Docteur (5 min)
1. Accéder aux constantes d'un patient (2 min)
2. Analyser l'historique (2 min)
3. Déterminer les anomalies (1 min)

---

## 💡 Tips & Tricks

### Pour l'Infirmière
```
💡 Conseil : Enregistrer les constantes immédiatement après la mesure
💡 Conseil : Utiliser les notes pour context (ex: avant/après repas)
💡 Conseil : Vérifier l'IMC automatiquement avant d'enregistrer
```

### Pour le Patient
```
💡 Conseil : Consulter régulièrement les constantes vitales
💡 Conseil : Noter tout changement significatif
💡 Conseil : Partager avec votre docteur avant la consultation
```

### Pour le Docteur
```
💡 Conseil : Comparer l'historique pour voir les tendances
💡 Conseil : Alerter infirmière pour anomalies récurrentes
💡 Conseil : Utiliser dans les décisions diagnostiques
```

---

## 📈 Prochaines Fonctionnalités

- 📊 Graphiques de tendances
- 🚨 Alertes automatiques
- 📄 Export PDF/Excel
- 🔔 Notifications
- 📲 App mobile native

---

**Dernière mise à jour :** 29 avril 2026
**Version :** 1.0.0
**Status :** ✅ Production Ready
