# 🎯 Exemples d'Utilisation - Services API

**Date**: 15 Avril 2026

Exemples concrets pour utiliser les services API Flutter avec le backend E-Santé.

---

## 1️⃣ Écran de Connexion

### Exemple: LoginScreen

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Valider les champs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (authService.isAuthenticated) {
        // Connexion réussie
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Bienvenue!')),
          );
          
          // Redirection selon le rôle
          Navigator.of(context).pushReplacementNamed(
            authService.currentUser?.role == 'patient'
                ? '/patient-home'
                : '/medecin-home',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${authService.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email Input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Password Input
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Se connecter'),
              ),
            ),

            const SizedBox(height: 16),

            // Sign Up Link
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.of(context).pushNamed('/register'),
              child: const Text('Pas de compte? S\'inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 2️⃣ Écran d'Inscription

### Exemple: RegisterScreen

```dart
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'patient';
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
      );

      if (authService.isAuthenticated && mounted) {
        Navigator.of(context).pushReplacementNamed('/patient-home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${authService.errorMessage}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('S\'inscrire')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Full Name
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nom Complet',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value?.isEmpty ?? true
                  ? 'Entrez votre nom'
                  : null,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Entrez un email';
                if (!value!.contains('@')) return 'Email invalide';
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone),
                hintText: '77123456',
              ),
              validator: (value) => value?.isEmpty ?? true
                  ? 'Entrez un téléphone'
                  : null,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe (min 8)',
                prefixIcon: Icon(Icons.lock),
              ),
              validator: (value) => value!.length < 8
                  ? 'Min 8 caractères'
                  : null,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Role Selection
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: ['patient', 'medecin', 'infirmiere']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: _isLoading ? null : (v) => setState(() => _selectedRole = v ?? ''),
              decoration: const InputDecoration(labelText: 'Rôle'),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('S\'inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 3️⃣ Écran Profil Patient

### Exemple: PatientProfileScreen

```dart
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  late Future<PatientModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = PatientService.getMyProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: FutureBuilder<PatientModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          // Chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Erreur
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _profileFuture = PatientService.getMyProfile();
                    }),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Succès
          final profile = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar & Basic Info
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          profile.nom?[0].toUpperCase() ?? 'P',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${profile.prenom} ${profile.nom}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(profile.email ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Contact Section
                _buildSection(
                  'Contact',
                  [
                    _buildInfo('📞 Téléphone', profile.telephone ?? 'N/A'),
                    _buildInfo('🏠 Adresse', profile.adresse ?? 'N/A'),
                  ],
                ),

                // Medical Section
                _buildSection(
                  'Informations Médicales',
                  [
                    _buildInfo('🩸 Groupe Sanguin', profile.groupeSanguin ?? 'N/A'),
                    _buildInfo('📏 Taille', '${profile.taille ?? 0} cm'),
                    _buildInfo('⚖️ Poids', '${profile.poids ?? 0} kg'),
                    _buildInfo('📊 IMC', _calculateIMC(profile)),
                  ],
                ),

                // Actions
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/edit-profile',
                    arguments: profile,
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier le Profil'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _calculateIMC(PatientModel profile) {
    if (profile.poids == null || profile.taille == null) return 'N/A';
    final imc = PatientService.calculateIMC(
      profile.poids!.toDouble(),
      profile.taille!.toDouble(),
    );
    return '${imc.toStringAsFixed(2)} (${PatientService.getIMCCategory(imc)})';
  }
}
```

---

## 4️⃣ Écran Dossier Médical

### Exemple: MedicalDossierScreen

```dart
class MedicalDossierScreen extends StatefulWidget {
  final String patientId;

  const MedicalDossierScreen({required this.patientId});

  @override
  State<MedicalDossierScreen> createState() => _MedicalDossierScreenState();
}

