import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/laboratory_service.dart';

/// Écran principal du laboratoire pour gérer les demandes d'examens
class LaboratoryScreen extends StatefulWidget {
  const LaboratoryScreen({super.key});

  @override
  State<LaboratoryScreen> createState() => _LaboratoryScreenState();
}

class _LaboratoryScreenState extends State<LaboratoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LaboratoryService _laboratoryService = LaboratoryService();
  late Future<Map<String, dynamic>> _pendingExamsFuture;
  late Future<Map<String, dynamic>> _inProgressExamsFuture;
  late Future<Map<String, dynamic>> _completedExamsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  void _loadData() {
    _pendingExamsFuture = _laboratoryService.getPendingExams();
    _inProgressExamsFuture = _laboratoryService.getInProgressExams();
    _completedExamsFuture = _laboratoryService.getCompletedExams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laboratoire Central',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analyses médicales & Imagerie',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.science, color: AppColors.primary),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          // Statistiques rapides
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: Future.wait<Map<String, dynamic>>([
                _pendingExamsFuture,
                _inProgressExamsFuture,
                _completedExamsFuture,
              ]),
              builder: (context, snapshot) {
                int pendingCount = 0;
                int inProgressCount = 0;
                int completedCount = 0;

                if (snapshot.hasData && snapshot.data!.length == 3) {
                  pendingCount = (snapshot.data![0]['exams'] as List?)?.length ?? 0;
                  inProgressCount = (snapshot.data![1]['exams'] as List?)?.length ?? 0;
                  completedCount = (snapshot.data![2]['exams'] as List?)?.length ?? 0;
                }

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'En attente',
                        count: pendingCount.toString(),
                        color: AppColors.warning,
                        icon: Icons.hourglass_empty,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'En cours',
                        count: inProgressCount.toString(),
                        color: AppColors.info,
                        icon: Icons.refresh,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Complétées',
                        count: completedCount.toString(),
                        color: AppColors.success,
                        icon: Icons.check_circle,
                      ),
                    ),
                  ],
                );
              },
            ),
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 16),
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'En attente'),
                Tab(text: 'En cours'),
                Tab(text: 'Complétées'),
                Tab(text: 'Historique'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PendingExamsTab(future: _pendingExamsFuture, onRefresh: _loadData),
                _InProgressExamsTab(future: _inProgressExamsFuture, onRefresh: _loadData),
                _CompletedExamsTab(future: _completedExamsFuture),
                _HistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab des demandes en attente
class _PendingExamsTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final VoidCallback onRefresh;

  const _PendingExamsTab({
    required this.future,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        return Future.delayed(const Duration(seconds: 1));
      },
      child: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          final exams = (snapshot.data?['exams'] as List?) ?? [];

          if (exams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune demande en attente',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: exams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final exam = exams[index] as Map<String, dynamic>;
              return _ExamRequestCard(
                exam: exam,
                status: 'pending',
                onAccept: () async {
                  final service = LaboratoryService();
                  try {
                    await service.startExam(exam['exam_id']?.toString() ?? '');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Examen pris en charge'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    onRefresh();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ).animate(delay: Duration(milliseconds: index * 100)).fadeIn(duration: 400.ms);
            },
          );
        },
      ),
    );
  }
}

/// Tab des demandes en cours
class _InProgressExamsTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final VoidCallback onRefresh;

  const _InProgressExamsTab({
    required this.future,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        return Future.delayed(const Duration(seconds: 1));
      },
      child: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          final exams = (snapshot.data?['exams'] as List?) ?? [];

          if (exams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun examen en cours',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: exams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final exam = exams[index] as Map<String, dynamic>;
              return _ExamRequestCard(
                exam: exam,
                status: 'in_progress',
                onComplete: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _ResultsBottomSheet(
                      examId: exam['exam_id']?.toString() ?? '',
                      onSave: () {
                        onRefresh();
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ).animate(delay: Duration(milliseconds: index * 100)).fadeIn(duration: 400.ms);
            },
          );
        },
      ),
    );
  }
}

/// Tab des demandes complétées
class _CompletedExamsTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;

  const _CompletedExamsTab({required this.future});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        return Future.delayed(const Duration(seconds: 1));
      },
      child: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          final exams = (snapshot.data?['exams'] as List?) ?? [];

          if (exams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun examen complété',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: exams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final exam = exams[index] as Map<String, dynamic>;
              return _ExamRequestCard(
                exam: exam,
                status: 'completed',
                isCompleted: true,
              ).animate(delay: Duration(milliseconds: index * 100)).fadeIn(duration: 400.ms);
            },
          );
        },
      ),
    );
  }
}

