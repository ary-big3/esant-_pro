import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common_widgets.dart';
import '../../services/auth_service.dart';
import '../patient/patient_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _selectedSexe;
  String? _selectedGroupeSanguin;
  DateTime? _dateNaissance;
  bool _isLoading = false;
  bool _acceptTerms = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateNaissance = picked);
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez accepter les conditions d\'utilisation'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (_dateNaissance == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une date de naissance'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (_selectedSexe == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner votre sexe'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        // Appeler le service d'authentification
        final authService = AuthService();
        await authService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: '${_prenomController.text} ${_nomController.text}',
          phone: _telephoneController.text.trim(),
          role: 'patient',
          gender: _selectedSexe,
          dateOfBirth: _dateNaissance,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription réussie ! Bienvenue sur E-Santé.'),
              backgroundColor: AppColors.success,
            ),
          );
          _navigateToHome();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Color(0xFF1A1A3E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Inscription'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _handleRegister();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: _currentStep == 2 ? 'S\'inscrire' : 'Continuer',
                        isLoading: _isLoading,
                        onPressed: details.onStepContinue,
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: SecondaryButton(
                          text: 'Retour',
                          onPressed: details.onStepCancel,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              // Étape 0 : Informations personnelles
              Step(
                title: const Text('Informations personnelles'),
                subtitle: const Text('Nom, prénom, date de naissance'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Nom',
                            hint: 'Votre nom',
                            controller: _nomController,
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requis';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Prénom',
                            hint: 'Votre prénom',
                            controller: _prenomController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requis';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Sexe
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sexe',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _SexeOption(
                                label: 'Homme',
                                icon: Icons.male,
                                isSelected: _selectedSexe == 'M',
                                onTap: () => setState(() => _selectedSexe = 'M'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SexeOption(
                                label: 'Femme',
                                icon: Icons.female,
                                isSelected: _selectedSexe == 'F',
                                onTap: () => setState(() => _selectedSexe = 'F'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Date de naissance
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date de naissance',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.textLight,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _dateNaissance != null
                                      ? '${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}'
                                      : 'Sélectionner une date',
                                  style: TextStyle(
                                    color: _dateNaissance != null
                                        ? AppColors.textPrimary
                                        : AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Informations médicales'),
                subtitle: const Text('Groupe sanguin, allergies'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Groupe sanguin',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.groupesSanguins.map((groupe) {
                        final isSelected = _selectedGroupeSanguin == groupe;
                        return ChoiceChip(
                          label: Text(groupe),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedGroupeSanguin = selected ? groupe : null);
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.info),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ces informations sont optionnelles mais peuvent être vitales en cas d\'urgence.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.info,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Compte'),
                subtitle: const Text('Email et mot de passe'),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    AppTextField(
                      label: 'Email',
                      hint: 'exemple@email.com',
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
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Téléphone',
                      hint: '+221 XX XXX XX XX',
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Mot de passe',
                      hint: 'Minimum 8 caractères',
                      controller: _passwordController,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mot de passe requis';
                        }
                        if (value.length < 8) {
                          return 'Minimum 8 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Confirmer le mot de passe',
                      hint: 'Répétez le mot de passe',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() => _acceptTerms = value ?? false);
                          },
                          activeColor: AppColors.primary,
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'J\'accepte les ',
                              children: [
                                TextSpan(
                                  text: 'conditions d\'utilisation',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' et la '),
                                TextSpan(
                                  text: 'politique de confidentialité',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _SexeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SexeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
