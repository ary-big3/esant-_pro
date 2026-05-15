# Guide d'Intégration - Inscriptions et Profils Patients

## 📋 Vue d'ensemble

Deux nouveaux écrans ont été créés pour gérer l'inscription et la mise à jour des profils patients :

1. **PatientRegistrationScreen** - Formulaire d'inscription complet en 3 étapes
2. **PatientEditProfileScreen** - Formulaire de modification du profil en 3 onglets

## 📁 Fichiers créés

```
lib/screens/auth/
  └── patient_registration_screen.dart    [NEW]

lib/screens/patient/
  └── patient_edit_profile_screen.dart    [NEW]
```

## 🔄 FLUX D'INSCRIPTION (PatientRegistrationScreen)

### Étape 1 : Informations de base
- Nom et Prénom
- Email (avec validation)
- Téléphone
- Adresse
- Sexe (Homme/Femme)
- Date de naissance
- Mot de passe (validation 8+ caractères)
- Confirmation du mot de passe

**Correspond aux champs SQL:**
- `users.nom`, `users.prenom`
- `users.email`
- `users.telephone`
- `users.adresse`
- `users.sexe`
- `users.date_naissance`

### Étape 2 : Informations médicales
- Groupe sanguin (O, A, B, AB + Rhésus)
- Numéro de sécurité sociale / NIR
- Allergies (liste dynamique)
- Antécédents médicaux (liste dynamique)

**Correspond aux champs SQL:**
- `patients.groupe_sanguin`
- `patients.numero_securite_sociale`
- Tabletude: `patient_allergies`
- Table: `patient_antecedents`

### Étape 3 : Autres informations
- Poids (kg)
- Taille (cm)
- ID Carte NFC
- Personne de confiance (urgence)
- Téléphone personne de confiance
- Acceptation des conditions d'utilisation

**Correspond aux champs SQL:**
- `patients.poids`
- `patients.taille`
- `patients.nfc_card_id`
- `patients.personne_urgence`
- `patients.telephone_urgence`

## 🎯 FLUX DE MODIFICATION DE PROFIL (PatientEditProfileScreen)

### Onglet 1 : Informations de base
- Photo de profil (changeable)
- Tous les champs de l'étape 1 de l'inscription

### Onglet 2 : Données médicales
- Groupe sanguin
- Numéro de sécurité sociale
- Gestion des allergies (ajout/suppression)
- Gestion des antécédents (ajout/suppression)

### Onglet 3 : Autres informations
- Poids et Taille
- **IMC calculé automatiquement** avec interprétation
- ID Carte NFC
- Informations de la personne de confiance

## 🔗 Intégration dans le routing

Ajoutez ces routes à votre système de navigation GoRouter:

```dart
// Pour l'inscription
GoRoute(
  path: '/patient-registration',
  name: 'patientRegistration',
  builder: (context, state) => const PatientRegistrationScreen(),
),

// Pour la modification du profil
GoRoute(
  path: '/patient/edit-profile',
  name: 'patientEditProfile',
  builder: (context, state) => const PatientEditProfileScreen(),
),
```

## 💾 Intégration avec la base de données

### Lors de l'inscription
1. Créer un enregistrement dans `users`
2. Créer un enregistrement dans `patients`
3. Insérer les allergies dans `patient_allergies`
4. Insérer les antécédents dans `patient_antecedents`
5. Créer un dossier médical vide dans `dossiers_medicaux`

```sql
-- Exemple SQL
BEGIN TRANSACTION;

INSERT INTO users (id, email, nom, prenom, telephone, adresse, date_naissance, sexe, role, is_active, created_at)
VALUES ('PAT-2026-001', 'amadou@email.com', 'Diallo', 'Amadou', '+221771234567', 'Rue 1, Dakar', '1990-01-15', 'M', 'patient', TRUE, NOW());

INSERT INTO patients (id, user_id, groupe_sanguin, numero_securite_sociale, poids, taille, nfc_card_id, personne_urgence, telephone_urgence)
VALUES ('PAT-2026-001', 'PAT-2026-001', 'A+', '1960101123456', 75, 180, 'NFC-2026-0001', 'Aissatou Diallo', '+221779876543');

INSERT INTO patient_allergies (patient_id, allergie) VALUES ('PAT-2026-001', 'Pénicilline');
INSERT INTO patient_antecedents (patient_id, antecedent) VALUES ('PAT-2026-001', 'Hypertension');

INSERT INTO dossiers_medicaux (id, patient_id, date_creation, derniere_mise_a_jour)
VALUES ('DOSS-2026-001', 'PAT-2026-001', NOW(), NOW());

COMMIT;
```