/// Tab historique
class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 48, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(
            'Filtrez par date ou patient',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez une plage de dates pour voir l\'historique',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Carte pour afficher une demande d'examen
class _ExamRequestCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final String status;
  final VoidCallback? onAccept;
  final VoidCallback? onComplete;
  final bool isCompleted;

  const _ExamRequestCard({
    required this.exam,
    required this.status,
    this.onAccept,
    this.onComplete,
    this.isCompleted = false,
  });

  Color _getUrgenceColor() {
    final urgency = exam['urgency_level']?.toString() ?? 'normal';
    switch (urgency) {
      case 'urgent':
        return AppColors.warning;
      case 'tres_urgent':
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }

  String _getUrgenceLabel() {
    final urgency = exam['urgency_level']?.toString() ?? 'normal';
    switch (urgency) {
      case 'urgent':
        return 'Urgent';
      case 'tres_urgent':
        return 'Très urgent';
      default:
        return 'Normal';
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Complété';
      default:
        return status;
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = '${exam['patient_first_name'] ?? ''} ${exam['patient_last_name'] ?? ''}'.trim();
    final doctorName = 'Dr. ${exam['doctor_first_name'] ?? ''} ${exam['doctor_last_name'] ?? ''}'.replaceAll('  ', ' ').trim();
    final speciality = exam['speciality_name'] ?? '';
    final examType = exam['exam_type'] ?? '';
    final examRef = exam['exam_request_number'] ?? '#${exam['exam_id'] ?? ''}';
    final createdAt = exam['created_at']?.toString() ?? '';
    final dateStr = createdAt.length >= 10 ? createdAt.substring(8, 10) + '/' + createdAt.substring(5, 7) + '/' + createdAt.substring(0, 4) : '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    examRef,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patientName.isNotEmpty ? patientName : 'Patient inconnu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getUrgenceColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getUrgenceLabel(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getUrgenceColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.textLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  doctorName,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.textLight),
              const SizedBox(width: 8),
              Text(
                speciality,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (examType.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                examType,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              StatusBadge(text: _getStatusLabel(), color: _getStatusColor()),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 12),
            if (status == 'pending')
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Prendre en charge',
                  onPressed: onAccept,
                ),
              )
            else if (status == 'in_progress')
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Ajouter les résultats',
                  onPressed: onComplete,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Statistique rapide
class _StatCard extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            count,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// BottomSheet pour uploader un document résultat (PDF/image)
class _ResultsBottomSheet extends StatefulWidget {
  final String examId;
  final VoidCallback onSave;

  const _ResultsBottomSheet({
    required this.examId,
    required this.onSave,
  });

  @override
  State<_ResultsBottomSheet> createState() => _ResultsBottomSheetState();
}

class _ResultsBottomSheetState extends State<_ResultsBottomSheet> {
  List<int>? _fileBytes;
  String? _fileName;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _fileBytes = result.files.single.bytes!;
          _fileName = result.files.single.name;
        });
      } else if (result != null && result.files.single.path != null) {
        // Fallback: lire le fichier depuis le path (mobile)
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        setState(() {
          _fileBytes = bytes;
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _uploadResult() async {
    if (_fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un fichier'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = LaboratoryService();
      await service.uploadResultDocument(
        widget.examId,
        _fileBytes!,
        _fileName ?? 'resultat.pdf',
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Résultat envoyé avec succès'),
          backgroundColor: AppColors.success,
        ),
      );

      widget.onSave();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Envoyer les résultats',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Uploadez le document PDF ou l\'image des résultats',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Zone de sélection de fichier
            GestureDetector(
              onTap: _isLoading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _fileBytes != null ? AppColors.success : AppColors.surfaceVariant,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _fileBytes != null
                      ? AppColors.success.withValues(alpha: 0.05)
                      : AppColors.surfaceVariant.withValues(alpha: 0.3),
                ),
                child: Column(
                  children: [
                    Icon(
                      _fileBytes != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                      size: 40,
                      color: _fileBytes != null ? AppColors.success : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fileName ?? 'Cliquez pour sélectionner un fichier',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _fileBytes != null ? AppColors.success : AppColors.textSecondary,
                        fontWeight: _fileBytes != null ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, JPG, PNG acceptés',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Description optionnelle
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ex: Bilan sanguin complet',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: _isLoading ? 'Envoi en cours...' : 'Envoyer le résultat',
                onPressed: _isLoading ? null : _uploadResult,
                icon: _isLoading ? null : Icons.send,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
