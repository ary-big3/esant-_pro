# 🏥 GUIDE D'ACCÈS INFIRMIÈRE - CONSTANTES VITALES

## 👩‍⚕️ Vue d'ensemble

Cette section permet aux infirmières et infirmiers d'enregistrer les constantes vitales des patients et de maintenir un historique médical complet et à jour.

---

## 📋 Fonctionnalités principales

### 1. 🔍 Recherche du patient
- **Entrer l'ID du patient** dans le champ de recherche
- L'application récupère automatiquement les informations du patient
- Affiche le profil patient avec photo, groupe sanguin, taille et poids

### 2. 📊 Enregistrement des constantes vitales

Les infirmières peuvent enregistrer les 6 constantes principales:

| Constante | Unité | Plage normale |
|-----------|-------|--------------|
| **Température** | °C | 36.5 - 37.5 |
| **Tension Artérielle (TA)** | mmHg | 90-120 / 60-80 |
| **Fréquence Cardiaque (FC)** | bpm | 60 - 100 |
| **Fréquence Respiratoire (FR)** | rpm | 12 - 20 |
| **Saturation en Oxygène (O₂)** | % | 95 - 100 |
| **Poids** | kg | Selon patient |
| **Taille** | cm | Selon patient |

#### Champs obligatoires:
- ✅ Température
- ✅ Tension Systolique
- ✅ Tension Diastolique
- ✅ Fréquence Cardiaque
- ✅ Fréquence Respiratoire
- ✅ Saturation en Oxygène

#### Champs optionnels:
- ⏳ Poids
- ⏳ Taille
- ⏳ Notes (observations supplémentaires)

### 3. 📈 Historique des constantes

L'onglet "Historique" affiche:
- **Liste chronologique** des enregistrements précédents
- **Date et heure** de chaque enregistrement
- **Affichage en grille** des 6 principaux vitaux
- **Calcul automatique de l'IMC** (si poids et taille disponibles)
- **Notes** associées à chaque enregistrement

### 4. ✏️ Modification des données

- Cliquez sur le bouton **"Modifier"** dans l'historique
- Les champs se remplissent automatiquement
- Modifiez les valeurs incorrectes
- Cliquez sur **"Mettre à jour"** pour sauvegarder

### 5. 🗑️ Suppression

- Cliquez sur le bouton **"Supprimer"** pour retirer un enregistrement
- L'historique se met à jour automatiquement

---

## 🔐 Authentification infirmière

### Identifiants partagés:
```
Rôle: Infirmière/Infirmier
Identifiant: NURSE-001 (tous les infirmiers)
Identifiant: NURSE-002 (tous les infirmiers)
```

**Note**: Tous les infirmiers utilisent les mêmes identifiants. 
Chaque enregistrement est horodaté et traçable.

---

## 📝 Flux de travail

### Étape 1: Recherche
```
1. Accéder à l'écran Infirmière
2. Entrer l'ID du patient (ex: PAT-123456)
3. Cliquer sur "Rechercher"
4. Attendre le chargement des informations
```

### Étape 2: Enregistrement
```
1. Mesurer les constantes du patient
2. Saisir les valeurs dans le formulaire
3. Ajouter les notes si nécessaire
4. Cliquer sur "Enregistrer"
5. Confirmation: "Constantes enregistrées avec succès"
```

### Étape 3: Consultation de l'historique
```
1. Aller à l'onglet "Historique"
2. Visualiser tous les enregistrements précédents
3. Comparer les tendances
4. Identifier les anomalies
```

### Étape 4: Correction (si erreur)
```
1. Localiser l'enregistrement erroné dans l'historique
2. Cliquer sur "Modifier"
3. Corriger les valeurs
4. Cliquer sur "Mettre à jour"
```

---

## 🎯 Conseils pratiques

### ✅ Bonnes pratiques:
- Enregistrer les constantes **à intervalles réguliers**
- **Ajouter des notes** si le patient a des symptômes
- **Vérifier les plages normales** avant de finaliser
- **Corriger immédiatement** les erreurs de saisie
- **Consulter l'historique** pour identifier les tendances

### ⚠️ À éviter:
- Ne pas laisser les champs obligatoires vides
- Ne pas entrer des valeurs hors de la plage possible
- Ne pas supprimer les enregistrements par erreur
- Ne pas oublier de sauvegarder après modification

---

## 📊 Structure des données

Chaque enregistrement contient:
```json
{
  "id": "VIT-1712000001",
  "patient_id": "PAT-123456",
  "nurse_id": "NURSE-001",
  "temperature": 37.2,
  "tension_systolique": 120,
  "tension_diastolique": 80,
  "frequence_cardiaque": 72,
  "frequence_respiratoire": 16,
  "satur_oxygene": 98.5,
  "poids": 75.0,
  "taille": 180.0,
  "notes": "Patient stable",
  "recorded_at": "2026-04-13T10:30:00",
  "created_at": "2026-04-13T10:30:00",
  "updated_at": null
}
```

---

## 🔗 Intégration avec le dossier patient

Les constantes vitales enregistrées sont:
- ✅ Sauvegardées dans le **dossier médical du patient**
- ✅ Accessibles par le **médecin traitant**
- ✅ Disponibles pour **la téléconsultation**
- ✅ Utilisées par les **systèmes d'alerte**
- ✅ Archivées pour **l'historique médical**

---

## 🆘 Troubleshooting

| Problème | Cause | Solution |
|----------|-------|----------|
| Patient non trouvé | ID incorrect | Vérifier l'ID du patient |
| Erreur d'enregistrement | Champ obligatoire vide | Remplir tous les champs requis |
| Les données ne se mettent pas à jour | Problème de connexion | Vérifier la connexion réseau |
| Impossible de modifier | Permissions insuffisantes | Contacter l'administration |

---

## 📞 Support

Si vous rencontrez des problèmes:
1. Vérifier votre connexion internet
2. Rafraîchir la page
3. Contacter le support technique
4. Consulter la documentation complète

---

**Dernière mise à jour**: 13 avril 2026  
**Version**: 1.0.0
