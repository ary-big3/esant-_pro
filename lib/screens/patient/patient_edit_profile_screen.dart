import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common_widgets.dart';

class PatientEditProfileScreen extends StatefulWidget {
  const PatientEditProfileScreen({super.key});

  @override
  State<PatientEditProfileScreen> createState() => _PatientEditProfileScreenState();
}

class _PatientEditProfileScreenState extends State<PatientEditProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentTab = 0;
  late TabController _tabController;

  // Informations de base
  final _nomController = TextEditingController(text: 'Diallo');
  final _prenomController = TextEditingController(text: 'Amadou');
  final _emailController = TextEditingController(text: 'amadou.diallo@email.com');
  final _telephoneController = TextEditingController(text: '+221 77 123 45 67');
  final _adresseController = TextEditingController(text: 'Rue 1, Dakar');

  String? _selectedSexe = 'M';
  DateTime? _dateNaissance;

  // Informations médicales
  String? _selectedGroupeSanguin = 'A+';
  final _numeroSecuriteSocialeController = TextEditingController(text: '1960101123456');
  List<String> _allergies = ['Pénicilline'];
  List<String> _antecedentsFamiliaux = ['Diabète', 'Hypertension'];
  List<String> _maladiesChroniques = ['Hypertension'];
  final _allergyController = TextEditingController();
  final _antecedentFamilialController = TextEditingController();
  final _maladieChroniqController = TextEditingController();

  // Données supplémentaires
  final _poidController = TextEditingController(text: '75');
  final _tailleController = TextEditingController(text: '180');
  final _nfcCardIdController = TextEditingController(text: 'NFC-2026-0001');
  final _personneUrgenceController = TextEditingController(text: 'Aissatou Diallo');
  final _telephoneUrgenceController = TextEditingController(text: '+221 77 987 65 43');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _numeroSecuriteSocialeController.dispose();
    _allergyController.dispose();
    _antecedentFamilialController.dispose();
    _maladieChroniqController.dispose();
    _poidController.dispose();
    _tailleController.dispose();
    _nfcCardIdController.dispose();
    _personneUrgenceController.dispose();
    _telephoneUrgenceController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(1990),
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
    if (picked != null) {
      setState(() => _dateNaissance = picked);
    }
  }

  void _addAllergy() {
    if (_allergyController.text.isNotEmpty && !_allergies.contains(_allergyController.text)) {
      setState(() {
        _allergies.add(_allergyController.text);
        _allergyController.clear();
      });
    }
  }

  void _addAntecedentFamilial() {
    if (_antecedentFamilialController.text.isNotEmpty && !_antecedentsFamiliaux.contains(_antecedentFamilialController.text)) {
      setState(() {
        _antecedentsFamiliaux.add(_antecedentFamilialController.text);
        _antecedentFamilialController.clear();
      });
    }
  }

  void _addMaladieChronique() {
    if (_maladieChroniqController.text.isNotEmpty && !_maladiesChroniques.contains(_maladieChroniqController.text)) {
      setState(() {
        _maladiesChroniques.add(_maladieChroniqController.text);
        _maladieChroniqController.clear();
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        await Future.delayed(const Duration(seconds: 2));

        // Données prêtes pour l'API (backend)
        // à envoyer via PatientService.updatePatientProfile()

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
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
        title: const Text('Modifier mon profil'),
      ),
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: Column(
            children: [
              // Onglets
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  onTap: (index) {
                    setState(() => _currentTab = index);
                  },
                  tabs: const [
                    Tab(text: 'Informations de base'),
                    Tab(text: 'Données médicales'),
                    Tab(text: 'Autres informations'),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildCurrentTabContent(),
                ),
              ),
              // Bouton Enregistrer
              Padding(
                padding: const EdgeInsets.all(20),
                child: PrimaryButton(
                  text: 'Enregistrer les modifications',
                  isLoading: _isLoading,
                  onPressed: _saveChanges,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildBasicInfoTab();
      case 1:
        return _buildMedicalInfoTab();
      case 2:
        return _buildAdditionalInfoTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ONGLET 1 : INFORMATIONS DE BASE
  Widget _buildBasicInfoTab() {
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const UserAvatar(
                initiales: 'AD',
                size: 80,
                backgroundColor: AppColors.primary,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Changer la photo',
                width: 200,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Nom',
                controller: _nomController,
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Prénom',
                controller: _prenomController,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Email',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Téléphone',
          controller: _telephoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Adresse',
          controller: _adresseController,
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 24),
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
                  child: _buildSexeOption('Homme', Icons.male, 'M'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSexeOption('Femme', Icons.female, 'F'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
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
                    const Icon(Icons.calendar_today, color: AppColors.textLight, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dateNaissance != null
                          ? '${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}'
                          : 'Sélectionner une date',
                      style: TextStyle(
                        color: _dateNaissance != null ? AppColors.textPrimary : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ONGLET 2 : DONNÉES MÉDICALES
  Widget _buildMedicalInfoTab() {
    return Column(
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
          controller: _numeroSecuriteSocialeController,
          prefixIcon: Icons.badge_outlined,
        ),
        const SizedBox(height: 24),
        // Allergies
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
                onDeleted: () => setState(() => _allergies.remove(allergie)),
              );
            }).toList(),
          ),
        const SizedBox(height: 24),
        // Antécédents
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
                onDeleted: () => setState(() => _allergies.remove(allergie)),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Ajouter un antécédent familial',
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
                onDeleted: () => setState(() => _antecedentsFamiliaux.remove(antecedent)),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Ajouter une maladie chronique',
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
                onDeleted: () => setState(() => _maladiesChroniques.remove(maladie)),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ONGLET 3 : AUTRES INFORMATIONS
  Widget _buildAdditionalInfoTab() {
    return Column(
      children: [
        Text(
          'Mesures anthropométriques',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Poids (kg)',
                controller: _poidController,
                prefixIcon: Icons.scale,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Taille (cm)',
                controller: _tailleController,
                prefixIcon: Icons.height,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // IMC (calculated)
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Indice de Masse Corporelle (IMC)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '23.5 kg/m²',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Poids normal',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // NFC Card
        AppTextField(
          label: 'ID Carte NFC',
          controller: _nfcCardIdController,
          prefixIcon: Icons.nfc,
        ),
        const SizedBox(height: 24),
        // Personne de confiance
        Text(
          'Personne de confiance',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Nom complet',
          controller: _personneUrgenceController,
          prefixIcon: Icons.person,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Téléphone',
          controller: _telephoneUrgenceController,
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSexeOption(String label, IconData icon, String value) {
    final isSelected = _selectedSexe == value;
    return InkWell(
      onTap: () => setState(() => _selectedSexe = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
