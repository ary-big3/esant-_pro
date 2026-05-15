import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exam_request_model.dart';
import '../../models/laboratory_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'doctor_patient_medical_history_screen.dart';

class DoctorPatientDossierScreen extends StatefulWidget {
  final String patientId;
  final String patientNom;
  final String patientPrenom;
  final int patientAge;
  final String patientGroupe;
  final String medecinId;
  final String medecinNom;

  const DoctorPatientDossierScreen({
    super.key,
    required this.patientId,
    required this.patientNom,
    required this.patientPrenom,
    required this.patientAge,
    required this.patientGroupe,
    required this.medecinId,
    required this.medecinNom,
  });

  @override
  State<DoctorPatientDossierScreen> createState() =>
      _DoctorPatientDossierScreenState();
}

class _DoctorPatientDossierScreenState extends State<DoctorPatientDossierScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showPrescriptionForm = false;
  String? _selectedSpecialite;
  List<String> _selectedExamens = [];
  String _urgence = 'normal';
  final _observationsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _observationsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.patientPrenom} ${widget.patientNom}'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_open,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dossier Médical',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'ID: ${widget.patientId} • ${widget.patientAge} ans',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.patientGroupe,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            // Onglets
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                tabs: const [
                  Tab(text: 'Résumé'),
                  Tab(text: 'Antécédents'),
                  Tab(text: 'Consultations'),
                  Tab(text: 'Examens'),
                  Tab(text: 'Vaccinations'),
                  Tab(text: 'Documents'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Contenu
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ResumeTab(),
                  _AntecedentsMedicauxTab(),
                  _ConsultationsTab(),
                  _ExamensTab(),
                  _VaccinationsTab(),
                  _DocumentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ResumeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations personnelles
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Informations personnelles',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(
                    label: 'Nom complet',
                    value: '${widget.patientPrenom} ${widget.patientNom}'),
                _InfoRow(label: 'ID Patient', value: widget.patientId),
                _InfoRow(label: 'Âge', value: '${widget.patientAge} ans'),
                _InfoRow(label: 'Groupe sanguin', value: widget.patientGroupe),
                _InfoRow(label: 'Médecin actuel', value: widget.medecinNom),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Antécédents
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Antécédents médicaux',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AntecedentChip(
                        label: 'Hypertension', color: AppColors.warning),
                    _AntecedentChip(label: 'Diabète Type 2', color: AppColors.error),
                    _AntecedentChip(label: 'Asthme', color: AppColors.info),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Allergies
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Allergies',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AllergieChip(label: 'Pénicilline'),
                    _AllergieChip(label: 'Arachides'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _ConsultationsTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _ConsultationCard(
          date: '${15 - index * 5} Jan 2026',
          medecin: 'Dr. ${index % 2 == 0 ? 'Marie Ndiaye' : 'Ibrahim Sow'}',
          specialite:
              index % 2 == 0 ? 'Médecine Générale' : 'Cardiologie',
          motif: index == 0 ? 'Consultation de suivi' : 'Contrôle routine',
          diagnostic: index == 0 ? 'État stable' : 'RAS',
        );
      },
    );
  }

  Widget _ExamensTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Bouton pour prescrire
          PrimaryButton(
            text: '+ Prescrire un examen',
            onPressed: () =>
                setState(() => _showPrescriptionForm = !_showPrescriptionForm),
            icon: Icons.add_circle_outline,
          ),
          const SizedBox(height: 16),
          // Formulaire de prescription (si visible)
          if (_showPrescriptionForm) _PrescriptionForm(
            patientId: widget.patientId,
            patientNom: widget.patientNom,
            patientPrenom: widget.patientPrenom,
            medecinId: widget.medecinId,
            medecinNom: widget.medecinNom,
            selectedSpecialite: _selectedSpecialite,
            onSpecialiteChanged: (value) =>
                setState(() {
                  _selectedSpecialite = value;
                  _selectedExamens = [];
                }),
            selectedExamens: _selectedExamens,
            onExamenToggled: (examen, selected) =>
                setState(() {
                  if (selected) {
                    _selectedExamens.add(examen);
                  } else {
                    _selectedExamens.remove(examen);
                  }
                }),
            urgence: _urgence,
            onUrgenceChanged: (value) =>
                setState(() => _urgence = value ?? 'normal'),
            observationsController: _observationsCtrl,
            onSubmit: _submitExamRequest,
            onCancel: () => setState(() => _showPrescriptionForm = false),
          ),
          const SizedBox(height: 16),
          // Examen existants
          Text(
            'Examens effectués',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final types = ['Analyse sanguine', 'ECG', 'Radiographie', 'IRM'];
              final resultats = ['Normal', 'Normal', 'RAS', 'En attente'];
              final isNormal = index != 3;

              return AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Icon(Icons.science, color: AppColors.info),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(types[index],
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            '${20 - index * 7} Jan 2026',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      text: resultats[index],
                      color: isNormal
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _VaccinationsTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final vaccins = [
          'COVID-19 (Pfizer)',
          'Grippe 2025',
          'Hépatite B',
          'Tétanos',
          'Fièvre jaune'
        ];
        final dates = [
          '15 Oct 2025',
          '10 Nov 2025',
          '05 Fév 2020',
          '12 Mar 2022',
          '20 Jan 2023'
        ];

        return AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.vaccines, color: AppColors.success),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vaccins[index],
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      dates[index],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: AppColors.success),
            ],
          ),
        );
      },
    );
  }

  Widget _DocumentsTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final docs = [
          'Compte rendu opératoire',
          'Certificat médical',
          'Ordonnance'
        ];
        final icons = [Icons.description, Icons.verified, Icons.receipt_long];

        return AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icons[index], color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(docs[index],
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'PDF • ${(index + 1) * 125} Ko',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.download, color: AppColors.primary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _AntecedentsMedicauxTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Antécédents Médicaux du Patient',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push<Map<String, dynamic>>(
                          MaterialPageRoute(
                            builder: (context) => DoctorPatientMedicalHistoryScreen(
                              patientId: widget.patientId,
                              patientName: '${widget.patientPrenom} ${widget.patientNom}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Cliquez sur "Modifier" pour éditer les antécédents médicaux du patient.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Note: Vous pouvez ajouter ici un affichage des antécédents actuels du patient
          // si les données sont disponibles dans le contexte
        ],
      ),
    );
  }

  void _submitExamRequest() {
    if (_selectedSpecialite == null || _selectedExamens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Sélectionnez une spécialité et au moins un examen'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final laboratoire = LaboratoryExamMapping.getLaboratoryBySpeciality(
        _selectedSpecialite!);
    
    if (laboratoire == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laboratoire non trouvé'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final examRequest = ExamRequestModel(
      id: 'REF-2026-${DateTime.now().millisecondsSinceEpoch}',
      patientId: widget.patientId,
      patientNom: widget.patientNom,
      patientPrenom: widget.patientPrenom,
      medecinId: widget.medecinId,
      medecinNom: widget.medecinNom,
      medecinPrenom: widget.medecinNom.split(' ').first,
      specialite: _selectedSpecialite!,
      hopitalId: 'HOP-2026-001',
      hopitalNom: 'Hôpital Principal',
      dateCreation: DateTime.now(),
      dateExamenPrevue: DateTime.now().add(const Duration(days: 3)),
      examensPrescrits: _selectedExamens,
      observations: _observationsCtrl.text,
      urgence: _urgence,
      laboratoireId: 'LAB-${_selectedSpecialite!.replaceAll(' ', '-').toUpperCase()}',
      laboratoireNom: laboratoire.nom,
      laboratoireType: laboratoire.type,
      status: ExamRequestStatus.pending,
    );

    // Afficher confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✓ Examen prescrit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
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
                          'Demande créée',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ref: ${examRequest.id}',
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
            Text('Patient: ${widget.patientPrenom} ${widget.patientNom}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text('Spécialité: $_selectedSpecialite',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text('Examens: ${_selectedExamens.length}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              'Urgence: ${_urgence == 'normal' ? 'Normal' : _urgence == 'urgent' ? 'Urgent' : 'Très urgent'}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: _getUrgencColor()),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active,
                      color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications envoyées',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '✓ Patient  •  ✓ Laboratoire',
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
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showPrescriptionForm = false;
                _selectedSpecialite = null;
                _selectedExamens = [];
                _urgence = 'normal';
                _observationsCtrl.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Examen prescrit avec succès'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getUrgencColor() {
    switch (_urgence) {
      case 'urgent':
        return AppColors.warning;
      case 'tres_urgent':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

// Widgets réutilisés
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _AntecedentChip extends StatelessWidget {
  final String label;
  final Color color;

  const _AntecedentChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }
}

class _AllergieChip extends StatelessWidget {
  final String label;

  const _AllergieChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dangerous, size: 14, color: AppColors.error),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final String date;
  final String medecin;
  final String specialite;
  final String motif;
  final String diagnostic;

  const _ConsultationCard({
    required this.date,
    required this.medecin,
    required this.specialite,
    required this.motif,
    required this.diagnostic,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(text: date, color: AppColors.primary),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textLight),
            ],
          ),
          const SizedBox(height: 12),
          Text(medecin, style: Theme.of(context).textTheme.titleMedium),
          Text(
            specialite,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Motif',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textLight,
                          ),
                    ),
                    Text(motif, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnostic',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textLight,
                          ),
                    ),
                    Text(diagnostic,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Formulaire de prescription
class _PrescriptionForm extends StatelessWidget {
  final String patientId;
  final String patientNom;
  final String patientPrenom;
  final String medecinId;
  final String medecinNom;
  final String? selectedSpecialite;
  final Function(String?) onSpecialiteChanged;
  final List<String> selectedExamens;
  final Function(String, bool) onExamenToggled;
  final String urgence;
  final Function(String?) onUrgenceChanged;
  final TextEditingController observationsController;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _PrescriptionForm({
    required this.patientId,
    required this.patientNom,
    required this.patientPrenom,
    required this.medecinId,
    required this.medecinNom,
    required this.selectedSpecialite,
    required this.onSpecialiteChanged,
    required this.selectedExamens,
    required this.onExamenToggled,
    required this.urgence,
    required this.onUrgenceChanged,
    required this.observationsController,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    List<String> examensDisponibles = selectedSpecialite != null
        ? LaboratoryExamMapping.getExamsBySpeciality(selectedSpecialite!)
        : [];

    LaboratoryInfo? laboratoire = selectedSpecialite != null
        ? LaboratoryExamMapping.getLaboratoryBySpeciality(selectedSpecialite!)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          Row(
            children: [
              const Icon(Icons.edit, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Prescrire un nouvel examen',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onCancel,
                iconSize: 20,
              ),
            ],
          ),
          const Divider(height: 16),
          const SizedBox(height: 8),
          // Info patient
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Patient: $patientPrenom $patientNom',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Spécialité
          Text(
            'Spécialité médicale',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            isExpanded: true,
            value: selectedSpecialite,
            hint: const Text('Sélectionnez une spécialité'),
            items: ['Cardiologie', 'Radiologie', 'Biologie', 'Rhumatologie', 'Gastroentérologie']
                .map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onSpecialiteChanged,
          ),
          const SizedBox(height: 16),
          // Laboratoire assigné
          if (selectedSpecialite != null && laboratoire != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital,
                      color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laboratoire assigné',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${laboratoire.nom} (${laboratoire.type})',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Examens disponibles
          if (selectedSpecialite != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Examens disponibles',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...examensDisponibles.map((examen) {
                  return CheckboxListTile(
                    title: Text(examen),
                    value: selectedExamens.contains(examen),
                    onChanged: (selected) =>
                        onExamenToggled(examen, selected ?? false),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ],
            ),
          const SizedBox(height: 16),
          // Urgence
          Text(
            'Niveau d\'urgence',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _UrgencyOption(
                label: 'Normal',
                value: 'normal',
                isSelected: urgence == 'normal',
                color: AppColors.success,
                onChanged: onUrgenceChanged,
              ),
              _UrgencyOption(
                label: 'Urgent',
                value: 'urgent',
                isSelected: urgence == 'urgent',
                color: AppColors.warning,
                onChanged: onUrgenceChanged,
              ),
              _UrgencyOption(
                label: 'Très urgent',
                value: 'tres_urgent',
                isSelected: urgence == 'tres_urgent',
                color: AppColors.error,
                onChanged: onUrgenceChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Observations
          Text(
            'Observations (optionnel)',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: observationsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ajoutez des notes ou remarques...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Boutons action
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: 'Annuler',
                  onPressed: onCancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: 'Prescrire',
                  onPressed: selectedSpecialite != null &&
                          selectedExamens.isNotEmpty
                      ? onSubmit
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UrgencyOption extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final Color color;
  final Function(String?) onChanged;

  const _UrgencyOption({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
