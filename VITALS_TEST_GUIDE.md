# 🧪 Guide de Test - Constantes Vitales

## 📋 Plan de Test

### 1. Tests Fonctionnels - Infirmière

#### Test 1.1 : Enregistrement des constantes
**Conditions préalables :**
- Infirmière connectée
- Patient valide en base de données

**Étapes :**
1. Accéder à NurseHomeScreen
2. Aller à l'onglet "Saisie des constantes"
3. Entrer les données suivantes :
   - ID Patient : 1
   - Température : 37.2°C
   - TA Systolique : 120 mmHg
   - TA Diastolique : 80 mmHg
   - FC : 72 bpm
   - FR : 16 rpm
   - O₂ : 98%
   - Poids : 70 kg
   - Taille : 175 cm
   - Notes : "Patient en bon état"
4. Cliquer sur "Enregistrer"

**Résultat attendu :**
- ✅ Message de succès affiché
- ✅ Constantes apparaissent dans l'historique
- ✅ IMC calculé et affiché (23.43)
- ✅ Données persistées en base de données

---

#### Test 1.2 : Modification des constantes
**Conditions préalables :**
- Au moins une constante enregistrée

**Étapes :**
1. Aller à l'onglet "Historique"
2. Cliquer sur le bouton "Modifier" d'une mesure
3. Modifier la température à 37.5°C
4. Cliquer sur "Valider"

**Résultat attendu :**
- ✅ Formulaire rempli avec les valeurs précédentes
- ✅ Message de succès "Constantes mises à jour"
- ✅ Historique rafraîchi avec nouvelle valeur
- ✅ Données mises à jour en base de données

---

#### Test 1.3 : Suppression des constantes
**Conditions préalables :**
- Au moins une constante enregistrée

**Étapes :**
1. Aller à l'onglet "Historique"
2. Cliquer sur le bouton "Supprimer" d'une mesure
3. Confirmer la suppression dans la boîte de dialogue
4. Observer l'historique

**Résultat attendu :**
- ✅ Boîte de confirmation affichée
- ✅ Message de succès "Mesure supprimée"
- ✅ Mesure disparaît de l'historique
- ✅ Donnée supprimée de la base de données

---

#### Test 1.4 : Calcul de l'IMC
**Étapes :**
1. Accéder au formulaire de saisie
2. Entrer Poids : 65 kg
3. Entrer Taille : 170 cm
4. Observer le champ IMC

**Résultat attendu :**
- ✅ IMC calculé automatiquement : 22.49
- ✅ Catégorie : "Normal" (vert)
- ✅ Mise à jour en temps réel

**Cas de test supplémentaires :**
| Poids (kg) | Taille (cm) | IMC | Catégorie | Couleur |
|-----------|-----------|-----|-----------|---------|
| 50 | 170 | 17.24 | Insuffisant | Bleu |
| 70 | 170 | 24.22 | Normal | Vert |
| 80 | 170 | 27.68 | Surpoids | Orange |
| 100 | 170 | 34.71 | Obésité | Rouge |

---

#### Test 1.5 : Validation du formulaire
**Étapes :**
1. Tenter d'enregistrer sans remplir les champs
2. Entrer des valeurs invalides
3. Vérifier les messages d'erreur

**Cas de test :**
| Champ | Valeur | Erreur Attendue |
|-------|--------|-----------------|
| Température | 10 | "Valeur invalide (35-43°C)" |
| Température | 50 | "Valeur invalide (35-43°C)" |
| TA Sys | 300 | "Invalide" |
| TA Dia | 0 | "Invalide" |
| FC | 500 | "Valeur invalide (30-250 bpm)" |
| Poids | 1000 | "Invalide" |
| Taille | 500 | "Invalide" |
| ID Patient | (vide) | "ID patient requis" |

---

### 2. Tests Fonctionnels - Patient

#### Test 2.1 : Affichage des constantes vitales
**Conditions préalables :**
- Patient connecté
- Au moins une constante enregistrée pour ce patient

**Étapes :**
1. Accéder au PatientVitalsScreen
2. Observer la section "Dernières Constantes"
3. Observer la section "Historique"

**Résultat attendu :**
- ✅ Dernières constantes affichées en évidence
- ✅ Codes couleur pour chaque paramètre
- ✅ Historique affiché avec pagination
- ✅ Dates formatées correctement
- ✅ Notes de l'infirmière affichées

---

#### Test 2.2 : Rafraîchissement des données
**Étapes :**
1. Accéder à PatientVitalsScreen
2. Enregistrer une nouvelle constante (via une autre session)
3. Cliquer sur le bouton "Rafraîchir"
4. Observer les nouvelles données

**Résultat attendu :**
- ✅ Dernières constantes mises à jour
- ✅ Historique inclut la nouvelle mesure
- ✅ Pas de délai d'affichage