### Lors de la mise à jour du profil
1. Mettre à jour les champs dans `users`
2. Mettre à jour les champs dans `patients`
3. Supprimer et réinsérer les allergies
4. Supprimer et réinsérer les antécédents
5. Mettre à jour la date `derniere_mise_a_jour` dans `dossiers_medicaux`

```sql
-- Exemple SQL
BEGIN TRANSACTION;

UPDATE users SET 
  telephone = '+221771234567',
  adresse = 'Nouvelle adresse',
  last_login = NOW()
WHERE id = 'PAT-2026-001';

UPDATE patients SET 
  poids = 76,
  taille = 180,
  groupe_sanguin = 'A+'
WHERE id = 'PAT-2026-001';

-- Supprimer et réinsérer les allergies
DELETE FROM patient_allergies WHERE patient_id = 'PAT-2026-001';
INSERT INTO patient_allergies (patient_id, allergie) VALUES 
  ('PAT-2026-001', 'Pénicilline'),
  ('PAT-2026-001', 'Aspirine');

UPDATE dossiers_medicaux SET derniere_mise_a_jour = NOW() 
WHERE patient_id = 'PAT-2026-001';

COMMIT;
```

## 🎨 Utilisation des composants

### AppTextField
Validations incluses pour :
- Champs requis
- Format email
- Longueur du mot de passe
- Correspondance des mots de passe

### ChoiceChip
Pour les groupes sanguins

### Chips dynamiques
Pour la gestion des allergies et antécédents

### DatePicker
Pour la date de naissance

## ✅ Validation des données

### Validations appliquées :

**Informations de base :**
- Email : Format valide requis
- Mot de passe : Minimum 8 caractères
- Mots de passe : Doivent correspondre

**Données médicales :**
- Numéro de sécurité sociale : Format flexible (optionnel)

**Autres informations :**
- Poids : Format numérique
- Taille : Format numérique

## 📊 Stockage des données

### Format de sérialisation
Les données sont envoyées à l'API sous forme JSON :

```json
{
  "nom": "Diallo",
  "prenom": "Amadou",
  "email": "amadou@email.com",
  "telephone": "+221771234567",
  "adresse": "Rue 1, Dakar",
  "sexe": "M",
  "date_naissance": "1990-01-15T00:00:00.000Z",
  "groupe_sanguin": "A+",
  "numero_securite_sociale": "1960101123456",
  "allergies": ["Pénicilline", "Aspirine"],
  "antecedents": ["Hypertension"],
  "poids": 75.0,
  "taille": 180.0,
  "nfc_card_id": "NFC-2026-0001",
  "personne_urgence": "Aissatou Diallo",
  "telephone_urgence": "+221779876543"
}
```

## 🔐 Sécurité

- Les mots de passe ne doivent jamais être stockés en clair
- Utiliser bcrypt ou argon2 pour le hash
- Implémenter HTTPS
- Valider les données côté serveur
- Implémenter le consentement RGPD

## 📱 Responsive Design

Les écrans sont optimisés pour :
- Téléphones (portrait et paysage)
- Tablettes
- Web (via Flutter Web)

## 🔄 État de l'application

Pour intégrer ces écrans avec votre système d'état (Provider, Riverpod, etc.):

```dart
// Exemple avec Provider
final patientProvider = StateNotifierProvider((ref) {
  return PatientNotifier();
});

// Utilisation dans les écrans
context.read(patientProvider.notifier).updateProfile(data);
```

## 📝 Notes importantes

1. **Allergies et Antécédents** : Implémenter un système d'auto-complétion avec les allergies/antécédents courants
2. **Carte NFC** : Intégrer un scanner NFC à l'écran pour lire l'ID
3. **Photo de profil** : Intégrer avec une API de stockage (AWS S3, Firebase Storage)
4. **Calcul IMC** : Implémenté automatiquement dans le modèle PatientModel
5. **Audit** : Logger toutes les modifications dans la table `security_audits`

## 🚀 Prochaines étapes

1. Connecter à une API backend réelle
2. Implémenter l'authentification (JWT/OAuth)
3. Ajouter la gestion de la photo de profil
4. Implémenter la vérification d'email
5. Ajouter la récupération de mot de passe
6. Intégrer un système d'audit pour tracer les modifications
