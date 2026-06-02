import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';
import 'file_saver_stub.dart' if (dart.library.io) 'file_saver_io.dart' as file_saver;

class PatientDossierScreen extends StatefulWidget {
  final String? childId;
  final String? childName;

  const PatientDossierScreen({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<PatientDossierScreen> createState() => _PatientDossierScreenState();
}

class _PatientDossierScreenState extends State<PatientDossierScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _patientData = {
    'nom': 'N/A',
    'dateNaissance': 'N/A',
    'sexe': 'N/A',
    'groupeSanguin': 'N/A',
    'phone': 'N/A',
    'email': 'N/A',
    'address': 'N/A',
  };
  List<dynamic> _consultations = [];
  List<dynamic> _exams = [];
  List<dynamic> _documents = [];
  List<dynamic> _diagnostics = [];
  String _lastUpdateDate = 'N/A';
  Map<String, dynamic> _medicalHistory = {};
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadMedicalDataAsync();
  }

  Future<void> _loadMedicalDataAsync() async {
    // Attendre que le token soit prêt
    await TokenHelper.ensureTokenReady();
    // Charger les données
    _loadMedicalData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicalData() async {
    try {
      final apiService = ApiService();
      
      // Charger le profil patient : si childId est fourni, charger le profil de l'enfant
      final profileUrl = widget.childId != null 
          ? '/patient/${widget.childId}/profile' 
          : '/patient/profile';
      final profileResponse = await apiService.get(profileUrl, requireAuth: true);
      if (kDebugMode) print('Profile Response: $profileResponse');
      
      if (profileResponse['success'] == true && profileResponse['data'] != null) {
        final patientInfo = profileResponse['data'];
        if (kDebugMode) print('Patient Info: $patientInfo');
        
        // Extraire le patient_id depuis le profil
        final patientId = patientInfo['patient_id'];
        if (kDebugMode) print('✅ Patient ID: $patientId');
        _patientId = patientId?.toString();
        
        setState(() {
          _patientData = {
            'nom': '${patientInfo['first_name'] ?? ''} ${patientInfo['last_name'] ?? ''}'.trim(),
            'dateNaissance': patientInfo['date_of_birth'] ?? 'N/A',
            'sexe': patientInfo['gender'] ?? 'N/A',
            'groupeSanguin': patientInfo['blood_group'] ?? 'N/A',
            'phone': patientInfo['phone'] ?? 'N/A',
            'email': patientInfo['email'] ?? patientInfo['user_email'] ?? 'N/A',
            'address': patientInfo['address'] ?? 'N/A',
          };
          if (kDebugMode) print('Patient Data Updated: $_patientData');
        });
        
        // Charger les antécédents médicaux
        if (patientId != null) {
          final historyResponse = await apiService.get('/medical-dossier/$patientId/summary', requireAuth: true);
          if (historyResponse['success'] == true && historyResponse['data'] != null) {
            setState(() {
              _medicalHistory = historyResponse['data'];
              if (kDebugMode) print('✅ Antécédents médicaux chargés: $_medicalHistory');
            });
          }
        }

        // Charger les consultations avec le bon patient_id
        final consultationsResponse = await apiService.get('/medical-dossier/$patientId/consultations', requireAuth: true);
        if (consultationsResponse['success'] == true && consultationsResponse['data'] != null) {
          setState(() {
            _consultations = consultationsResponse['data'] is List ? consultationsResponse['data'] : [];
            _lastUpdateDate = _getLastUpdateDate();
            if (kDebugMode) print('✅ ${_consultations.length} consultations chargées');
          });
        }

        // Charger les examens avec le bon patient_id
        final examsUrl = '/patient/$patientId/exams';
        final examsResponse = await apiService.get(examsUrl, requireAuth: true);
        if (examsResponse['success'] == true && examsResponse['data'] != null) {
          setState(() {
            // examsResponse['data'] contient: { exams: [], total: ..., page: ..., etc }
            final examsData = examsResponse['data'];
            if (examsData is Map && examsData['exams'] != null) {
              _exams = examsData['exams'] is List ? examsData['exams'] : [];
            } else if (examsData is List) {
              _exams = examsData;
            } else {
              _exams = [];
            }
            if (kDebugMode) print('✅ ${_exams.length} examens chargés');
          });
        }

        // Charger les documents médicaux du dossier patient
        if (patientId != null) {
          final documentsResponse = await apiService.get('/medical-dossier/$patientId/documents?page=1&limit=50', requireAuth: true);
          if (documentsResponse['success'] == true && documentsResponse['data'] != null) {
          setState(() {
            final documentsData = documentsResponse['data'];
            if (documentsData is Map && documentsData['documents'] != null) {
              _documents = documentsData['documents'] is List ? documentsData['documents'] : [];
            } else if (documentsData is List) {
              _documents = documentsData;
            } else {
              _documents = [];
            }
            if (kDebugMode) print('✅ ${_documents.length} documents chargés');
          });
        }
        }

        // Charger les diagnostics (via consultations qui contiennent les diagnostics)
        if (_consultations.isNotEmpty) {
          setState(() {
            _diagnostics = _consultations.where((c) => c['diagnosis'] != null && c['diagnosis'].toString().isNotEmpty).toList();
            if (kDebugMode) print('✅ ${_diagnostics.length} diagnostics extraits');
          });
        }
      } else {
        if (kDebugMode) print('Profile Response - Success: ${profileResponse['success']}, Data: ${profileResponse['data']}');
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors du chargement des données du dossier: $e');
    }
  }

  String _getLastUpdateDate() {
    if (_consultations.isEmpty) return 'N/A';
    try {
      final lastConsultation = _consultations.first;
      final date = DateTime.tryParse(lastConsultation['created_at'] ?? '');
      return date != null ? '${date.day}/${date.month}/${date.year}' : 'N/A';
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        'Mon Dossier Médical',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Dernière mise à jour: $_lastUpdateDate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      tooltip: 'Télécharger',
                    ),
                  ],
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'Résumé'),
                Tab(text: 'Consultation'),
                Tab(text: 'Examen'),
                Tab(text: 'Diagnostic'),
                Tab(text: 'Vaccination'),
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
                _ResumeTab(
                  patientData: _patientData,
                  medicalHistory: _medicalHistory,
                  patientId: _patientId,
                  childId: widget.childId,
                  childName: widget.childName,
                  onRefresh: _loadMedicalData,
                ),
                _ConsultationsTab(consultations: _consultations),
                _ExamensTab(exams: _exams),
                _DiagnosticsTab(diagnostics: _diagnostics),
                _VaccinationsTab(),
                _DocumentsTab(documents: _documents),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeTab extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final Map<String, dynamic> medicalHistory;
  final String? patientId;
  final String? childId;
  final String? childName;
  final VoidCallback onRefresh;

  const _ResumeTab({
    required this.patientData,
    required this.medicalHistory,
    this.patientId,
    this.childId,
    this.childName,
    required this.onRefresh,
  });

  @override
  State<_ResumeTab> createState() => _ResumeTabState();
}

class _ResumeTabState extends State<_ResumeTab> {
  String _formatList(dynamic value) {
    if (value == null) return 'Non renseigné';
    if (value is List) {
      if (value.isEmpty) return 'Non renseigné';
      return value.join(', ');
    }
    final str = value.toString();
    if (str.isEmpty || str == 'null') return 'Non renseigné';
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final mh = widget.medicalHistory;
    final hasMedicalData = (mh['medical_conditions'] != null && _formatList(mh['medical_conditions']) != 'Non renseigné') ||
        (mh['family_history'] != null && _formatList(mh['family_history']) != 'Non renseigné') ||
        (mh['chronic_diseases'] != null && _formatList(mh['chronic_diseases']) != 'Non renseigné') ||
        (mh['known_allergies'] != null && _formatList(mh['known_allergies']) != 'Non renseigné');

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
                    Expanded(
                      child: Text(
                        'Informations personnelles',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Nom complet', value: widget.patientData['nom'] ?? 'N/A'),
                _InfoRow(label: 'Date de naissance', value: widget.patientData['dateNaissance'] ?? 'N/A'),
                _InfoRow(label: 'Sexe', value: widget.patientData['sexe'] ?? 'N/A'),
                _InfoRow(label: 'Groupe sanguin', value: widget.patientData['groupeSanguin'] ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Informations de contact
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.contact_mail, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Informations de contact',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Téléphone', value: widget.patientData['phone'] ?? 'N/A'),
                _InfoRow(label: 'Email', value: widget.patientData['email'] ?? 'N/A'),
                _InfoRow(label: 'Adresse', value: widget.patientData['address'] ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Antécédents Médicaux
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Antécédents Médicaux',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMedicalInfoRow(
                  icon: Icons.medical_information,
                  label: 'Antécédents',
                  value: _formatList(mh['medical_conditions']),
                ),
                const SizedBox(height: 8),
                _buildMedicalInfoRow(
                  icon: Icons.family_restroom,
                  label: 'Antécédents familiaux',
                  value: _formatList(mh['family_history']),
                ),
                const SizedBox(height: 8),
                _buildMedicalInfoRow(
                  icon: Icons.favorite,
                  label: 'Maladies chroniques',
                  value: _formatList(mh['chronic_diseases']),
                ),
                const SizedBox(height: 8),
                _buildMedicalInfoRow(
                  icon: Icons.warning_amber,
                  label: 'Allergies',
                  value: _formatList(mh['known_allergies']),
                ),
                if (!hasMedicalData)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Aucun antécédent renseigné. Appuyez sur modifier pour ajouter.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isNotFilled = value == 'Non renseigné';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isNotFilled
            ? AppColors.surfaceVariant.withValues(alpha: 0.3)
            : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNotFilled
              ? Colors.transparent
              : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isNotFilled ? AppColors.textSecondary : AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isNotFilled ? AppColors.textSecondary : AppColors.textPrimary,
                    fontWeight: isNotFilled ? FontWeight.w400 : FontWeight.w600,
                    fontStyle: isNotFilled ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultationsTab extends StatelessWidget {
  final List<dynamic> consultations;

  const _ConsultationsTab({this.consultations = const []});

  @override
  Widget build(BuildContext context) {
    return consultations.isEmpty
        ? Center(
            child: Text(
              'Aucune consultation enregistrée',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: consultations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final consultation = consultations[index];
              return GestureDetector(
                onTap: () => _showConsultationDetails(context, consultation),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    consultation['doctor_name'] ?? 'Dr. Inconnu',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    consultation['speciality_name'] ?? 'Consultation générale',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          consultation['created_at'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  void _showConsultationDetails(BuildContext context, Map<String, dynamic> consultation) {
    // Chercher la date dans plusieurs champs possibles et la formater
    String formattedDate = 'Date inconnue';
    final dateField = consultation['consultation_date'] ?? 
                      consultation['created_at'] ?? 
                      consultation['date'] ?? 
                      consultation['created_date'];
    
    if (dateField != null && dateField.toString().isNotEmpty) {
      try {
        final dateObj = DateTime.parse(dateField.toString());
        formattedDate = '${dateObj.day}/${dateObj.month.toString().padLeft(2, '0')}/${dateObj.year}';
      } catch (e) {
        formattedDate = dateField.toString().split(' ')[0];
      }
    }
    
    // Récupérer les notes
    final notes = consultation['notes'] ?? consultation['observations'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Consultation - ${consultation['doctor_name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Médecin:', consultation['doctor_name'] ?? 'N/A'),
              _DetailRow('Spécialité:', consultation['speciality_name'] ?? 'N/A'),
              _DetailRow('Date:', formattedDate),
              if (consultation['diagnosis'] != null && consultation['diagnosis'].toString().isNotEmpty)
                _DetailRow('Diagnostic:', consultation['diagnosis']),
              if (consultation['treatment'] != null && consultation['treatment'].toString().isNotEmpty)
                _DetailRow('Traitement:', consultation['treatment']),
              // Afficher les notes TOUJOURS
              _DetailRow('Notes:', notes.isEmpty ? 'Aucune note enregistrée' : notes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _ExamensTab extends StatelessWidget {
  final List<dynamic> exams;

  const _ExamensTab({required this.exams});

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return Center(
        child: Text(
          'Aucun examen enregistré',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...exams.map((exam) => _ExamCard(exam: exam)).toList(),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Map<String, dynamic> exam;

  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showExamDetails(context),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam['exam_type'] ?? 'Examen',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Numéro: ${exam['exam_request_number'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(exam['exam_status'] ?? 'pending'),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(exam['exam_status'] ?? 'pending'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Spécialité',
              value: exam['speciality_name'] ?? exam['speciality_id']?.toString() ?? 'N/A',
            ),
            _InfoRow(
              label: 'Urgence',
              value: exam['urgency_level']?.toString() ?? 'Normal',
            ),
            _InfoRow(
              label: 'Date',
              value: exam['created_at']?.toString().split(' ')[0] ?? 'N/A',
            ),
            if (exam['observations'] != null && exam['observations'].isNotEmpty)
              _InfoRow(
                label: 'Observations',
                value: exam['observations'],
              ),
            const SizedBox(height: 8),
            Text(
              '👆 Cliquez pour plus de détails',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExamDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${exam['exam_type']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Numéro:', exam['exam_request_number'] ?? 'N/A'),
              _DetailRow('Type:', exam['exam_type'] ?? 'N/A'),
              _DetailRow('Spécialité:', exam['speciality_name'] ?? 'N/A'),
              _DetailRow('Statut:', _getStatusLabel(exam['exam_status'] ?? 'pending')),
              _DetailRow('Urgence:', exam['urgency_level']?.toString() ?? 'Normal'),
              _DetailRow('Date prescription:', exam['created_at']?.toString() ?? 'N/A'),
              if (exam['result_interpretation'] != null)
                _DetailRow('Interprétation:', exam['result_interpretation']),
              if (exam['observations'] != null && exam['observations'].toString().isNotEmpty)
                _DetailRow('Observations:', exam['observations']),
              if (exam['laboratory_name'] != null)
                _DetailRow('Laboratoire:', exam['laboratory_name']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (exam['exam_status'] == 'completed')
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Ouvrir document des résultats
              },
              icon: const Icon(Icons.download),
              label: const Text('Voir résultats'),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Complété';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class _DiagnosticsTab extends StatelessWidget {
  final List<dynamic> diagnostics;

  const _DiagnosticsTab({required this.diagnostics});

  @override
  Widget build(BuildContext context) {
    if (diagnostics.isEmpty) {
      return Center(
        child: Text(
          'Aucun diagnostic enregistré',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...diagnostics.map((diagnostic) => _DiagnosticCard(diagnostic: diagnostic)).toList(),
        ],
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  final Map<String, dynamic> diagnostic;

  const _DiagnosticCard({required this.diagnostic});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDiagnosticDetails(context),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    diagnostic['diagnosis'] ?? 'Diagnostic',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                // Format consultation date properly
                String formattedDate = 'N/A';
                final dateField = diagnostic['consultation_date'];
                if (dateField != null && dateField.toString().isNotEmpty) {
                  try {
                    final dateObj = DateTime.parse(dateField.toString());
                    formattedDate = '${dateObj.day}/${dateObj.month.toString().padLeft(2, '0')}/${dateObj.year}';
                  } catch (e) {
                    formattedDate = dateField.toString().split(' ')[0];
                  }
                }
                return _InfoRow(
                  label: 'Date',
                  value: formattedDate,
                );
              },
            ),
            _InfoRow(
              label: 'Médecin',
              value: '${diagnostic['doctor_first_name'] ?? ''} ${diagnostic['doctor_last_name'] ?? ''}'.trim(),
            ),
            if (diagnostic['treatment'] != null && diagnostic['treatment'].toString().isNotEmpty)
              _InfoRow(
                label: 'Traitement',
                value: diagnostic['treatment'],
              ),
            const SizedBox(height: 8),
            Text(
              '👆 Cliquez pour plus de détails',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiagnosticDetails(BuildContext context) {
    // Format consultation date properly
    String formattedDate = 'N/A';
    final dateField = diagnostic['consultation_date'];
    if (dateField != null && dateField.toString().isNotEmpty) {
      try {
        final dateObj = DateTime.parse(dateField.toString());
        formattedDate = '${dateObj.day}/${dateObj.month.toString().padLeft(2, '0')}/${dateObj.year}';
      } catch (e) {
        formattedDate = dateField.toString().split(' ')[0];
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du Diagnostic'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Diagnostic:', diagnostic['diagnosis'] ?? 'N/A'),
              _DetailRow('Date:', formattedDate),
              _DetailRow('Médecin:', '${diagnostic['doctor_first_name'] ?? ''} ${diagnostic['doctor_last_name'] ?? ''}'.trim()),
              if (diagnostic['treatment'] != null && diagnostic['treatment'].toString().isNotEmpty)
                _DetailRow('Traitement:', diagnostic['treatment']),
              if (diagnostic['notes'] != null && diagnostic['notes'].toString().isNotEmpty)
                _DetailRow('Notes:', diagnostic['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _VaccinationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Aucune vaccination enregistrée',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  final List<dynamic> documents;

  const _DocumentsTab({required this.documents});

  Future<String> _resolveDownloadUrl(String fileUrl) async {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }

    final baseUri = Uri.parse(ApiService.baseUrl);
    final origin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
    if (fileUrl.startsWith('/')) {
      return '$origin$fileUrl';
    }
    return '$origin/$fileUrl';
  }

  Future<void> _downloadDocument(BuildContext context, String fileUrl) async {
    try {
      final resolvedUrl = await _resolveDownloadUrl(fileUrl);
      final uri = Uri.parse(resolvedUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Impossible de télécharger le document (code ${response.statusCode})');
      }

      final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'document.pdf';
      final bytes = response.bodyBytes;
      await file_saver.FileSaver.saveAndOpen(bytes: bytes, fileName: fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document téléchargé: $fileName'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Erreur téléchargement document: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur téléchargement: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_present, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Aucun document disponible',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final document = documents[index] as Map<String, dynamic>;
        final title = document['document_title'] ?? 'Document';
        final type = document['document_type'] ?? 'Non spécifié';
        final date = document['upload_date'] ?? document['created_at'] ?? 'N/A';
        final fileUrl = document['file_url'] ?? document['file_path'] ?? '';

        return AppCard(
          onTap: fileUrl.isNotEmpty ? () => _downloadDocument(context, fileUrl) : null,
          child: Row(
            children: [
              const Icon(Icons.description, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Type: $type • Date: ${date.toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(
                fileUrl.isNotEmpty ? Icons.download : Icons.lock,
                color: fileUrl.isNotEmpty ? AppColors.primary : Colors.grey,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
