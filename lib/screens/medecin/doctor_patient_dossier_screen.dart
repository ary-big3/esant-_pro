import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';
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
  late ApiService _apiService;
  final _observationsCtrl = TextEditingController();
  
  // Données chargées depuis l'API
  List<Map<String, dynamic>> _prescriptions = [];
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _consultations = [];
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _vaccinations = [];
  Map<String, dynamic>? _dossierResume;
  bool _isLoadingPrescriptions = false;
  bool _isLoadingExams = false;
  bool _isLoadingConsultations = false;
  bool _isLoadingDocuments = false;
  bool _isLoadingVaccinations = false;
  bool _isLoadingDossier = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    // Charger les données initiales
    _loadDossierResume();
    _loadConsultations();
    _loadPrescriptions();
    _loadExams();
  }

  // Recharger quand l'onglet change
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    if (_tabController.index == 0) {
      _loadDossierResume();
    } else if (_tabController.index == 2) {
      _loadConsultations();
    } else if (_tabController.index == 3) {
      _loadExams();
    } else if (_tabController.index == 4) {
      _loadPrescriptions();
    } else if (_tabController.index == 5) {
      _loadVaccinations();
    } else if (_tabController.index == 6) {
      _loadDocuments();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _observationsCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _sanitizeNullValues(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    data.forEach((key, value) {
      if (value == null) {
        sanitized[key] = '';
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeNullValues(value);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _sanitizeNullValues(item);
          }
          return item ?? '';
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }
  
  Future<void> _loadPrescriptions() async {
    if (!mounted) return;
    setState(() => _isLoadingPrescriptions = true);
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get(
        '/doctor/patients/${widget.patientId}/prescriptions?page=1&limit=50',
        requireAuth: true,
      );
      if (response['success'] == true && mounted) {
        setState(() {
          _prescriptions = List<Map<String, dynamic>>.from(
            (response['data'] ?? [])
              .map((p) => _sanitizeNullValues(p as Map<String, dynamic>))
              .toList()
          );
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement ordonnances: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPrescriptions = false);
    }
  }
  
  Future<void> _loadExams() async {
    if (!mounted) return;
    setState(() => _isLoadingExams = true);
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get(
        '/doctor/patients/${widget.patientId}/exams?page=1&limit=50',
        requireAuth: true,
      );
      if (response['success'] == true && mounted) {
        setState(() {
          _exams = List<Map<String, dynamic>>.from(
            (response['data'] ?? [])
              .map((e) => _sanitizeNullValues(e as Map<String, dynamic>))
              .toList()
          );
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement examens: $e');
    } finally {
      if (mounted) setState(() => _isLoadingExams = false);
    }
  }
  
  Future<void> _loadConsultations() async {
    if (!mounted) return;
    setState(() => _isLoadingConsultations = true);
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get(
        '/doctor/patients/${widget.patientId}/consultations?page=1&limit=50',
        requireAuth: true,
      );
      if (response['success'] == true && mounted) {
        setState(() {
          _consultations = List<Map<String, dynamic>>.from(
            (response['data'] ?? [])
              .map((c) => _sanitizeNullValues(c as Map<String, dynamic>))
              .toList()
          );
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement consultations: $e');
    } finally {
      if (mounted) setState(() => _isLoadingConsultations = false);
    }
  }

  Future<void> _loadDossierResume() async {
    if (!mounted) return;
    setState(() => _isLoadingDossier = true);
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get(
        '/doctor/patients/${widget.patientId}/dossier',
        requireAuth: true,
      );
      if (response['success'] == true && mounted) {
        setState(() {
          _dossierResume = response['data'] ?? {};
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement résumé dossier: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDossier = false);
    }
  }

  Future<void> _loadDocuments() async {
    if (!mounted) return;
    setState(() => _isLoadingDocuments = true);
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get(
        '/doctor/patients/${widget.patientId}/documents?page=1&limit=50',
        requireAuth: true,
      );
      if (response['success'] == true && mounted) {
        setState(() {
          _documents = List<Map<String, dynamic>>.from(
            (response['data'] ?? [])
              .map((d) => _sanitizeNullValues(d as Map<String, dynamic>))
              .toList()
          );
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement documents: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDocuments = false);
    }
  }

  Future<void> _loadVaccinations() async {
    if (!mounted) return;
    setState(() => _isLoadingVaccinations = true);
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get(
        '/doctor/patients/${widget.patientId}/allergies?page=1&limit=50',
        requireAuth: true,
      );
      if (response['success'] == true && mounted) {
        setState(() {
          _vaccinations = List<Map<String, dynamic>>.from(
            (response['data'] ?? [])
              .map((v) => _sanitizeNullValues(v as Map<String, dynamic>))
              .toList()
          );
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement vaccinations: $e');
    } finally {
      if (mounted) setState(() => _isLoadingVaccinations = false);
    }
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
            // En-tête du patient
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
                    child: const Icon(Icons.folder_open, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dossier Médical', style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          'ID: ${widget.patientId} • ${widget.patientAge} ans',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.info),
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
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                tabs: const [
                  Tab(text: 'Résumé'),
                  Tab(text: 'Antécédents'),
                  Tab(text: 'Consultations'),
                  Tab(text: 'Examens'),
                  Tab(text: 'Ordonnances'),
                  Tab(text: 'Vaccinations'),
                  Tab(text: 'Documents'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ResumeTab(),
                  _AntecedentsMedicauxTab(),
                  _ConsultationsTab(),
                  _ExamensTab(),
                  _OrdonnancesTab(),
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

  // --- TAB: CONSULTATIONS ---
  Widget _ConsultationsTab() {
    if (_isLoadingConsultations) return const Center(child: CircularProgressIndicator());
    if (_consultations.isEmpty) return _buildEmptyState('Aucune consultation');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _consultations.length,
      itemBuilder: (context, index) {
        final c = _consultations[index];
        
        // Extraction des données avec fallbacks
        final docFirstName = c['doctor_first_name'] ?? c['first_name'] ?? '';
        final docLastName = c['doctor_last_name'] ?? c['last_name'] ?? '';
        final docName = 'Dr. ${docFirstName} ${docLastName}'.trim();
        final speciality = c['speciality_name'] ?? c['speciality'] ?? 'Médecine générale';
        final dateStr = _formatDateTime(c['consultation_date'] ?? c['created_at']);
        final motif = c['chief_complaint'] ?? c['reason_for_visit'] ?? 'Consultation de suivi';
        final diagnostic = c['diagnosis'] ?? '';
        final notes = c['notes'] ?? c['observations'] ?? '';

        return AppCard(
          margin: const EdgeInsets.only(bottom: 16),
          onTap: () => _showConsultationDetails(c),
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
                        Text(docName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(speciality, style: TextStyle(fontSize: 12, color: AppColors.primary.withOpacity(0.8))),
                      ],
                    ),
                  ),
                  Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow('Motif', motif, isTitle: true),
              if (diagnostic.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Diagnostic', diagnostic, isHighlight: true),
                const SizedBox(height: 8),
                _buildInfoRow('Statut', 'Terminée après diagnostic', isHighlight: true),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Notes', notes),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Voir détails ➔', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB: EXAMENS ---
  Widget _ExamensTab() {
    if (_isLoadingExams) return const Center(child: CircularProgressIndicator());
    if (_exams.isEmpty) return _buildEmptyState('Aucun examen enregistré');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        
        final type = exam['exam_type'] ?? 'Examen médical';
        final number = exam['exam_request_number'] ?? exam['exam_id'] ?? 'N/A';
        final status = exam['exam_status'] ?? exam['status'] ?? 'pending';
        final date = _formatDate(exam['exam_date'] ?? exam['created_at']);
        final speciality = exam['speciality_name'] ?? exam['specialty_name'] ?? 'Spécialité non définie';
        final laboratory = exam['laboratory_name'] ?? exam['lab_name'] ?? 'Laboratoire non spécifié';
        final docName = 'Dr. ${exam['doctor_first_name'] ?? ''} ${exam['doctor_last_name'] ?? ''}'.trim();
        final obs = exam['observations'] ?? '';
        
        // Liste des examens spécifiques
        final details = exam['exams'] as List? ?? [];
        final detailsNames = details.map((e) => e['name'] ?? e['exam_type'] ?? 'Examen').join(', ');

        return AppCard(
          margin: const EdgeInsets.only(bottom: 16),
          onTap: () => _showExamDetails(exam),
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
                        Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(speciality, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 4),
              Text('ID: $number', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const Divider(height: 24),
              if (docName.trim().isNotEmpty)
                _buildInfoRow('Prescripteur', docName),
              _buildInfoRow('Laboratoire', laboratory),
              _buildInfoRow('Date', date),
              if (detailsNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Examens prescrits', detailsNames, isHighlight: true),
              ],
              if (obs.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Observations', obs),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Détails complets ➔', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB: ORDONNANCES ---
  Widget _OrdonnancesTab() {
    if (_isLoadingPrescriptions) return const Center(child: CircularProgressIndicator());
    if (_prescriptions.isEmpty) return _buildEmptyState('Aucune ordonnance');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prescriptions.length,
      itemBuilder: (context, index) {
        final p = _prescriptions[index];
        
        final docName = 'Dr. ${p['doctor_first_name'] ?? ''} ${p['doctor_last_name'] ?? ''}'.trim();
        final speciality = p['speciality_name'] ?? 'Médecine';
        final date = _formatDateTime(p['prescription_date'] ?? p['created_at']);
        final issueDate = _formatDate(p['issue_date']);
        final expiryDate = _formatDate(p['expiry_date']);
        final status = p['status'] ?? 'active';
        final isValid = status.toString().toLowerCase().contains('act');
        final medications = p['medications'] as List? ?? [];
        final notes = p['notes'] ?? p['observations'] ?? '';
        final hospital = p['hospital_name'] ?? '';
        final rxNumber = p['prescription_number'] ?? 'N/A';

        return AppCard(
          margin: const EdgeInsets.only(bottom: 16),
          onTap: () => _showPrescriptionDetails(p),
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
                        Text(docName.isNotEmpty ? docName : 'Médecin inconnu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(speciality, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        if (hospital.isNotEmpty)
                          Text(hospital, style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isValid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isValid ? Colors.green : Colors.orange, width: 0.5),
                    ),
                    child: Text(
                      isValid ? 'VALIDE' : 'EXPIRÉE',
                      style: TextStyle(color: isValid ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rx: $rxNumber', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              if (issueDate.isNotEmpty || expiryDate.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Du $issueDate au $expiryDate',
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
              const Divider(height: 24),
              if (notes.isNotEmpty) ...[
                _buildInfoRow('Instructions', notes),
                const SizedBox(height: 12),
              ],
              if (medications.isNotEmpty) ...[
                const Text('Médicaments :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ...medications.take(3).map((m) {
                  final name = m['medication_name'] ?? m['name'] ?? 'Médicament';
                  final dosage = '${m['dosage'] ?? ''} ${m['dosage_unit'] ?? ''}'.trim();
                  final freq = m['frequency'] ?? '';
                  final duration = m['duration'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$name ${dosage.isNotEmpty ? '($dosage)' : ''} $freq ${duration.isNotEmpty ? 'x $duration' : ''}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (medications.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('+ ${medications.length - 3} autres...', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Afficher l\'ordonnance ➔', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, bool isTitle = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text('$label:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isTitle ? 14 : 13,
              fontWeight: (isHighlight || isTitle) ? FontWeight.w600 : FontWeight.normal,
              color: isHighlight ? AppColors.primary : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'completed': color = Colors.green; label = 'Complété'; break;
      case 'in_progress': color = Colors.blue; label = 'En cours'; break;
      case 'pending': color = Colors.orange; label = 'En attente'; break;
      case 'cancelled': color = Colors.red; label = 'Annulé'; break;
      default: color = Colors.grey; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateInput) {
    if (dateInput == null || dateInput.toString().isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateInput.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateInput.toString().split(' ').first;
    }
  }

  String _formatDateTime(dynamic dateInput) {
    if (dateInput == null || dateInput.toString().isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateInput.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateInput.toString();
    }
  }

  // --- RESTE DU CODE (TAB RÉSUMÉ, DOCUMENTS, ETC.) ---
  // (Inclusion des méthodes existantes pour assurer la compilation)

  Widget _ResumeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text('Informations Patient', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const Divider(height: 32),
                _InfoRowStatic(label: 'Nom Complet', value: '${widget.patientPrenom} ${widget.patientNom}'),
                _InfoRowStatic(label: 'Âge', value: '${widget.patientAge} ans'),
                _InfoRowStatic(label: 'Groupe Sanguin', value: widget.patientGroupe),
                _InfoRowStatic(label: 'ID Dossier', value: widget.patientId),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Résumé du dossier médical
          if (_isLoadingDossier)
            const Center(child: CircularProgressIndicator())
          else if (_dossierResume != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medical_services, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Text('Dossier Médical', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const Divider(height: 32),
                  if (_dossierResume!['allergies'] != null)
                    _InfoRowStatic(label: 'Allergies', value: _dossierResume!['allergies'] ?? 'Aucune'),
                  if (_dossierResume!['chronic_diseases'] != null)
                    _InfoRowStatic(label: 'Maladies Chroniques', value: _dossierResume!['chronic_diseases'] ?? 'Aucune'),
                  if (_dossierResume!['surgeries'] != null)
                    _InfoRowStatic(label: 'Chirurgies', value: _dossierResume!['surgeries'] ?? 'Aucune'),
                  if (_dossierResume!['medications'] != null)
                    _InfoRowStatic(label: 'Médicaments Actuels', value: _dossierResume!['medications'] ?? 'Aucun'),
                ],
              ),
            ),
          const SizedBox(height: 20),
          
          // Dernière consultation
          if (_consultations.isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.info),
                      const SizedBox(width: 12),
                      Text('Dernière Consultation', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const Divider(height: 32),
                  _InfoRowStatic(
                    label: 'Date',
                    value: _formatDateTime(_consultations[0]['consultation_date'] ?? _consultations[0]['created_at']),
                  ),
                  _InfoRowStatic(
                    label: 'Médecin',
                    value: 'Dr. ${_consultations[0]['doctor_first_name'] ?? ''} ${_consultations[0]['doctor_last_name'] ?? ''}',
                  ),
                  _InfoRowStatic(
                    label: 'Motif',
                    value: _consultations[0]['reason_for_visit'] ?? 'Non spécifié',
                  ),
                ],
              ),
            ),
        ],
      ),
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
                    Text('Antécédents Médicaux', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Cliquez sur "Modifier" pour éditer les antécédents médicaux du patient.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _VaccinationsTab() {
    if (_isLoadingVaccinations) return const Center(child: CircularProgressIndicator());
    if (_vaccinations.isEmpty) return _buildEmptyState('Aucune allergie/vaccination enregistrée');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _vaccinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final v = _vaccinations[index];
        final name = v['allergy_name'] ?? v['name'] ?? 'Allergie/Vaccin';
        final type = v['allergy_type'] ?? v['type'] ?? 'Non spécifié';
        final severity = v['severity'] ?? 'Moyen';
        
        return AppCard(
          child: Row(
            children: [
              const Icon(Icons.vaccines, color: AppColors.success),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      'Type: $type | Sévérité: $severity',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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
    if (_isLoadingDocuments) return const Center(child: CircularProgressIndicator());
    if (_documents.isEmpty) return _buildEmptyState('Aucun document enregistré');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = _documents[index];
        final title = doc['document_title'] ?? doc['title'] ?? 'Document';
        final type = doc['document_type'] ?? doc['type'] ?? 'Non spécifié';
        final date = _formatDate(doc['upload_date'] ?? doc['created_at']);
        final url = doc['file_url'] ?? doc['document_url'] ?? '';
        
        return AppCard(
          onTap: url.isNotEmpty ? () {
            // Ouvrir le document (à implémenter)
          } : null,
          child: Row(
            children: [
              const Icon(Icons.description, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      'Type: $type | Date: $date',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (url.isNotEmpty)
                const Icon(Icons.download, color: AppColors.primary)
              else
                const Icon(Icons.lock, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  // --- DIALOGS ---
  void _showConsultationDetails(Map<String, dynamic> c) {
    final docName = 'Dr. ${c['doctor_first_name'] ?? ''} ${c['doctor_last_name'] ?? ''}'.trim();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails Consultation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Médecin', docName.isNotEmpty ? docName : 'Médecin inconnu'),
              _buildDetailItem('Spécialité', c['speciality_name'] ?? c['speciality'] ?? 'Médecine générale'),
              _buildDetailItem('Type', c['consultation_type'] ?? 'En personne'),
              _buildDetailItem('Statut', c['consultation_status'] ?? 'completed'),
              _buildDetailItem('Date', _formatDateTime(c['consultation_date'] ?? c['created_at'])),
              if (c['future_date_follow_up'] != null && c['future_date_follow_up'].toString().isNotEmpty)
                _buildDetailItem('Suivi prévu', _formatDate(c['future_date_follow_up'])),
              const Divider(),
              _buildDetailItem('Motif de visite', c['reason_for_visit'] ?? c['chief_complaint'] ?? 'Non spécifié'),
              _buildDetailItem('Plainte principale', c['chief_complaint'] ?? 'Non spécifiée'),
              _buildDetailItem('Diagnostic', c['diagnosis'] ?? 'En cours d\'évaluation'),
              _buildDetailItem('Statut', c['diagnosis'] != null && c['diagnosis'].toString().trim().isNotEmpty ? 'Terminée après diagnostic' : (c['consultation_status'] ?? 'En attente')), 
              _buildDetailItem('Notes', c['notes'] ?? c['observations'] ?? 'Aucune note'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  void _showPrescriptionDetails(Map<String, dynamic> p) {
    final meds = p['medications'] as List? ?? [];
    final docName = 'Dr. ${p['doctor_first_name'] ?? ''} ${p['doctor_last_name'] ?? ''}'.trim();
    final status = p['status'] ?? 'active';
    final isValid = status.toString().toLowerCase().contains('act');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails Ordonnance'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Médecin', docName.isNotEmpty ? docName : 'Médecin inconnu'),
              _buildDetailItem('Spécialité', p['speciality_name'] ?? 'Non spécifiée'),
              if (p['hospital_name'] != null && p['hospital_name'].toString().isNotEmpty)
                _buildDetailItem('Hôpital', p['hospital_name']),
              _buildDetailItem('Numéro', p['prescription_number'] ?? 'N/A'),
              _buildDetailItem('Statut', isValid ? 'VALIDE' : 'EXPIRÉE'),
              _buildDetailItem('Date d\'émission', _formatDate(p['issue_date'])),
              _buildDetailItem('Date d\'expiration', _formatDate(p['expiry_date'])),
              _buildDetailItem('Date de création', _formatDateTime(p['prescription_date'] ?? p['created_at'])),
              const Divider(),
              const Text('Médicaments :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...meds.map((m) {
                final route = m['route_of_administration'] ?? '';
                final instructions = m['special_instructions'] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ${m['medication_name'] ?? 'Médicament'} - ${m['dosage'] ?? ''} ${m['dosage_unit'] ?? ''}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 4),
                        child: Text(
                          'Fréquence: ${m['frequency'] ?? 'N/A'} | Durée: ${m['duration'] ?? 'N/A'} j.${route.isNotEmpty ? '\nVoie: $route' : ''}${instructions.isNotEmpty ? '\nInstructions: $instructions' : ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (meds.isEmpty)
                const Text('Aucun médicament listé', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              const Divider(),
              _buildDetailItem('Instructions', p['notes'] ?? p['observations'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  void _showExamDetails(Map<String, dynamic> e) {
    final details = e['exams'] as List? ?? [];
    final docName = 'Dr. ${e['doctor_first_name'] ?? ''} ${e['doctor_last_name'] ?? ''}'.trim();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails Examen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Type', e['exam_type'] ?? 'Examen'),
              _buildDetailItem('Statut', e['exam_status'] ?? e['status'] ?? 'pending'),
              if (docName.trim().isNotEmpty)
                _buildDetailItem('Prescripteur', docName),
              _buildDetailItem('Laboratoire', e['laboratory_name'] ?? 'Non spécifié'),
              _buildDetailItem('Spécialité', e['speciality_name'] ?? e['specialty_name'] ?? 'Non spécifiée'),
              _buildDetailItem('Date', _formatDate(e['exam_date'] ?? e['created_at'])),
              const Divider(),
              const Text('Examens demandés :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              if (details.isNotEmpty)
                ...details.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• ${d['name'] ?? d['exam_type'] ?? 'Examen'}', style: const TextStyle(fontSize: 13)),
                )).toList()
              else
                const Text('Aucun examen détaillé listé', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              const Divider(),
              _buildDetailItem('Observations', e['observations'] ?? 'N/A'),
              if (e['result_notes'] != null && e['result_notes'].toString().isNotEmpty)
                _buildDetailItem('Résultats', e['result_notes']),
              if (e['result_values'] != null && e['result_values'].toString().isNotEmpty)
                _buildDetailItem('Valeurs', e['result_values']),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _InfoRowStatic extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRowStatic({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}