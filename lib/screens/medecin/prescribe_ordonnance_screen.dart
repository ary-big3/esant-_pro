import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';

class PrescribeOrdonnanceScreen extends StatefulWidget {
  final String patientNom;
  final String patientPrenom;
  final String patientId;
  final String medecinNom;
  final Map<String, dynamic>? existingPrescription;

  const PrescribeOrdonnanceScreen({
    super.key,
    required this.patientNom,
    required this.patientPrenom,
    required this.patientId,
    required this.medecinNom,
    this.existingPrescription,
  });

  @override
  State<PrescribeOrdonnanceScreen> createState() =>
      _PrescribeOrdonnanceScreenState();
}

class _PrescribeOrdonnanceScreenState extends State<PrescribeOrdonnanceScreen> {
  final List<Map<String, dynamic>> _prescribedMedications = [];
  late ApiService _apiService;
  bool _isSaving = false;
  bool _isLoadingMedications = false;
  List<Map<String, dynamic>> _availableMedications = [];
  Map<String, bool> _selectedMedicationIds = {};
  String _selectedCategory = 'Tous';
  String _searchQuery = '';

  bool get _isEditing => widget.existingPrescription != null;
  String get _screenTitle => _isEditing ? 'Modifier l\'ordonnance' : 'Prescrire une Ordonnance';
  
