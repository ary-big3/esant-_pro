# 🔗 Guide d'Intégration - Constantes Vitales

## 📌 Intégration dans l'Application

### 1. Navigation depuis l'Infirmière

#### Intégration dans Nurse Screen

**Fichier à modifier :** `lib/screens/nurse/nurse_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'nurse_home_screen.dart';

class NurseScreen extends StatefulWidget {
  const NurseScreen({Key? key}) : super(key: key);

  @override
  State<NurseScreen> createState() => _NurseScreenState();
}

class _NurseScreenState extends State<NurseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Infirmière'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.medical_services),
          label: const Text('Gestion des Constantes Vitales'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NurseHomeScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

### 2. Navigation depuis le Patient

#### Intégration dans Medical Dossier

**Fichier à modifier :** `lib/screens/patient/patient_dossier_screen.dart` (ou similaire)

```dart
// Ajouter un onglet ou une section pour les constantes vitales
import 'patient_vitals_screen.dart';

// Dans le widget build :
TabBar(
  tabs: [
    const Tab(text: 'Consultations'),
    const Tab(text: 'Prescriptions'),
    const Tab(text: 'Examens'),
    const Tab(icon: Icon(Icons.favorite), text: 'Constantes Vitales'),
  ],
),

// Dans TabBarView :
TabBarView(
  children: [
    // ... autres onglets
    PatientVitalsScreen(patientId: patientId),
  ],
),
```

#### Intégration dans Patient Home

**Fichier à modifier :** `lib/screens/patient/patient_home_screen.dart`

```dart
// Ajouter un widget pour afficher les dernières constantes

Widget _buildLatestVitals() {
  return FutureBuilder<VitalsModel?>(
    future: VitalsService.getLatestVitals(patientId),
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data == null) {
        return const SizedBox.shrink();
      }
      
      final vital = snapshot.data!;
      return ListTile(
        leading: const Icon(Icons.favorite, color: Colors.red),
        title: const Text('Dernières Constantes'),
        subtitle: Text('${vital.temperature}°C - FC: ${vital.frequenceCardiaque}'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientVitalsScreen(
                patientId: patientId,
              ),
            ),
          );
        },
      );
    },
  );
}
```

---

### 3. Navigation depuis le Docteur

#### Consultation des constantes d'un patient

**Fichier à modifier :** `lib/screens/doctor/doctor_patient_detail_screen.dart`

```dart
// Ajouter une section pour les constantes vitales

Container(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Constantes Vitales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        icon: const Icon(Icons.favorite),
        label: const Text('Voir les constantes'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientVitalsScreen(
                patientId: patientId,
              ),
            ),
          );
        },
      ),
    ],
  ),
),
```

---

### 4. Widgets Réutilisables

#### Widget de Carte Constantes Vitales Rapides

**Fichier à créer :** `lib/widgets/vital_signs_card.dart`

```dart
import 'package:flutter/material.dart';
import '../models/vitals_model.dart';

class VitalSignsCard extends StatelessWidget {
  final VitalsModel vital;
  final VoidCallback? onTap;
  final bool showNotes;

