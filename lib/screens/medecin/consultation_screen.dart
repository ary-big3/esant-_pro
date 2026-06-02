import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/ia_models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';

class ConsultationScreen extends StatefulWidget {
  final String patientNom;
  final String patientAge;
  final String patientId;

  const ConsultationScreen({
    super.key,
    required this.patientNom,
    required this.patientAge,
    required this.patientId,
  });

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _apiService;
  bool _isSaving = false;
  final List<Map<String, String>> _medicaments = [];
  bool _createOrdonnance = true;
  final _motifController = TextEditingController();
  final _observationsController = TextEditingController();
  final _diagnosticController = TextEditingController();

  // Constantes vitales
  final _tensionSysController = TextEditingController();
  final _tensionDiaController = TextEditingController();
  final _poulsController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _poidsController = TextEditingController();
  final _tailleController = TextEditingController();

  // IA Médicale
  IAMedicale? iaMedicale;

  void _analyserAvecIA() {
    final constantes = [
      _tensionSysController.text,
      _tensionDiaController.text,
      _poulsController.text,
      _temperatureController.text,
      _poidsController.text,
      _tailleController.text,
    ];
    iaMedicale = IAMedicale(
      constantesVitales: constantes,
      anomaliesDetectees: [],
      synthese: '',
      alertes: [],
    );
    iaMedicale!.analyserConstantes(constantes);
    // Utiliser iaMedicale.detecterAnomalies(), iaMedicale.genererSynthese(), etc.
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _motifController.dispose();
    _observationsController.dispose();
    _diagnosticController.dispose();
    _tensionSysController.dispose();
    _tensionDiaController.dispose();
    _poulsController.dispose();
    _temperatureController.dispose();
    _poidsController.dispose();
    _tailleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Nouvelle Consultation'),
            actions: [
              TextButton.icon(
                onPressed: _isSaving ? null : () => _saveDraft(),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Brouillon'),
              ),
              IconButton(
                icon: const Icon(Icons.smart_toy),
            tooltip: 'Analyse IA',
            onPressed: _analyserAvecIA,
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête patient
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                UserAvatar(
                  initiales: widget.patientNom.split(' ').map((e) => e[0]).join(),
                  size: 48,
                  backgroundColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patientNom,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${widget.patientAge} ans',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const StatusBadge(text: 'A+', color: AppColors.error),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showPatientHistory(context),
                  icon: const Icon(Icons.history),
                  tooltip: 'Historique',
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          // Résultats IA médicale
          if (iaMedicale != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Synthèse IA :', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(iaMedicale!.genererSynthese()),
                  Text('Anomalies détectées :'),
                  ...iaMedicale!.detecterAnomalies().map((a) => Text('- $a')),
                  Text('Alertes :'),
                  ...iaMedicale!.genererAlertes().map((al) => Text('- $al')),
                ],
              ),
            ),
          // Onglets
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.secondary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.secondary,
              tabs: const [
                Tab(text: 'Motif'),
                Tab(text: 'Examen'),
                Tab(text: 'Diagnostic'),
              ],
            ),
          ),
          // Contenu
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MotifTab(
                  motifController: _motifController,
                  onNext: () => _tabController.animateTo(1),
                ),
                _ExamenTab(
                  tensionSysController: _tensionSysController,
                  tensionDiaController: _tensionDiaController,
                  poulsController: _poulsController,
                  temperatureController: _temperatureController,
                  poidsController: _poidsController,
                  tailleController: _tailleController,
                  observationsController: _observationsController,
                  onNext: () => _tabController.animateTo(2),
                ),
                _DiagnosticTab(
                  diagnosticController: _diagnosticController,
                  onNext: _finishConsultation,
                ),
              ],
            ),
          ),
        ],
      ),
        ),
        // Indicateur de chargement
        if (_isSaving)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Brouillon sauvegardé'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _saveConsultationToDatabase() async {
    try {
      setState(() => _isSaving = true);
      await TokenHelper.ensureTokenReady();

      final bodyToSend = {
        'patient_id': widget.patientId,
        'motif': _motifController.text,
        'observations': _observationsController.text,
        'diagnostic': _diagnosticController.text,
        'tension_sys': _tensionSysController.text,
        'tension_dia': _tensionDiaController.text,
        'pouls': _poulsController.text,
        'temperature': _temperatureController.text,
        'poids': _poidsController.text,
        'taille': _tailleController.text,
        'date': DateTime.now().toIso8601String(),
        'status': 'completed',
      };
      
      print('📤 DEBUG - Données envoyées à l\'API: $bodyToSend');

      final response = await _apiService.post(
        '/consultations',
        body: bodyToSend,
      );

      print('📥 DEBUG - Réponse API: ${response.toString()}');

      setState(() => _isSaving = false);

      if (response['success'] == true) {
        // Si ordonnance créée, sauvegarder les médicaments
        if (_createOrdonnance && _medicaments.isNotEmpty) {
          final consultationId = response['data']?['consultation_id'];
          if (consultationId != null) {
            await _savePrescriptionToDatabase(consultationId);
          }
        }
        return; // Succès
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

  /// Sauvegarder la prescription avec les médicaments
  Future<void> _savePrescriptionToDatabase(int consultationId) async {
    try {
      if (_medicaments.isEmpty) {
        print('⚠️ Aucun médicament à sauvegarder');
        return;
      }

      print('💾 Sauvegarde de l\'ordonnance avec ${_medicaments.length} médicament(s)');

      // Transformer les données pour correspondre au format attendu par l'API
      final medications = _medicaments.map((med) {
        final durationValue = med['duree']?.toString().trim() ?? '7';
        return {
          'medication_name': med['nom'] ?? '',
          'dosage': med['dosage'] ?? '',
          'dosage_unit': 'mg',
          'frequency': med['posologie'] ?? '1x/jour',
          'duration': durationValue,
          'route_of_administration': 'oral',
          'special_instructions': '',
        };
      }).toList();

      final prescriptionData = {
        'patient_id': widget.patientId,
        'consultation_id': consultationId,
        'medications': medications,
        'notes': 'Ordonnance prescrite lors de la consultation',
        'status': 'active',
      };

      print('📤 Ordonnance à envoyer: ${jsonEncode(prescriptionData)}');

      final response = await _apiService.post(
        '/prescriptions',
        body: prescriptionData,
      );

      if (response['success'] == true) {
        print('✅ Ordonnance sauvegardée avec succès: ${response['data']?['prescription_number']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Ordonnance sauvegardée avec succès'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        print('❌ Erreur API: ${response['message']}');
        throw Exception(response['message'] ?? 'Erreur lors de la sauvegarde de l\'ordonnance');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde ordonnance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur ordonnance: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _finishConsultation() async {
    try {
      await _saveConsultationToDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Consultation sauvegardée'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Erreur déjà affichée dans _saveConsultationToDatabase
    }
  }

  void _showPatientHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Historique du patient',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${15 - index * 30} Jan 2026',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const StatusBadge(text: 'Terminé', color: AppColors.success),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Consultation de suivi',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dr. Fatou Diop • Cardiologie',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

class _MotifTab extends StatefulWidget {
  final TextEditingController motifController;
  final VoidCallback onNext;

  const _MotifTab({required this.motifController, required this.onNext});

  @override
  State<_MotifTab> createState() => _MotifTabState();
}

class _MotifTabState extends State<_MotifTab> {
  String? _selectedMotif;
  
  // Liste complète des motifs de consultation
  final List<String> _motifsList = [
    'Suivi médical',
    'Douleur thoracique',
    'Essoufflement',
    'Palpitations',
    'Contrôle tension',
    'Renouvellement d\'ordonnance',
    'Consultation préventive',
    'Bilan de santé',
    'Malaise',
    'Fièvre',
    'Toux',
    'Allergie',
    'Autre',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Motif avec Dropdown
          Text(
            'Motif de consultation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Dropdown Button pour motifs prédéfinis
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 1),
              color: AppColors.surface,
            ),
            child: DropdownButton<String>(
              value: _selectedMotif,
              hint: const Text('Sélectionnez un motif...'),
              isExpanded: true,
              underline: const SizedBox(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              items: _motifsList.map((String motif) {
                return DropdownMenuItem<String>(
                  value: motif,
                  child: Text(motif),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedMotif = value;
                  if (value != null) {
                    widget.motifController.text = value;
                  }
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Champ de description personnalisée
          Text(
            'Détails supplémentaires',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.motifController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Décrivez le motif de consultation en détail...',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Section Symptômes
          Text(
            'Symptômes signalés',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sélectionnez les symptômes rapportés par le patient',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _SymptomChecklistDropdown(),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              child: const Text('Continuer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomChecklistDropdown extends StatefulWidget {
  @override
  State<_SymptomChecklistDropdown> createState() => _SymptomChecklistDropdownState();
}

class _SymptomChecklistDropdownState extends State<_SymptomChecklistDropdown> {
  final List<String> _symptomsList = [
    'Fièvre',
    'Fatigue',
    'Maux de tête',
    'Nausées',
    'Vertiges',
    'Douleurs musculaires',
    'Toux',
    'Essoufflement',
    'Douleur thoracique',
    'Palpitations',
    'Allergie',
    'Éruption cutanée',
  ];
  
  final Map<String, bool> _selectedSymptoms = {};
  bool _showSymptomsList = false;

  @override
  void initState() {
    super.initState();
    for (var symptom in _symptomsList) {
      _selectedSymptoms[symptom] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedSymptoms.values.where((v) => v).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bouton pour afficher/masquer la liste déroulante
        GestureDetector(
          onTap: () => setState(() => _showSymptomsList = !_showSymptomsList),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 1),
              color: AppColors.surface,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedCount > 0
                        ? '$selectedCount symptôme${selectedCount > 1 ? 's' : ''} sélectionné${selectedCount > 1 ? 's' : ''}'
                        : 'Sélectionnez les symptômes...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selectedCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  _showSymptomsList ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        
        // Liste déroulante des symptômes
        if (_showSymptomsList) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 1),
              color: AppColors.surface,
            ),
            child: Column(
              children: _symptomsList.map((symptom) {
                return Column(
                  children: [
                    CheckboxListTile(
                      value: _selectedSymptoms[symptom] ?? false,
                      onChanged: (_) => setState(() => 
                        _selectedSymptoms[symptom] = !(_selectedSymptoms[symptom] ?? false)
                      ),
                      title: Text(symptom),
                      activeColor: AppColors.secondary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      dense: true,
                    ),
                    if (symptom != _symptomsList.last)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
        
        // Affichage des symptômes sélectionnés
        if (selectedCount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Symptômes sélectionnés:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _selectedSymptoms.entries
                      .where((e) => e.value)
                      .map((e) => Text(
                        '✓ ${e.key}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.secondary, fontSize: 13),
        ),
      ),
    );
  }
}

class _SymptomChecklist extends StatefulWidget {
  @override
  State<_SymptomChecklist> createState() => _SymptomChecklistState();
}

class _SymptomChecklistState extends State<_SymptomChecklist> {
  final Map<String, bool> _symptoms = {
    'Fièvre': false,
    'Fatigue': false,
    'Maux de tête': false,
    'Nausées': false,
    'Vertiges': false,
    'Douleurs musculaires': false,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _symptoms.entries
          .map((e) => FilterChip(
                label: Text(e.key),
                selected: e.value,
                onSelected: (selected) => setState(() => _symptoms[e.key] = selected),
                selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.secondary,
              ))
          .toList(),
    );
  }
}

class _ExamenTab extends StatelessWidget {
  final TextEditingController tensionSysController;
  final TextEditingController tensionDiaController;
  final TextEditingController poulsController;
  final TextEditingController temperatureController;
  final TextEditingController poidsController;
  final TextEditingController tailleController;
  final TextEditingController observationsController;
  final VoidCallback onNext;

  const _ExamenTab({
    required this.tensionSysController,
    required this.tensionDiaController,
    required this.poulsController,
    required this.temperatureController,
    required this.poidsController,
    required this.tailleController,
    required this.observationsController,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Constantes vitales',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _VitalInput(
                  label: 'Tension Sys',
                  unit: 'mmHg',
                  controller: tensionSysController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VitalInput(
                  label: 'Tension Dia',
                  unit: 'mmHg',
                  controller: tensionDiaController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VitalInput(
                  label: 'Pouls',
                  unit: 'bpm',
                  controller: poulsController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VitalInput(
                  label: 'Température',
                  unit: '°C',
                  controller: temperatureController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VitalInput(
                  label: 'Poids',
                  unit: 'kg',
                  controller: poidsController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VitalInput(
                  label: 'Taille',
                  unit: 'cm',
                  controller: tailleController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Examen clinique',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: observationsController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Notes d\'examen clinique...',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Ajouter une photo'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continuer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalInput extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;

  const _VitalInput({
    required this.label,
    required this.unit,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DiagnosticTab extends StatefulWidget {
  final TextEditingController diagnosticController;
  final VoidCallback onNext;

  const _DiagnosticTab({required this.diagnosticController, required this.onNext});

  @override
  State<_DiagnosticTab> createState() => _DiagnosticTabState();
}

class _DiagnosticTabState extends State<_DiagnosticTab> {
  final List<String> _diagnostics = [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diagnostic',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          // Recherche CIM-10
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un code CIM-10...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              // Simuler recherche
            },
          ),
          const SizedBox(height: 16),
          // Suggestions IA
          AppCard(
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology, color: AppColors.info, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Suggestions IA',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DiagnosticChip(
                      code: 'I10',
                      label: 'Hypertension essentielle',
                      onTap: () => _addDiagnostic('I10 - Hypertension essentielle'),
                    ),
                    _DiagnosticChip(
                      code: 'I25.1',
                      label: 'Cardiopathie ischémique',
                      onTap: () => _addDiagnostic('I25.1 - Cardiopathie ischémique'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_diagnostics.isNotEmpty) ...[
            Text(
              'Diagnostics sélectionnés',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...List.generate(
              _diagnostics.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(_diagnostics[index])),
                      IconButton(
                        onPressed: () => setState(() => _diagnostics.removeAt(index)),
                        icon: const Icon(Icons.close, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: widget.diagnosticController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Notes complémentaires sur le diagnostic...',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              child: const Text('Valider'),
            ),
          ),
        ],
      ),
    );
  }

  void _addDiagnostic(String diagnostic) {
    if (!_diagnostics.contains(diagnostic)) {
      setState(() => _diagnostics.add(diagnostic));
    }
  }
}

class _DiagnosticChip extends StatelessWidget {
  final String code;
  final String label;
  final VoidCallback onTap;

  const _DiagnosticChip({
    required this.code,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                code,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.add, size: 16, color: AppColors.info),
          ],
        ),
      ),
    );
  }
}

class _TraitementTab extends StatefulWidget {
  final List<Map<String, String>> medicaments;
  final bool createOrdonnance;
  final Function(bool) onCreateOrdonnanceChanged;
  final VoidCallback onFinish;

  const _TraitementTab({
    required this.medicaments,
    required this.createOrdonnance,
    required this.onCreateOrdonnanceChanged,
    required this.onFinish,
  });

  @override
  State<_TraitementTab> createState() => _TraitementTabState();
}

class _TraitementTabState extends State<_TraitementTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prescription',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: [
                  const Text('Ordonnance', style: TextStyle(fontSize: 13)),
                  Switch(
                    value: widget.createOrdonnance,
                    onChanged: (v) => widget.onCreateOrdonnanceChanged(v),
                    activeColor: AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.createOrdonnance) ...[
            // Liste des médicaments
            if (widget.medicaments.isNotEmpty) ...[
              ...List.generate(widget.medicaments.length, (index) {
                final med = widget.medicaments[index];
                final nom = med['nom']?.toString().trim() ?? '';
                final dosage = med['dosage']?.toString().trim() ?? '';
                final posologie = med['posologie']?.toString().trim() ?? '';
                final duree = med['duree']?.toString().trim() ?? '';
                
                // Construire l'affichage complet
                final dosageDisplay = dosage.isNotEmpty ? dosage : 'Dosage non spécifié';
                final posologieDisplay = posologie.isNotEmpty ? posologie : 'Posologie non spécifiée';
                final dureeDisplay = duree.isNotEmpty ? '$duree jour${int.tryParse(duree) != null && int.parse(duree) > 1 ? 's' : ''}' : 'Durée non spécifiée';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                nom.isNotEmpty ? nom : 'Médicament',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => widget.medicaments.removeAt(index)),
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dosage: $dosageDisplay',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fréquence: $posologieDisplay',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Durée: $dureeDisplay',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: () => _showAddMedicamentDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un médicament'),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Examens complémentaires',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'ECG',
              'Bilan sanguin',
              'Radiographie',
              'Échographie',
              'IRM',
              'Scanner',
            ].map((e) => _ExamenChip(label: e)).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Prochain rendez-vous',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Planifier'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  hint: const Text('Délai'),
                  items: ['1 semaine', '2 semaines', '1 mois', '3 mois', '6 mois']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Signature
          AppCard(
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user, color: AppColors.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signature électronique',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            'Dr. Fatou Diop - MED-2020-0456',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const StatusBadge(text: 'Prêt', color: AppColors.success),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Valider et signer la consultation'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMedicamentDialog(BuildContext context) {
    final nomController = TextEditingController();
    final dosageController = TextEditingController();
    final posologieController = TextEditingController();
    final dureeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un médicament'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom du médicament'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(labelText: 'Dosage (ex: 500mg)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: posologieController,
                decoration: const InputDecoration(labelText: 'Posologie (ex: 2x/jour)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dureeController,
                decoration: const InputDecoration(labelText: 'Durée (ex: 7 jours)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final nom = nomController.text.trim();
              final dosage = dosageController.text.trim();
              final posologie = posologieController.text.trim();
              final duree = dureeController.text.trim();
              
              // Validation : tous les champs obligatoires
              if (nom.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ Le nom du médicament est obligatoire')),
                );
                return;
              }
              if (dosage.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ Le dosage est obligatoire')),
                );
                return;
              }
              if (posologie.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ La fréquence est obligatoire')),
                );
                return;
              }
              if (duree.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ La durée est obligatoire')),
                );
                return;
              }
              
              setState(() {
                widget.medicaments.add({
                  'nom': nom,
                  'dosage': dosage,
                  'posologie': posologie,
                  'duree': duree,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

class _ExamenChip extends StatefulWidget {
  final String label;

  const _ExamenChip({required this.label});

  @override
  State<_ExamenChip> createState() => _ExamenChipState();
}

class _ExamenChipState extends State<_ExamenChip> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(widget.label),
      selected: _selected,
      onSelected: (v) => setState(() => _selected = v),
      selectedColor: AppColors.info.withValues(alpha: 0.2),
      checkmarkColor: AppColors.info,
    );
  }
}