  final _customMedicationNameController = TextEditingController();
  final _customDosageController = TextEditingController();
  final _customFrequencyController = TextEditingController();
  final _customDurationController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _loadMedications();
    if (_isEditing) {
      _loadExistingPrescription();
    }
  }

  @override
  void dispose() {
    _customMedicationNameController.dispose();
    _searchController.dispose();
    _customDosageController.dispose();
    _customFrequencyController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }
    

  Future<void> _loadMedications() async {
    if (_isLoadingMedications) return;
    
    setState(() => _isLoadingMedications = true);
    
    try {
      await TokenHelper.ensureTokenReady();
      
      final response = await _apiService.get('/medications?limit=100');
      
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _availableMedications = List<Map<String, dynamic>>.from(
            response['data']['medications'] ?? []
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des médicaments: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingMedications = false);
    }
  }
  
    
  /// Ajouter un médicament coché à la prescription
  void _toggleMedicationSelection(Map<String, dynamic> medication) {
    final medId = medication['medication_id']?.toString();
    final isSelected = medId != null && _selectedMedicationIds[medId] == true;

    setState(() {
      if (isSelected) {
        if (medId != null) {
          _selectedMedicationIds[medId] = false;
        }
        _prescribedMedications.removeWhere(
          (m) => m['medication_id']?.toString() == medId,
        );
      } else {
        if (medId != null) {
          _selectedMedicationIds[medId] = true;
        }

        if (medId == null || !_prescribedMedications.any((m) => m['medication_id']?.toString() == medId)) {
          _prescribedMedications.add({
            'medication_id': medication['medication_id'],
            'medication_name': medication['medication_name'] ?? '',
            'generic_name': medication['generic_name'],
            'dosage': medication['dosage'] ?? '',
            'dosage_unit': medication['dosage_unit'] ?? 'mg',
            'frequency': medication['frequency'] ?? '1x/jour',
            'duration': medication['default_duration'] ?? 7,
            'route_of_administration': medication['route_of_administration'] ?? 'oral',
            'category': medication['category'] ?? '',
            'special_instructions': '',
          });
        }
      }
    });
  }
  
  /// Ajouter un médicament personnalisé
  void _addCustomMedication() {
    if (_customMedicationNameController.text.isEmpty ||
        _customDosageController.text.isEmpty ||
        _customFrequencyController.text.isEmpty ||
        _customDurationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remplissez tous les champs'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
  
    setState(() {
      _prescribedMedications.add({
        'medication_id': null,
        'medication_name': _customMedicationNameController.text,
        'generic_name': null,
        'dosage': _customDosageController.text,
        'dosage_unit': 'mg',
        'frequency': _customFrequencyController.text,
        'duration': int.tryParse(_customDurationController.text) ?? 7,
        'route_of_administration': 'oral',
        'category': 'Personnalisé',
        'special_instructions': '',
      });
    });

    _customMedicationNameController.clear();
    _customDosageController.clear();
    _customFrequencyController.clear();
    _customDurationController.clear();
  }

  /// Retirer un médicament de la prescription
  void _removeMedication(int index) {
    final med = _prescribedMedications[index];
    final medId = med['medication_id']?.toString();
    
    setState(() {
      _prescribedMedications.removeAt(index);
      if (medId != null) {
        _selectedMedicationIds[medId] = false;
      }
    });
  }

  List<Map<String, dynamic>> _buildMedicationsPayload() {
    return _prescribedMedications.map((med) {
      return {
        'medication_id': med['medication_id'],
        'medication_name': med['medication_name'],
        'generic_name': med['generic_name'],
        'dosage': med['dosage'],
        'dosage_unit': med['dosage_unit'],
        'frequency': med['frequency'],
        'duration': med['duration'],
        'route_of_administration': med['route_of_administration'],
        'category': med['category'],
        'special_instructions': med['special_instructions'] ?? '',
      };
    }).toList();
  }

  void _loadExistingPrescription() {
    final existing = widget.existingPrescription;
    if (existing == null || existing['medications'] == null) return;

    final medications = List<Map<String, dynamic>>.from(existing['medications']);

    setState(() {
      _prescribedMedications.clear();
      _selectedMedicationIds.clear();

      for (final medication in medications) {
        final medId = medication['medication_id']?.toString() ?? medication['ref_medication_id']?.toString();
        if (medId != null) {
          _selectedMedicationIds[medId] = true;
        }

        _prescribedMedications.add({
          'medication_id': medication['medication_id'],
          'medication_name': medication['medication_name'] ?? medication['nom'] ?? '',
          'generic_name': medication['generic_name'],
          'dosage': medication['dosage'] ?? medication['dose'] ?? '',
          'dosage_unit': medication['dosage_unit'] ?? medication['unite_dosage'] ?? 'mg',
          'frequency': medication['frequency'] ?? medication['posologie'] ?? '1x/jour',
          'duration': medication['duration'] ?? medication['duree'] ?? 7,
          'route_of_administration': medication['route_of_administration'] ?? medication['voie_administration'] ?? 'oral',
          'category': medication['category'] ?? 'Personnalisé',
          'special_instructions': medication['special_instructions'] ?? medication['instructions'] ?? '',
        });
      }
    });
  }

  Future<void> _updateOrdonnanceInDatabase() async {
    final prescriptionId = widget.existingPrescription?['prescription_id']?.toString();
    if (prescriptionId == null) {
      throw Exception('Identifiant de l\'ordonnance manquant');
    }

    try {
      setState(() => _isSaving = true);
      await TokenHelper.ensureTokenReady();

      final response = await _apiService.put(
        '/prescriptions/$prescriptionId',
        body: {
          'patient_id': widget.patientId,
          'medications': _buildMedicationsPayload(),
          'notes': 'Ordonnance mise à jour',
          'date': DateTime.now().toIso8601String(),
          'status': 'active',
        },
      );

      setState(() => _isSaving = false);

      if (response['success'] == true) {
        return;
      } else {
        throw Exception(response['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _saveOrdonnanceToDatabase() async {
    if (_isEditing && widget.existingPrescription?['prescription_id'] != null) {
      return _updateOrdonnanceInDatabase();
    }

    try {
      setState(() => _isSaving = true);
      await TokenHelper.ensureTokenReady();

      final response = await _apiService.post(
        '/prescriptions',
        body: {
          'patient_id': widget.patientId,
          'medications': _buildMedicationsPayload(),
          'notes': 'Ordonnance prescrite',
          'date': DateTime.now().toIso8601String(),
          'status': 'active',
        },
      );
  
      setState(() => _isSaving = false);

      if (response['success'] == true) {
        return; // Succès, continuer
      } else {
        throw Exception(response['message'] ?? 'Erreur lors de la sauvegarde');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      rethrow;
    }
  }

  void _submitOrdonnance() {
    if (_prescribedMedications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un médicament'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
  
    // Afficher confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? '✓ Ordonnance mise à jour' : '✓ Ordonnance créée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ordonnance validée',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ref: ORD-2026-${DateTime.now().millisecondsSinceEpoch}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Patient: ${widget.patientPrenom} ${widget.patientNom}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              'Médicaments: ${_prescribedMedications.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Médecin: ${widget.medecinNom}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medication,
                          color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Médicaments prescrits',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._prescribedMedications.map((med) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '✓ ${med['medication_name']} ${med['dosage']}${med['dosage_unit']} - ${med['frequency']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification envoyée',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '✓ ${widget.patientPrenom} ${widget.patientNom}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    try {
                      await _saveOrdonnanceToDatabase();
                      if (mounted) {
                        Navigator.pop(context); // Fermer le dialogue
                        Navigator.pop(context); // Fermer l'écran
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isEditing ? '✓ Ordonnance mise à jour et sauvegardée' : '✓ Ordonnance prescrite et sauvegardée'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      // Erreur déjà affichée dans _saveOrdonnanceToDatabase
                    }
                  },
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final categoriesAvailable = <String>{'Tous'};
    for (var med in _availableMedications) {
      categoriesAvailable.add(med['category']?.toString() ?? 'Autre');
    }
    final categories = categoriesAvailable.toList()..sort();

    var filteredMedications = _selectedCategory == 'Tous'
        ? _availableMedications
        : _availableMedications
            .where((m) => m['category']?.toString() == _selectedCategory)
            .toList();

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filteredMedications = filteredMedications
          .where((m) =>
              (m['medication_name']?.toString().toLowerCase() ?? '')
                  .contains(_searchQuery) ||
              (m['generic_name']?.toString().toLowerCase() ?? '')
                  .contains(_searchQuery) ||
              (m['category']?.toString().toLowerCase() ?? '')
                  .contains(_searchQuery))
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_screenTitle),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête patient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.patientPrenom} ${widget.patientNom}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ID: ${widget.patientId}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
  
            // ===== SECTION 1: Sélectionner des médicaments prédéfinis =====
            Text(
              'Sélectionner les médicaments',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Cochez les médicaments à prescrire',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un médicament...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.divider,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.divider,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filtre par catégorie avec Dropdown
            if (categories.length > 1)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider, width: 1),
                  color: AppColors.surface,
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  underline: const SizedBox(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
              ),
            const SizedBox(height: 12),
            
            // Afficher le nombre de résultats
            if (_searchQuery.isNotEmpty || _selectedCategory != 'Tous')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${filteredMedications.length} résultat${filteredMedications.length > 1 ? 's' : ''} trouvé${filteredMedications.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            // Liste des médicaments avec checkboxes
            if (_isLoadingMedications)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (filteredMedications.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.medication_rounded,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Aucun médicament ne correspond à votre recherche'
                            : 'Aucun médicament disponible',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider, width: 1),
                  color: AppColors.surface,
                ),
                child: DropdownButton<String>(
                  hint: Text(
                    filteredMedications.isEmpty
                        ? 'Aucun médicament disponible'
                        : 'Ajouter un médicament',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  isExpanded: true,
                  underline: const SizedBox(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  items: filteredMedications.map((medication) {
                    final medId = medication['medication_id'].toString();
                    final medicationName = medication['medication_name'] ?? 'N/A';
                    final dosageInfo = 'Dosage: ${medication['dosage']} ${medication['dosage_unit']} • ${medication['frequency']} • ${medication['default_duration']} jours';
                    
                    return DropdownMenuItem<String>(
                      value: medId,
                      child: Text(
                        '$medicationName - $dosageInfo',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? selectedMedId) {
                    if (selectedMedId != null) {
                      final selectedMed = filteredMedications.firstWhere(
                        (med) => med['medication_id'].toString() == selectedMedId,
                        orElse: () => {},
                      );
                      if (selectedMed.isNotEmpty) {
                        _toggleMedicationSelection(selectedMed);
                      }
                    }
                  },
                ),
              ),

            const SizedBox(height: 24),

            // ===== SECTION 2: Médicaments prescrits =====
            if (_prescribedMedications.isNotEmpty) ...[
              Text(
                'Médicaments prescrits',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _prescribedMedications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final med = _prescribedMedications[index];
                  
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête avec nom du médicament
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med['medication_name'] ?? 'N/A',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (med['generic_name'] != null)
                                    Text(
                                      'Générique: ${med['generic_name']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeMedication(index),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Grille de dropdowns pour posologie, fréquence et durée
                        Row(
                          children: [
                            // Posologie (Dosage)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Posologie',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.divider),
                                      color: AppColors.surface,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: DropdownButton<String>(
                                      value: med['dosage']?.toString() ?? '',
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items: <String>[
                                        ...(med['dosage']?.toString() ?? '').isNotEmpty ? [med['dosage']?.toString() ?? ''] : [],
                                        '250mg', '500mg', '750mg', '1000mg', '1500mg', '2000mg', 'Autre'
                                      ].toSet().map((String dose) {
                                        return DropdownMenuItem<String>(
                                          value: dose,
                                          child: Text(dose),
                                        );
                                      }).toList(),
                                      onChanged: (String? value) {
                                        if (value != null && value.isNotEmpty) {
                                          setState(() => _prescribedMedications[index]['dosage'] = value);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Fréquence
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fréquence',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.divider),
                                      color: AppColors.surface,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: DropdownButton<String>(
                                      value: med['frequency']?.toString() ?? '',
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items: <String>[
                                        ...(med['frequency']?.toString() ?? '').isNotEmpty ? [med['frequency']?.toString() ?? ''] : [],
                                        '1x/jour', '2x/jour', '3x/jour', '4x/jour', 'Matin', 'Midi', 'Soir', 'Au coucher'
                                      ].toSet().map((String freq) {
                                        return DropdownMenuItem<String>(
                                          value: freq,
                                          child: Text(freq),
                                        );
                                      }).toList(),
                                      onChanged: (String? value) {
                                        if (value != null && value.isNotEmpty) {
                                          setState(() => _prescribedMedications[index]['frequency'] = value);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Durée (Jours)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Durée (jours)',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.divider),
                                      color: AppColors.surface,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: DropdownButton<String>(
                                      value: med['duration']?.toString() ?? '',
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items: <String>[
                                        ...(med['duration']?.toString() ?? '').isNotEmpty ? [med['duration']?.toString() ?? ''] : [],
                                        '1', '3', '5', '7', '10', '14', '21', '30'
                                      ].toSet().map((String duration) {
                                        return DropdownMenuItem<String>(
                                          value: duration,
                                          child: Text('$duration j'),
                                        );
                                      }).toList(),
                                      onChanged: (String? value) {
                                        if (value != null && value.isNotEmpty) {
                                          setState(() => _prescribedMedications[index]['duration'] = int.tryParse(value) ?? 7);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // ===== SECTION 3: Ajouter un médicament personnalisé =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ajouter un médicament personnalisé',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _customMedicationNameController,
                    decoration: InputDecoration(
                      hintText: 'Nom du médicament',
                      prefixIcon: const Icon(Icons.medication),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customDosageController,
                          decoration: InputDecoration(
                            hintText: 'Dosage (ex: 500)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _customFrequencyController,
                          decoration: InputDecoration(
                            hintText: 'Fréquence',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customDurationController,
                    decoration: InputDecoration(
                      hintText: 'Durée (jours)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addCustomMedication,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter le médicament'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Boutons action
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Annuler',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: _isEditing ? 'Mettre à jour l\'ordonnance' : 'Prescrire l\'ordonnance',
                    onPressed:
                        _prescribedMedications.isEmpty ? null : _submitOrdonnance,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}