class _MedicalDossierScreenState extends State<MedicalDossierScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier Médical'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Consultations'),
            Tab(text: 'Examens'),
            Tab(text: 'Vaccinations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildConsultationsTab(),
          _buildExamsTab(),
          _buildVaccinationsTab(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: PatientService.getMedicalDossier(widget.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final dossier = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDossierSection('Allergies', dossier['allergies']),
              _buildDossierSection('Antécédents', dossier['medical_history']),
              _buildDossierSection(
                'Maladies Chroniques',
                dossier['chronic_diseases'],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsultationsTab() {
    return FutureBuilder<List<dynamic>>(
      future: PatientService.getPatientConsultations(widget.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final consultations = snapshot.data ?? [];

        if (consultations.isEmpty) {
          return const Center(
            child: Text('Aucune consultation'),
          );
        }

        return ListView.builder(
          itemCount: consultations.length,
          itemBuilder: (context, index) {
            final consultation = consultations[index];
            return ListTile(
              leading: const Icon(Icons.medical_services),
              title: Text(consultation['doctor_name'] ?? 'Médecin'),
              subtitle: Text(consultation['consultation_date'] ?? ''),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => _showConsultationDetails(consultation),
            );
          },
        );
      },
    );
  }

  Widget _buildExamsTab() {
    return FutureBuilder<List<dynamic>>(
      future: PatientService.getPatientExams(widget.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final exams = snapshot.data ?? [];

        if (exams.isEmpty) {
          return const Center(child: Text('Aucun examen'));
        }

        return ListView.builder(
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final exam = exams[index];
            return ListTile(
              leading: const Icon(Icons.science),
              title: Text(exam['exam_type'] ?? 'Examen'),
              subtitle: Text('${exam['exam_date']} - ${exam['exam_status']}'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => _showExamDetails(exam),
            );
          },
        );
      },
    );
  }

  Widget _buildVaccinationsTab() {
    return FutureBuilder<List<dynamic>>(
      future: PatientService.getPatientVaccinations(widget.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final vaccinations = snapshot.data ?? [];

        if (vaccinations.isEmpty) {
          return const Center(child: Text('Aucune vaccination'));
        }

        return ListView.builder(
          itemCount: vaccinations.length,
          itemBuilder: (context, index) {
            final vaccination = vaccinations[index];
            return ListTile(
              leading: const Icon(Icons.vaccines),
              title: Text(vaccination['vaccine_name'] ?? 'Vaccin'),
              subtitle: Text(vaccination['vaccination_date'] ?? ''),
              trailing: Text(vaccination['status'] ?? 'Complété'),
            );
          },
        );
      },
    );
  }

  Widget _buildDossierSection(String title, dynamic data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (data is List) ...[
          ...data.map((item) => Padding(
                padding: const EdgeInsets.all(4),
                child: Chip(label: Text(item.toString())),
              )),
        ] else if (data != null) ...[
          Text(data.toString()),
        ] else ...[
          const Text('Non renseigné'),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  void _showConsultationDetails(Map<String, dynamic> consultation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de la Consultation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Médecin', consultation['doctor_name']),
              _buildDetailRow('Date', consultation['consultation_date']),
              _buildDetailRow('Diagnostic', consultation['diagnosis']),
              _buildDetailRow('Traitement', consultation['treatment_plan']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showExamDetails(Map<String, dynamic> exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l\'Examen'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Type', exam['exam_type']),
              _buildDetailRow('Date', exam['exam_date']),
              _buildDetailRow('Status', exam['exam_status']),
              _buildDetailRow('Laboratoire', exam['laboratory_name']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value?.toString() ?? 'N/A'),
        ],
      ),
    );
  }
}
```

---

## 5️⃣ Configuration dans main.dart

### Utiliser Provider pour l'AuthService

```dart
import 'package:provider/provider.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        // AuthService avec ChangeNotifier
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ),
        // Ajouter d'autres providers si nécessaire
      ],
      child: const ESanteApp(),
    ),
  );
}

class ESanteApp extends StatelessWidget {
  const ESanteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Santé',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          // Redirection automatique selon l'état d'authentification
          if (authService.isAuthenticated) {
            return const PatientHomeScreen(); // ou écran approprié
          } else {
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/patient-home': (_) => const PatientHomeScreen(),
        '/profile': (_) => const PatientProfileScreen(),
        '/medical-dossier': (_) =>
            const MedicalDossierScreen(patientId: 'current'),
      },
    );
  }
}
```

---

## 🎓 Bonnes Pratiques

### 1. Toujours utiliser try-catch
```dart
try {
  final result = await PatientService.getMyProfile();
} catch (e) {
  print('Erreur: $e');
}
```

### 2. Afficher des loaders
```dart
if (isLoading) {
  return const Center(child: CircularProgressIndicator());
}
```

### 3. Gérer les erreurs réseau
```dart
if (snapshot.hasError) {
  return Center(
    child: Column(
      children: [
        const Icon(Icons.error, color: Colors.red),
        Text('${snapshot.error}'),
        ElevatedButton(
          onPressed: () => setState(() {}),
          child: const Text('Réessayer'),
        ),
      ],
    ),
  );
}
```

### 4. Valider avant d'envoyer
```dart
if (email.isEmpty || !email.contains('@')) {
  showError('Email invalide');
  return;
}
```

### 5. Utiliser Consumer ou watch avec Provider
```dart
// Approche automatique (recommandé)
Consumer<AuthService>(
  builder: (context, authService, _) {
    return Text(authService.currentUser?.fullName ?? 'Utilisateur');
  },
)

// Approche manuelle
final authService = Provider.of<AuthService>(context, listen: false);
```

---

✅ **Vous avez maintenant des exemples concrets pour intégrer chaque écran!**
