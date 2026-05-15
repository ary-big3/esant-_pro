import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/auth_service.dart';
import '../medecin/medecin_home_screen_premium.dart';
import '../admin/admin_home_screen.dart';
import '../nurse/nurse_home_screen.dart';
import '../laboratory/laboratory_home_screen.dart';

class ProfessionalRegistrationScreen extends StatefulWidget {
  const ProfessionalRegistrationScreen({super.key});

  @override
  State<ProfessionalRegistrationScreen> createState() =>
      _ProfessionalRegistrationScreenState();
}

class _ProfessionalRegistrationScreenState
    extends State<ProfessionalRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _specialiteController = TextEditingController();
  final _numeroLicenceController = TextEditingController();

  String? _selectedRole;
  bool _isLoading = false;
  bool _acceptTerms = false;

  // Rôles disponibles
  final Map<String, Map<String, dynamic>> _roles = {
    'medecin': {
      'label': 'Médecin',
      'icon': Icons.medical_services,
      'color': AppColors.primary,
    },
    'infirmiere': {
      'label': 'Infirmier/Infirmière',
      'icon': Icons.health_and_safety,
      'color': const Color(0xFF4CAF50),
    },
    'laboratoire': {
      'label': 'Laboratoire',
      'icon': Icons.science,
      'color': const Color(0xFF2196F3),
    },
    'admin': {
      'label': 'Administrateur',
      'icon': Icons.admin_panel_settings,
      'color': const Color(0xFFFF9800),
    },
  };

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specialiteController.dispose();
    _numeroLicenceController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner votre rôle'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez accepter les conditions d\'utilisation'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les mot de passe ne correspondent pas'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final authService = AuthService();
        
        // Appeler le service d'authentification avec inscription
        await authService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: '${_prenomController.text} ${_nomController.text}',
          phone: _telephoneController.text.trim(),
          role: _selectedRole ?? 'medecin',
        );

        if (mounted) {
          setState(() => _isLoading = false);
          
          // Déterminer l'écran d'accueil basé sur le rôle
          Widget homeScreen;
          switch (_selectedRole) {
            case 'admin':
              homeScreen = const AdminHomeScreen();
              break;
            case 'infirmiere':
              homeScreen = const NurseHomeScreen();
              break;
            case 'laboratoire':
              homeScreen = const LaboratoryHomeScreen();
              break;
            case 'medecin':
            default:
              homeScreen = const MedecinHomeScreenPremium();
              break;
          }

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => homeScreen),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur d\'inscription: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Inscription Professionnel',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélection du rôle
                Text(
                  'Sélectionnez votre profil',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 12),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles.keys.toList()[index];
                    final roleData = _roles[role]!;
                    final isSelected = _selectedRole == role;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedRole = role),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? roleData['color'] : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? roleData['color'].withValues(alpha: 0.1)
                              : AppColors.surface,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: roleData['color'].withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                roleData['icon'],
                                color: roleData['color'],
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              roleData['label'],
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? roleData['color'] : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (index * 100).ms);
                  },
                ),

                const SizedBox(height: 24),

                // Formulaire d'inscription
                AppTextField(
                  label: 'Prénom',
                  hint: 'Entrez votre prénom',
                  controller: _prenomController,
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Prénom requis';
                    }
                    return null;
                  },
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Nom',
                  hint: 'Entrez votre nom',
                  controller: _nomController,
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nom requis';
                    }
                    return null;
                  },
                ).animate(delay: 100.ms).fadeIn(),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Email professionnel',
                  hint: 'exemple@hopital.sn',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email requis';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Téléphone',
                  hint: '77 XXX XX XX',
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Téléphone requis';
                    }
                    return null;
                  },
                ).animate(delay: 300.ms).fadeIn(),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Mot de passe',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mot de passe requis';
                    }
                    if (value.length < 6) {
                      return 'Minimum 6 caractères';
                    }
                    return null;
                  },
                ).animate(delay: 400.ms).fadeIn(),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Confirmer le mot de passe',
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirmation requise';
                    }
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ).animate(delay: 500.ms).fadeIn(),

                const SizedBox(height: 20),

                // Conditions d'utilisation
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodySmall,
                            children: [
                              const TextSpan(text: 'J\'accepte les '),
                              TextSpan(
                                text: 'conditions d\'utilisation',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(text: ' et la '),
                              TextSpan(
                                text: 'politique de confidentialité',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 600.ms).fadeIn(),

                const SizedBox(height: 24),

                // Bouton d'inscription
                PrimaryButton(
                  text: 'S\'inscrire',
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                  icon: Icons.app_registration,
                ).animate(delay: 700.ms).fadeIn(),

                const SizedBox(height: 16),

                // Retour à la connexion
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà inscrit ? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Se connecter'),
                      ),
                    ],
                  ),
                ).animate(delay: 800.ms).fadeIn(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