  const VitalSignsCard({
    Key? key,
    required this.vital,
    this.onTap,
    this.showNotes = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Constantes Vitales',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${vital.temperature}°C',
                    style: const TextStyle(fontSize: 14, color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  _buildBadge('TA', '${vital.tensionSystolique}/${vital.tensionDiastolique}'),
                  _buildBadge('FC', '${vital.frequenceCardiaque}'),
                  _buildBadge('O₂', '${vital.saturOxygene}%'),
                ],
              ),
              if (showNotes && vital.notes != null) ...[
                const SizedBox(height: 8),
                Text(
                  vital.notes!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
```

**Utilisation :**
```dart
VitalSignsCard(
  vital: latest,
  showNotes: true,
  onTap: () => // Naviguer vers le détail
)
```

---

### 5. Intégration dans le Dossier Médical

#### Ajout d'une section constantes

**Fichier à modifier :** `lib/screens/patient/medical_dossier_screen.dart`

```dart
// Dans la page du dossier médical :

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: ListView(
      children: [
        // ... autres sections
        
        // Section Constantes Vitales
        SectionHeader(title: 'Constantes Vitales'),
        FutureBuilder<VitalsModel?>(
          future: VitalsService.getLatestVitals(patientId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return VitalSignsCard(
                vital: snapshot.data!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientVitalsScreen(
                        patientId: patientId,
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    ),
  );
}
```

---

### 6. Intégration API/Service

#### Initialisation du Service

**Fichier :** `lib/main.dart` ou `lib/core/initialization.dart`

```dart
// S'assurer que le token est défini au démarrage
void initializeServices() {
  final apiService = ApiService();
  // Le token est défini lors de la connexion via AuthService
  
  // Optionnel : Vérifier que le token est valide
  final token = apiService.getToken();
  if (token == null) {
    print('Avertissement : Token d\'authentification non défini');
  }
}
```

---

### 7. Gestion des Erreurs

#### Traitement centralisé des erreurs

**Fichier à modifier :** `lib/services/vitals_service.dart`

```dart
// Ajouter une méthode de gestion centralisée
static void _handleError(String method, Exception e) {
  if (kDebugMode) {
    print('❌ [VitalsService.$method] Erreur: $e');
  }
  
  // Envoyer à un service de logging
  // LoggerService.logError(
  //   'VitalsService.$method',
  //   e.toString(),
  // );
}
```

---

### 8. Notifications et Alertes

#### Notification de constantes anormales

**Fichier à créer :** `lib/services/vital_alerts_service.dart`

```dart
class VitalAlertsService {
  /// Vérifier si les constantes sont anormales
  static bool isAbnormal(VitalsModel vital) {
    return isAbnormalTemperature(vital.temperature) ||
           isAbnormalTension(vital.tensionSystolique, vital.tensionDiastolique) ||
           isAbnormalHeartRate(vital.frequenceCardiaque) ||
           isAbnormalO2(vital.saturOxygene);
  }

  static bool isAbnormalTemperature(double temp) => temp < 36.5 || temp > 37.5;
  static bool isAbnormalTension(int systolic, int diastolic) => systolic < 90 || systolic > 140;
  static bool isAbnormalHeartRate(int fc) => fc < 60 || fc > 100;
  static bool isAbnormalO2(double o2) => o2 < 95;

  /// Créer une notification
  static Future<void> notifyAbnormal(VitalsModel vital) async {
    if (!isAbnormal(vital)) return;
    
    // Envoyer notification
    // await NotificationService.sendNotification(
    //   title: 'Constantes Anormales',
    //   body: 'Patient ${vital.patientId} a des constantes anormales',
    // );
  }
}
```

---

### 9. Configuration des Constantes de Menu

#### Ajouter dans les menus de navigation

**Fichier à modifier :** `lib/core/routes/app_routes.dart`

```dart
class AppRoutes {
  // ... routes existantes
  
  static const String nurseVitals = '/nurse/vitals';
  static const String patientVitals = '/patient/vitals/:patientId';
}
```

#### Configurer les routes

**Fichier à modifier :** `lib/main.dart`

```dart
MaterialApp(
  routes: {
    // ... routes existantes
    AppRoutes.nurseVitals: (context) => const NurseHomeScreen(),
  },
)
```

---

### 10. Checklist d'Intégration

- [ ] Import des écrans dans les fichiers parents
- [ ] Navigation mise à place
- [ ] Widgets réutilisables créés
- [ ] Service intégré
- [ ] Token d'authentification vérifié
- [ ] Routes configurées
- [ ] Tests de navigation effectués
- [ ] Gestion d'erreurs testée
- [ ] UI responsive validée
- [ ] Performance vérifiée

---

## 🎯 Architecture de Navigation Complète

```
┌─────────────────────────────────────────────────────────────┐
│                      App Principale                          │
└─────────────────────────────────────────────────────────────┘
                    ↓
        ┌───────────┬───────────┬───────────┐
        ↓           ↓           ↓           ↓
    PATIENT      INFIRMIÈRE    DOCTEUR    ADMIN
        ↓           ↓           ↓           ↓
   PatientHome  NurseHome   DoctorHome  AdminHome
        ↓           ↓           ↓
        │      NurseHomeScreen  │
        │      - Saisie         │
        │      - Historique     │
        │           ↓           │
        │      [Modify/Delete]  │
        │           ↓           │
        │        VitalsService  │
        │           ↓           │
        └─ → API Backend ← ─────┘
                    ↓
            ┌───────────────────┐
            │  Nurse Controller  │
            │  (CRUD Vitals)     │
            └───────────────────┘
                    ↓
            ┌───────────────────┐
            │   MySQL Database   │
            │  (vital_signs)     │
            └───────────────────┘
            
PatientHome → PatientVitalsScreen ↘
DoctorHome → PatientVitalsScreen ──→ VitalsService → API Backend
```

---

## 📊 Points de Données

### Flux de Données

1. **Enregistrement :**
   NurseScreen → NurseHomeScreen → VitalsService.recordVitals() → API → Backend → MySQL

2. **Modification :**
   NurseHomeScreen → VitalsService.updateVitals() → API → Backend → MySQL

3. **Suppression :**
   NurseHomeScreen → VitalsService.deleteVitals() → API → Backend → MySQL

4. **Consultation (Patient) :**
   PatientScreen → PatientVitalsScreen → VitalsService.getPatientVitalsHistory() → API → Backend → MySQL

5. **Consultation (Docteur) :**
   DoctorScreen → PatientVitalsScreen → VitalsService.getPatientVitalsHistory() → API → Backend → MySQL

---

## 🔒 Points de Sécurité

- ✅ Authentification JWT à chaque appel API
- ✅ Vérification du rôle à chaque endpoint
- ✅ Validation des données côté client et serveur
- ✅ Limitation d'accès aux données propres
- ✅ Logs d'audit des modifications
- ✅ HTTPS pour la transmission

---

## 📞 Support et Questions

Pour l'intégration, consultez :
1. `VITALS_IMPLEMENTATION.md` - Vue d'ensemble
2. `VITALS_TEST_GUIDE.md` - Tests et validation
3. Documentation API Backend
4. Code source des services existants
