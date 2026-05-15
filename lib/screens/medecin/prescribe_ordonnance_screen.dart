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

  const PrescribeOrdonnanceScreen({
    super.key,
    required this.patientNom,
    required this.patientPrenom,
    required this.patientId,
    required this.medecinNom,
  });

  @override
  State<PrescribeOrdonnanceScreen> createState() =>
      _PrescribeOrdonnanceScreenState();
}

class _PrescribeOrdonnanceScreenState extends State<PrescribeOrdonnanceScreen> {
  final List<Map<String, String>> _medicaments = [];
  late ApiService _apiService;
  bool _isSaving = false;
  final _nomController = TextEditingController();
  final _dosageController = TextEditingController();
  final _posologieController = TextEditingController();
  final _dureeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _dosageController.dispose();
    _posologieController.dispose();
    _dureeController.dispose();
    super.dispose();
  }

  void _addMedicament() {
    if (_nomController.text.isEmpty ||
        _dosageController.text.isEmpty ||
        _posologieController.text.isEmpty ||
        _dureeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remplissez tous les champs'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _medicaments.add({
        'medication_name': _nomController.text,
        'dosage': _dosageController.text,
        'dosage_unit': 'mg',
        'frequency': _posologieController.text,
        'duration': _dureeController.text,
        'route_of_administration': 'oral',
        'special_instructions': '',
      });
    });

    _nomController.clear();
    _dosageController.clear();
    _posologieController.clear();
    _dureeController.clear();
  }

  void _removeMedicament(int index) {
    setState(() => _medicaments.removeAt(index));
  }

  Future<void> _saveOrdonnanceToDatabase() async {
    try {
      setState(() => _isSaving = true);
      await TokenHelper.ensureTokenReady();

      final response = await _apiService.post(
        '/prescriptions',
        body: {
          'patient_id': widget.patientId,
          'medications': _medicaments,
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
    if (_medicaments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins un médicament'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Afficher confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✓ Ordonnance créée'),
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
              'Médicaments: ${_medicaments.length}',
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
                  ..._medicaments.map((med) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '✓ ${med['nom']} ${med['dosage']} - ${med['posologie']}',
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
                          '✓ Patient de ${widget.patientPrenom} ${widget.patientNom}',
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
                          const SnackBar(
                            content: Text('✓ Ordonnance prescrite et sauvegardée'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prescrire une Ordonnance'),
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
                    child: const Icon(Icons.person,
                        color: AppColors.primary, size: 24),
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
            // Titre section médicaments
            Text(
              'Médicamentos à prescrire',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Formulaire ajout médicament
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajouter un médicament',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nomController,
                    decoration: InputDecoration(
                      hintText: 'Nom du médicament (ex: Amoxicilline)',
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
                          controller: _dosageController,
                          decoration: InputDecoration(
                            hintText: 'Dosage (ex: 500mg)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _posologieController,
                          decoration: InputDecoration(
                            hintText: 'Posologie (ex: 2x/jour)',
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
                    controller: _dureeController,
                    decoration: InputDecoration(
                      hintText: 'Durée (ex: 7 jours)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addMedicament,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter le médicament'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Liste des médicaments
            if (_medicaments.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 48,
                        color: AppColors.textLight.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun médicament ajouté',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _medicaments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final med = _medicaments[index];
                  return AppCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.medication,
                              color: AppColors.secondary, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med['medication_name']!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${med['dosage']} ${med['dosage_unit']} • ${med['frequency']} • ${med['duration']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeMedicament(index),
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                        ),
                      ],
                    ),
                  );
                },
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
                    text: 'Prescrire l\'ordonnance',
                    onPressed:
                        _medicaments.isEmpty ? null : _submitOrdonnance,
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