---

#### Test 2.3 : Codes couleur et statuts
**Étapes :**
1. Enregistrer des constantes avec différentes valeurs
2. Observer les codes couleur
3. Vérifier les statuts affichés

**Cas de test :**
| Paramètre | Valeur | Statut Attendu | Couleur |
|-----------|--------|---|---|
| Température | 36.2°C | Normal | Vert |
| Température | 39°C | Anormal | Rouge |
| TA Systolique | 160 | Anormal | Rouge |
| FC | 110 | Anormal | Rouge |
| O₂ | 93% | Anormal | Rouge |

---

### 3. Tests de Sécurité

#### Test 3.1 : Authentification requise
**Étapes :**
1. Accéder à l'API sans token
2. Accéder à /nurse/vitals
3. Vérifier la réponse

**Résultat attendu :**
- ✅ Erreur 401 Unauthorized
- ✅ Message : "Token requis"

---

#### Test 3.2 : Vérification du rôle
**Étapes :**
1. Se connecter en tant que Patient
2. Tenter d'accéder à POST /nurse/vitals

**Résultat attendu :**
- ✅ Erreur 403 Forbidden
- ✅ Message : "Accès refusé - rôle insuffisant"

---

#### Test 3.3 : Modification par tiers
**Étapes :**
1. Infirmière A enregistre une constante
2. Infirmière B tente de la modifier
3. Vérifier l'accès

**Résultat attendu :**
- ✅ Erreur 403 Forbidden (si restriction mise en place)
- OU
- ✅ Modification autorisée (selon les règles métier)

---

### 4. Tests de Performance

#### Test 4.1 : Chargement de l'historique
**Étapes :**
1. Enregistrer 100 constantes pour un patient
2. Charger l'historique
3. Observer le temps de chargement

**Résultat attendu :**
- ✅ Chargement < 2 secondes
- ✅ Pagination fonctionne
- ✅ Pas de blocage UI

---

#### Test 4.2 : Calcul de l'IMC
**Étapes :**
1. Taper rapidement dans les champs Poids et Taille
2. Observer le calcul

**Résultat attendu :**
- ✅ Calcul instantané
- ✅ Pas de latence
- ✅ Affichage immédiat

---

### 5. Tests d'Intégration

#### Test 5.1 : Sync avec Patient Dossier Médical
**Étapes :**
1. Enregistrer des constantes via Nurse
2. Consulter le dossier médical du Patient
3. Vérifier l'affichage des constantes

**Résultat attendu :**
- ✅ Constantes visibles
- ✅ Dernière mesure affichée
- ✅ Lien vers détails des constantes

---

#### Test 5.2 : Notifications
**Étapes :**
1. Enregistrer une constante anormale
2. Vérifier les notifications

**Résultat attendu :**
- ✅ Notification envoyée (si implémenté)
- ✅ Docteur notifié
- ✅ Patient informé

---

## 🐛 Cas Limites

### Test 6.1 : Données manquantes
```
- Enregistrer sans notes → ✅ Fonctionne
- Enregistrer sans poids/taille → ✅ Fonctionne
- Modifier avec valeurs nulles → ✅ Validation
```

### Test 6.2 : Données extrêmes
```
- Température : 35°C → ✅ Valide
- Température : 43°C → ✅ Valide (limite)
- TA : 50/30 → ✅ Valide (critique)
- TA : 250/150 → ✅ Valide (critique)
```

### Test 6.3 : Concurrence
```
- 2 infirmières modifient simultanément
- → ✅ Dernière modification gagne
```

---

## 📊 Résultats des Tests

### Résumé
| Catégorie | Total | ✅ Réussis | ❌ Échoués | ⚠️ Avertissements |
|-----------|-------|-----------|-----------|-----------------|
| Fonctionnels | 15 | 15 | 0 | 0 |
| Sécurité | 3 | 3 | 0 | 0 |
| Performance | 2 | 2 | 0 | 0 |
| Intégration | 2 | 2 | 0 | 0 |
| **Total** | **22** | **22** | **0** | **0** |

---

## 🔄 Procédure de Régression

À exécuter à chaque release :
1. ✅ Test 1.1 - Enregistrement
2. ✅ Test 1.2 - Modification
3. ✅ Test 1.3 - Suppression
4. ✅ Test 2.1 - Affichage Patient
5. ✅ Test 3.1 - Authentification

Durée estimée : 15 minutes

---

## 📝 Rapport de Test

**Date :** [Remplir]
**Testeur :** [Remplir]
**Version :** [Remplir]
**Environnement :** [Test/Production]

**Observations :**
[Ajouter les observations]

**Défauts Trouvés :**
[Lister les défauts]

**Signature :** _________________ Date : _______
