import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/exam_request_model.dart';
import '../../models/laboratory_model.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';

/// Écran pour prescrire des examens au laboratoire
class PrescribeExamScreen extends StatefulWidget {
  final String patientId;
  final String patientNom;
  final String? patientPrenom;
  final String medecinId;
  final String medecinNom;
  final String? medecinPrenom;

  const PrescribeExamScreen({
    super.key,
    required this.patientId,
    required this.patientNom,
    this.patientPrenom,
    required this.medecinId,
    required this.medecinNom,
    this.medecinPrenom,
  });

  @override
  State<PrescribeExamScreen> createState() => _PrescribeExamScreenState();
}

class _PrescribeExamScreenState extends State<PrescribeExamScreen> {
  String? _selectedSpecialite;
  List<String> _selectedExamens = [];
  String _urgence = 'normal';
  final _observationsCtrl = TextEditingController();
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

  @override
  void dispose() {
    _observationsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demander une analyse'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info patient
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.patientNom,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${widget.patientId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Sélection spécialité
            Text(
              'Sélectionner la spécialité',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSpecialite,
              decoration: const InputDecoration(
                labelText: 'Spécialité',
                prefixIcon: Icon(Icons.medical_services_outlined),
                hintText: 'Choisir une spécialité',
              ),
              items: AppConstants.specialites
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSpecialite = value;
                  _selectedExamens = [];
                });
              },
            ),
            const SizedBox(height: 24),
            // Afficher les examens en fonction de la spécialité sélectionnée
            if (_selectedSpecialite != null) ...[
              _LaboratorySelectionCard(speciality: _selectedSpecialite!),
              const SizedBox(height: 24),
              // Sélection des examens
              Text(
                'Examens disponibles',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              _ExamsSelectionList(
                speciality: _selectedSpecialite!,
                selectedExamens: _selectedExamens,
                onExamSelected: (exam, isSelected) {
                  setState(() {
                    if (isSelected) {
                      _selectedExamens.add(exam);
                    } else {
                      _selectedExamens.remove(exam);
                    }
                  });
                },
              ),
            ],
            const SizedBox(height: 24),
            // Urgence
            Text(
              'Niveau d\'urgence',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _UrgencyOption(
                    label: 'Normal',
                    isSelected: _urgence == 'normal',
                    color: AppColors.success,
                    onTap: () => setState(() => _urgence = 'normal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UrgencyOption(
                    label: 'Urgent',
                    isSelected: _urgence == 'urgent',
                    color: AppColors.warning,
                    onTap: () => setState(() => _urgence = 'urgent'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UrgencyOption(
                    label: 'Très urgent',
                    isSelected: _urgence == 'tres_urgent',
                    color: AppColors.error,
                    onTap: () => setState(() => _urgence = 'tres_urgent'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Observations
            Text(
              'Observations (optionnel)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _observationsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ajouter des observations cliniques...',
                prefixIcon: Align(
                  alignment: Alignment.topLeft,
                  child: Icon(Icons.note_outlined),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Boutons
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
                    text: 'Envoyer la demande',
                    onPressed: _selectedSpecialite != null && _selectedExamens.isNotEmpty
                        ? () => _submitExamRequest()
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

    void _submitExamRequest() {
    final labInfo = LaboratoryExamMapping.getLaboratoryBySpeciality(_selectedSpecialite!);
    if (labInfo == null) return;

    // Créer la demande d'examen
    final examRequest = ExamRequestModel(
      id: 'REF-2026-${DateTime.now().millisecondsSinceEpoch}',
      patientId: widget.patientId,
      patientNom: widget.patientNom,
      patientPrenom: widget.patientPrenom,
      medecinId: widget.medecinId,
      medecinNom: widget.medecinNom,
      medecinPrenom: widget.medecinPrenom,
      specialite: _selectedSpecialite!,
      hopitalId: 'HOPITAL_001', // À remplacer par l'ID réel
      hopitalNom: 'Hôpital Principal',
      dateCreation: DateTime.now(),
      dateExamenPrevue: DateTime.now().add(const Duration(days: 2)),
      examensPrescrits: _selectedExamens,
      observations: _observationsCtrl.text.isNotEmpty ? _observationsCtrl.text : null,
      urgence: _urgence,
      status: ExamRequestStatus.pending,
      laboratoireId: '', // Vide - le backend récupérera via laboratory_assignment
      laboratoireNom: labInfo.nom,
      laboratoireType: labInfo.type,
    );

    // Sauvegarder dans la base de données avant d'afficher le dialogue
    _saveExamRequestToDatabase(examRequest);
  }

  Future<void> _saveExamRequestToDatabase(ExamRequestModel examRequest) async {
    try {
      await TokenHelper.ensureTokenReady();

      final response = await _apiService.post(
        '/exams',
        body: {
          'patient_id': examRequest.patientId,
          'exams': examRequest.examensPrescrits,
          'specialite': examRequest.specialite,
          'urgence': examRequest.urgence,
          'observations': examRequest.observations ?? '',
          'laboratory_id': examRequest.laboratoireId,
          'date': examRequest.dateCreation.toString(),
        },
      );

      if (response['success'] == true) {
        _showExamConfirmationDialog();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${response['message'] ?? "Erreur lors de la sauvegarde"}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
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
    }
  }

  void _showExamConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✓ Demande d\'examen envoyée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Numéro de la demande
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Numéro de demande',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.patientId,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Infos du patient
            Text('Informations du patient', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${widget.patientNom}${widget.patientPrenom != null ? ' ${widget.patientPrenom}' : ''}'),
            const SizedBox(height: 8),
            Text('ID Patient: ${widget.patientId}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            // Infos du médecin
            Text('Médecin prescripteur', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${widget.medecinNom}${widget.medecinPrenom != null ? ' ${widget.medecinPrenom}' : ''}'),
            const SizedBox(height: 16),
            // Infos de la demande
            Text('Détails de la demande', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Spécialité: $_selectedSpecialite'),
            const SizedBox(height: 8),
            Text('Examens: ${_selectedExamens.join(", ")}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications envoyées',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Patient: Notification de prescription\n• Laboratoire: Nouvelle demande d\'examen',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Demande d\'examen prescrite et sauvegardée'),
                    backgroundColor: AppColors.success,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Affiche les infos du laboratoire pour une spécialité
class _LaboratorySelectionCard extends StatelessWidget {
  final String speciality;

  const _LaboratorySelectionCard({required this.speciality});

  @override
  Widget build(BuildContext context) {
    final labInfo = LaboratoryExamMapping.getLaboratoryBySpeciality(speciality);
    
    if (labInfo == null) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laboratoire assigné',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labInfo.nom,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              labInfo.type,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

/// Liste des examens disponibles pour sélection
class _ExamsSelectionList extends StatelessWidget {
  final String speciality;
  final List<String> selectedExamens;
  final Function(String, bool) onExamSelected;

  const _ExamsSelectionList({
    required this.speciality,
    required this.selectedExamens,
    required this.onExamSelected,
  });

  @override
  Widget build(BuildContext context) {
    final examens = LaboratoryExamMapping.getExamsBySpeciality(speciality);

    return Column(
      children: examens
          .map((exam) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CheckboxListTile(
          title: Text(exam),
          value: selectedExamens.contains(exam),
          onChanged: (value) => onExamSelected(exam, value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          tileColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ))
          .toList(),
    );
  }
}

/// Option d'urgence
class _UrgencyOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _UrgencyOption({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.surfaceVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? color : AppColors.textLight,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
