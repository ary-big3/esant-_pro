import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common_widgets.dart';
import '../../services/patient_service.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _acceptTerms = false;

  // Étape 1 : Informations de base
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedSexe;
  DateTime? _dateNaissance;

  // Étape 2 : Informations médicales
  String? _selectedGroupeSanguin;
  final _numeroSecuriteSocialeController = TextEditingController();
  List<String> _allergies = [];
  List<String> _antecedentsFamiliaux = [];
  List<String> _maladiesChroniques = [];
  final _allergyController = TextEditingController();
  final _antecedentFamilialController = TextEditingController();
  final _maladieChroniqController = TextEditingController();

  // Étape 3 : Infos supplémentaires
  final _poidController = TextEditingController();
  final _tailleController = TextEditingController();
  final _nfcCardIdController = TextEditingController();
  final _personneUrgenceController = TextEditingController();
  final _telephoneUrgenceController = TextEditingController();

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _numeroSecuriteSocialeController.dispose();
    _allergyController.dispose();
    _antecedentFamilialController.dispose();
    _maladieChroniqController.dispose();
    _poidController.dispose();
    _tailleController.dispose();
    _nfcCardIdController.dispose();
    _personneUrgenceController.dispose();
    _telephoneUrgenceController.dispose();
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
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateNaissance) {
      setState(() => _dateNaissance = picked);
    }
  }

  void _addAllergy() {
    if (_allergyController.text.isNotEmpty) {
      setState(() {
        _allergies.add(_allergyController.text);
        _allergyController.clear();
      });
    }
  }

  void _addAntecedentFamilial() {
    if (_antecedentFamilialController.text.isNotEmpty) {
      setState(() {
        _antecedentsFamiliaux.add(_antecedentFamilialController.text);
        _antecedentFamilialController.clear();
      });
    }
  }

  void _addMaladieChronique() {
    if (_maladieChroniqController.text.isNotEmpty) {
      setState(() {
        _maladiesChroniques.add(_maladieChroniqController.text);
        _maladieChroniqController.clear();
      });
    }
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        _showError('Veuillez accepter les conditions d\'utilisation');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final userData = {
          'nom': _nomController.text,
          'prenom': _prenomController.text,
          'email': _emailController.text,
          'telephone': _telephoneController.text,
          'adresse': _adresseController.text,
          'sexe': _selectedSexe,
          'date_naissance': _dateNaissance?.toIso8601String(),
          'password': _passwordController.text,
        };

        final patientData = {
          'groupe_sanguin': _selectedGroupeSanguin,
          'numero_securite_sociale': _numeroSecuriteSocialeController.text,
          'allergies': _allergies,
          'antecedents_familiaux': _antecedentsFamiliaux,
          'maladies_chroniques': _maladiesChroniques,
          'poids': double.tryParse(_poidController.text) ?? 0,
          'taille': double.tryParse(_tailleController.text) ?? 0,
          'nfc_card_id': _nfcCardIdController.text,
          'personne_urgence': _personneUrgenceController.text,
          'telephone_urgence': _telephoneUrgenceController.text,
        };

        await PatientService.registerPatient(
          userData: userData,
          patientData: patientData,
        );

        if (mounted) {
          _showSuccess('Inscription réussie ! Bienvenue sur E-Santé.');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      } catch (e) {
        _showError('Erreur lors de l\'inscription: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Inscription Patient'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _handleRegistration();
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
                // ÉTAPE 1 : INFORMATIONS DE BASE
                Step(
                  title: const Text('Informations de base'),
                  subtitle: const Text('Identité et contact'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: SingleChildScrollView(
                    child: Column(
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
                                  if (value == null || value.isEmpty) return 'Nom requis';
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
                                  if (value == null || value.isEmpty) return 'Prénom requis';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Email',
                          hint: 'votre.email@example.com',
                          controller: _emailController,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email requis';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Téléphone',
                          hint: '+221 77 123 45 67',
                          controller: _telephoneController,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Téléphone requis';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Adresse',
                          hint: 'Rue, commune, région',
                          controller: _adresseController,
                          prefixIcon: Icons.location_on_outlined,
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Adresse requise';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Mot de passe',
                          hint: 'Au moins 8 caractères',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Mot de passe requis';
                            if (value.length < 8) {
                              return 'Au minimum 8 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Confirmer le mot de passe',
                          hint: 'Répétez le mot de passe',
                          controller: _confirmPasswordController,
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirmation requise';
                            }
                            if (value != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // ÉTAPE 2 : INFORMATIONS MÉDICALES
                Step(
                  title: const Text('Informations médicales'),
                  subtitle: const Text('Santé et antécédents'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: SingleChildScrollView(
                    child: Column(
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
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          label: 'Numéro de sécurité sociale',
                          hint: 'Votre NIR ou numéro équivalent',
                          controller: _numeroSecuriteSocialeController,
                          prefixIcon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Allergies',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Ajouter une allergie',
                                hint: 'Ex: Pénicilline',
                                controller: _allergyController,
                                prefixIcon: Icons.add_circle_outline,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _addAllergy,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_allergies.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allergies.map((allergie) {
                              return Chip(
                                label: Text(allergie),
                                onDeleted: () {
                                  setState(() => _allergies.remove(allergie));
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'Antécédents familiaux',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Maladies héréditaires dans votre famille',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textLight,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Ajouter un antécédent familial',
                                hint: 'Ex: Diabète, Hypertension',
                                controller: _antecedentFamilialController,
                                prefixIcon: Icons.family_restroom_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _addAntecedentFamilial,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_antecedentsFamiliaux.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _antecedentsFamiliaux.map((antecedent) {
                              return Chip(
                                label: Text(antecedent),
                                onDeleted: () {
                                  setState(() => _antecedentsFamiliaux.remove(antecedent));
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'Maladies chroniques',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Affections persistantes (diabète, hypertension, asthme, etc.)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textLight,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Ajouter une maladie chronique',
                                hint: 'Ex: Hypertension',
                                controller: _maladieChroniqController,
                                prefixIcon: Icons.health_and_safety_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _addMaladieChronique,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_maladiesChroniques.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _maladiesChroniques.map((maladie) {
                              return Chip(
                                label: Text(maladie),
                                onDeleted: () {
                                  setState(() => _maladiesChroniques.remove(maladie));
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                // ÉTAPE 3 : DONNÉES SUPPLÉMENTAIRES
                Step(
                  title: const Text('Autres informations'),
                  subtitle: const Text('Mesures et contacts urgence'),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Poids (kg)',
                                hint: '70',
                                controller: _poidController,
                                prefixIcon: Icons.scale,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'Taille (cm)',
                                hint: '175',
                                controller: _tailleController,
                                prefixIcon: Icons.height,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'ID Carte NFC',
                          hint: 'Votre identifiant NFC',
                          controller: _nfcCardIdController,
                          prefixIcon: Icons.nfc,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Personne de confiance',
                          hint: 'Nom et prénom',
                          controller: _personneUrgenceController,
                          prefixIcon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Téléphone personne urgence',
                          hint: '+221 77 123 45 67',
                          controller: _telephoneUrgenceController,
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),
                        CheckboxListTile(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() => _acceptTerms = value ?? false);
                          },
                          title: const Text('J\'accepte les conditions d\'utilisation'),
                          subtitle: const Text('Veuillez lire attentivement nos CGU'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
