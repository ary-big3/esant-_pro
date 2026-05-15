import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/medical_data_manager.dart';
import '../../services/patient_service.dart';

class PatientMedicalHistoryScreen extends StatefulWidget {
  final String? childId;
  final String? childName;
  final Map<String, dynamic>? initialData;
  final bool isReadOnly; // Nouveau paramètre
  final String? patientIdForDoctor; // Pour médecin editant un patient

  const PatientMedicalHistoryScreen({
    Key? key,
    this.childId,
    this.childName,
    this.initialData,
    this.isReadOnly = true, // Par défaut: lecture seule pour le patient
    this.patientIdForDoctor,
  }) : super(key: key);

  @override
  State<PatientMedicalHistoryScreen> createState() =>
      _PatientMedicalHistoryScreenState();
}

class _PatientMedicalHistoryScreenState
    extends State<PatientMedicalHistoryScreen> {
  late TextEditingController _antecedentsMedicauxController;
  late TextEditingController _antecedentsFamiliauxController;
  late TextEditingController _allergiesController;
  late TextEditingController _groupeSanguinController;
  late TextEditingController _maladieChroniqueController;
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _antecedentsMedicauxController = TextEditingController(
      text: widget.initialData?['antecedentsMedicaux'] ?? '',
    );
    _antecedentsFamiliauxController = TextEditingController(
      text: widget.initialData?['antecedentsFamiliaux'] ?? '',
    );
    _allergiesController = TextEditingController(
      text: (widget.initialData?['allergies'] as List<String>?)?.join(', ') ?? '',
    );
    _groupeSanguinController = TextEditingController(
      text: widget.initialData?['groupeSanguin'] ?? '',
    );
    _maladieChroniqueController = TextEditingController(
      text: (widget.initialData?['maladieCchronique'] as List<String>?)?.join(', ') ?? '',
    );
    
    _patientId = widget.patientIdForDoctor ?? widget.childId;
    
    // Charger les données existantes depuis l'API
    _loadMedicalHistory();
  }

  @override
  void dispose() {
    _antecedentsMedicauxController.dispose();
    _antecedentsFamiliauxController.dispose();
    _allergiesController.dispose();
    _groupeSanguinController.dispose();
    _maladieChroniqueController.dispose();
    super.dispose();
  }

  /// Charger l'historique médical depuis l'API
  Future<void> _loadMedicalHistory() async {
    if (_patientId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final history = await PatientService.getMedicalHistory(_patientId!);
      
      if (mounted && history.isNotEmpty) {
        setState(() {
          // medical_conditions est une List depuis l'API (explode côté backend)
          final medicalConditions = history['medical_conditions'];
          if (medicalConditions is List && medicalConditions.isNotEmpty) {
            _antecedentsMedicauxController.text = medicalConditions.join(', ');
          } else if (medicalConditions is String && medicalConditions.isNotEmpty) {
            _antecedentsMedicauxController.text = medicalConditions;
          }

          final familyHistory = history['family_history'];
          if (familyHistory is List && familyHistory.isNotEmpty) {
            _antecedentsFamiliauxController.text = familyHistory.join(', ');
          } else if (familyHistory is String && familyHistory.isNotEmpty) {
            _antecedentsFamiliauxController.text = familyHistory;
          }

          final bloodGroup = history['blood_group'];
          if (bloodGroup is String && bloodGroup.isNotEmpty) {
            _groupeSanguinController.text = bloodGroup;
          }
          
          // Convertir les listes JSON en chaînes
          if (history['chronic_diseases'] is List) {
            _maladieChroniqueController.text = (history['chronic_diseases'] as List).join(', ');
          }
          if (history['known_allergies'] is List) {
            _allergiesController.text = (history['known_allergies'] as List).join(', ');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de charger les données: $e'),
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

  Future<void> _saveData() async {
    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: ID patient manquant'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final bloodGroup = _groupeSanguinController.text.trim();
      final data = {
        'antecedentsMedicaux': _antecedentsMedicauxController.text.trim(),
        'antecedentsFamiliaux': _antecedentsFamiliauxController.text.trim(),
        'allergies': _allergiesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'groupeSanguin': bloodGroup.isEmpty ? null : bloodGroup,
        'maladieCchronique': _maladieChroniqueController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      };

      // Sauvegarder dans l'API
      await PatientService.updateMedicalHistory(_patientId!, data);
      
      // Sauvegarder aussi localement
      MedicalDataManager.updateMedicalData(_patientId!, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Antécédents médicaux sauvegardés avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChild = widget.childId != null;
    final screenTitle = isChild ? '${widget.childName}\n- Antécédents Médicaux' : 'Mes Antécédents Médicaux';
    final titleWithMode = widget.isReadOnly ? '$screenTitle (Lecture seule)' : screenTitle;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(titleWithMode),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titleWithMode),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.medical_information,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations Médicales',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Remplissez tous les champs pour un suivi complet',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Antécédents Médicaux
            _MedicalField(
              icon: Icons.history,
              title: 'Antécédents Médicaux',
              subtitle: 'Maladies passées, chirurgies, interventions',
              controller: _antecedentsMedicauxController,
              hint: 'Ex: Appendicectomie en 2018, Pneumonie en 2020\nOu: Fracture du bras gauche en 2019',
              isReadOnly: widget.isReadOnly,
            ),
            const SizedBox(height: 20),

            // Antécédents Familiaux
            _MedicalField(
              icon: Icons.family_restroom,
              title: 'Antécédents Familiaux',
              subtitle: 'Maladies héréditaires et génétiques',
              controller: _antecedentsFamiliauxController,
              hint: 'Ex: Diabète (grand-mère), Hypertension (père)\nOu: Cancer du sein (mère)',
              isReadOnly: widget.isReadOnly,
            ),
            const SizedBox(height: 20),

            // Groupe Sanguin
            _BloodGroupSelector(
              controller: _groupeSanguinController,
              isReadOnly: widget.isReadOnly,
            ),
            const SizedBox(height: 20),

            // Maladies Chroniques
            _MedicalField(
              icon: Icons.favorite,
              title: 'Maladies Chroniques',
              subtitle: 'Conditions à long terme',
              controller: _maladieChroniqueController,
              hint: 'Séparés par des virgules\nEx: Diabète Type 2, Hypertension, Asthme',
              isReadOnly: widget.isReadOnly,
            ),
            const SizedBox(height: 20),

            // Allergies
            _MedicalField(
              icon: Icons.warning_amber,
              title: 'Allergies Connues',
              subtitle: 'Médicaments, aliments, autres substances',
              controller: _allergiesController,
              hint: 'Séparés par des virgules\nEx: Pénicilline, Arachides, Latex',
              isReadOnly: widget.isReadOnly,
            ),
            const SizedBox(height: 32),

            // Boutons Actions (masqués si lecture seule)
            if (!widget.isReadOnly)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Annuler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceVariant,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveData,
                      icon: _isSaving 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Retour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MedicalField extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final String hint;
  final bool isReadOnly;

  const _MedicalField({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.hint,
    this.isReadOnly = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          maxLines: 4,
          readOnly: isReadOnly,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _BloodGroupSelector extends StatelessWidget {
  final TextEditingController controller;
  final bool isReadOnly;
  static const List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  const _BloodGroupSelector({
    required this.controller,
    this.isReadOnly = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bloodtype_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Groupe Sanguin',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      ' *',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Votre groupe et rhésus',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _bloodGroups.contains(controller.text) ? controller.text : null,
          decoration: InputDecoration(
            hintText: 'Sélectionnez votre groupe sanguin',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: _bloodGroups.map((group) => DropdownMenuItem(
            value: group,
            child: Text(group, style: const TextStyle(fontWeight: FontWeight.w600)),
          )).toList(),
          onChanged: isReadOnly ? null : (value) {
            if (value != null) controller.text = value;
          },
        ),
      ],
    );
  }
}
