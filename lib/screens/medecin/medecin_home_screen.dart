import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/doctor_layout.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';
import 'prescribe_exam_screen.dart';
import 'prescribe_ordonnance_screen.dart';
import 'consultation_screen.dart';
import 'doctor_upload_document_screen.dart';
import 'doctor_patient_medical_history_screen.dart';
import '../auth/login_screen.dart';

class MedecinHomeScreen extends StatefulWidget {
  const MedecinHomeScreen({super.key});

  @override
  State<MedecinHomeScreen> createState() => _MedecinHomeScreenState();
}

class _MedecinHomeScreenState extends State<MedecinHomeScreen> {
  int _currentIndex = 0;
  String _doctorName = 'Dr. ?';
  String _specialty = 'Chargement...';

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
  }

  Future<void> _loadDoctorInfo() async {
    try {
      await TokenHelper.ensureTokenReady();
      final response = await ApiService().get('/doctor/profile');
      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _doctorName = response['data']['full_name'] ?? 'Dr. ?';
            _specialty = response['data']['specialty'] ?? 'Généraliste';
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DoctorLayout(
      currentIndex: _currentIndex,
      onNavigate: (index) => setState(() => _currentIndex = index),
      doctorName: _doctorName,
      specialty: _specialty,
      pages: [
        _MedecinDashboard(),
        _MedecinPatientsScreen(),
        _MedecinAgendaScreen(),
        _MedecinProfileScreen(),
        _MedecinSettingsScreen(),
      ],
    );
  }
}

// ========== PREMIUM DASHBOARD ==========
class _MedecinDashboard extends StatefulWidget {
  const _MedecinDashboard();

  @override
  State<_MedecinDashboard> createState() => _MedecinDashboardState();
}

class _MedecinDashboardState extends State<_MedecinDashboard> {
  late AuthService _authService;
  late ApiService _apiService;

  String _doctorName = 'Dr. ?';
  String _specialty = 'Chargement...';
  String _consultationsCount = '0';
  String _patientsCount = '0';
  String _examsCount = '0';
  String _alertsCount = '0';

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _apiService = ApiService();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    try {
      await TokenHelper.ensureTokenReady();

      final profileResponse = await _apiService.get('/doctor/profile');

      if (profileResponse['success'] == true && profileResponse['data'] != null) {
        final doctorData = profileResponse['data'];

        final statsResponse = await _apiService.get('/doctor/statistics');
        Map<String, dynamic> statsData = {};

        if (statsResponse['success'] == true && statsResponse['data'] != null) {
          statsData = statsResponse['data'];
        }

        if (mounted) {
          setState(() {
            _doctorName = doctorData['full_name'] ?? 'Dr. ?';

            String specialty = doctorData['specialty'] ?? 'Généraliste';
            String hospital = doctorData['hospital_name'] ?? 'Hôpital';
            _specialty = '$specialty • $hospital';

            _consultationsCount = (statsData['consultations_today'] ?? '0').toString();
            _patientsCount = (statsData['distinct_patients'] ?? '0').toString();
            _examsCount = (statsData['urgent_exams'] ?? '0').toString();
            _alertsCount = (statsData['active_prescriptions'] ?? '0').toString();
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement données médecin: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _doctorName,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _specialty,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox.shrink(),
              ],
            ).animate().fadeIn(duration: 500.ms).slide(begin: const Offset(-0.1, 0)),
            
            const SizedBox(height: 28),

            // Mini Graph Stats Row
            Row(
              children: [
                Expanded(
                  child: _MiniGraphStat(
                    titre: 'Consultations',
                    valeur: _consultationsCount,
                    icon: Icons.medical_services,
                    color: const Color(0xFFC9A84C),
                    sparkData: [3, 5, 4, 7, 6, 8, 9],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniGraphStat(
                    titre: 'Patients',
                    valeur: _patientsCount,
                    icon: Icons.people,
                    color: const Color(0xFF14B8A6),
                    sparkData: [12, 15, 14, 18, 20, 22, 25],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniGraphStat(
                    titre: 'Examens',
                    valeur: _examsCount,
                    icon: Icons.science,
                    color: const Color(0xFF3B82F6),
                    sparkData: [2, 3, 1, 4, 3, 5, 4],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniGraphStat(
                    titre: 'Ordonnances',
                    valeur: _alertsCount,
                    icon: Icons.description,
                    color: const Color(0xFF10B981),
                    sparkData: [5, 7, 6, 8, 9, 7, 10],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions - horizontal compact buttons
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.science,
                    label: 'Prescrire un Examen',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PrescribeExamScreen(
                            patientId: 'P123',
                            patientNom: 'Sélectionnez un patient',
                            medecinId: _authService.currentUser?.id ?? 'M?',
                            medecinNom: _doctorName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.file_upload_outlined,
                    label: 'Envoyer un Bilan',
                    color: const Color(0xFFC9A84C),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DoctorUploadDocumentScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 28),

            // Section divider
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Agenda',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sélectionnez un patient pour voir les rendez-vous',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ========== MINI GRAPH STAT CARD ==========
class _MiniGraphStat extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icon;
  final Color color;
  final List<double> sparkData;

  const _MiniGraphStat({
    required this.titre,
    required this.valeur,
    required this.icon,
    required this.color,
    this.sparkData = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1A2E).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titre,
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valeur,
            style: const TextStyle(
              color: Color(0xFF0F1A2E),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (sparkData.isNotEmpty)
            SizedBox(
              height: 28,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (sparkData.length - 1).toDouble(),
                  minY: 0,
                  maxY: sparkData.reduce((a, b) => a > b ? a : b) * 1.3,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sparkData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ========== QUICK ACTION BUTTON ==========
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1A2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F1A2E).withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.5), size: 12),
          ],
        ),
      ),
    );
  }
}

// ========== PARAMETRES SCREEN ==========
class _MedecinSettingsScreen extends StatefulWidget {
  const _MedecinSettingsScreen();

  @override
  State<_MedecinSettingsScreen> createState() => _MedecinSettingsScreenState();
}

class _MedecinSettingsScreenState extends State<_MedecinSettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: const TextStyle(
              color: Color(0xFF0F1A2E),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gérez vos préférences',
            style: TextStyle(color: const Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Notifications
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF0F1A2E).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: SwitchListTile(
              title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F1A2E))),
              subtitle: Text('Recevoir les alertes de rendez-vous', style: TextStyle(color: const Color(0xFF64748B), fontSize: 12)),
              value: _notificationsEnabled,
              activeColor: const Color(0xFFC9A84C),
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
          ),
          const SizedBox(height: 12),

          // Dark mode
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF0F1A2E).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: SwitchListTile(
              title: const Text('Mode sombre', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F1A2E))),
              subtitle: Text('Activer le thème sombre', style: TextStyle(color: const Color(0xFF64748B), fontSize: 12)),
              value: _darkModeEnabled,
              activeColor: const Color(0xFFC9A84C),
              onChanged: (val) => setState(() => _darkModeEnabled = val),
            ),
          ),
          const SizedBox(height: 12),

          // Langue
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF0F1A2E).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFC9A84C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.language, color: Color(0xFFC9A84C), size: 20),
              ),
              title: const Text('Langue', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F1A2E))),
              subtitle: Text('Français', style: TextStyle(color: const Color(0xFF64748B), fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 12),

          // Aide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF0F1A2E).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.help_outline, color: Color(0xFF3B82F6), size: 20),
              ),
              title: const Text('Aide & Support', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F1A2E))),
              subtitle: Text('Contacter le support technique', style: TextStyle(color: const Color(0xFF64748B), fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 32),

          // Déconnexion
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              label: const Text('Déconnexion', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== PATIENT CARD (existing - keep premium styling) ==========
class _PatientCard extends StatelessWidget {
  final String nom;
  final String email;
  final String phone;
  final String patientId;

  const _PatientCard({
    required this.nom,
    required this.email,
    required this.phone,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    List<String> nameParts = nom.split(' ');
    String initiales = nameParts.length >= 2
        ? (nameParts[0][0] + nameParts[1][0]).toUpperCase()
        : (nameParts.isNotEmpty ? nameParts[0][0].toUpperCase() : '?');

    return AppCard(
      onTap: () => _showPatientDetails(context),
      child: Row(
        children: [
          UserAvatar(
            initiales: initiales,
            size: 48,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.mail_outline, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ID: $patientId',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
            ],
          ),
        ],
      ),
    );
  }

  void _showPatientDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PatientDetailScreen(nom: nom, patientId: patientId),
      ),
    );
  }
}

// ========== PATIENT DETAILS ==========
class _PatientDetailScreen extends StatefulWidget {
  final String nom;
  final String patientId;

  const _PatientDetailScreen({required this.nom, required this.patientId});

  @override
  State<_PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<_PatientDetailScreen> {
  late ApiService _apiService;
  Map<String, dynamic> _patientData = {};
  bool _isLoading = true;
  int _selectedTab = 0;
  List<Map<String, dynamic>> _consultations = [];
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _prescriptions = [];
  Map<String, dynamic> _medicalHistory = {};

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      await TokenHelper.ensureTokenReady();

      final response = await _apiService.get('/patient/${widget.patientId}/profile');

      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _patientData = response['data'];
            _isLoading = false;
          });
        }
        _loadConsultations();
        _loadPrescriptions();
        _loadExams();
        _loadMedicalHistory();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement patient: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadConsultations() async {
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get('/patient/${widget.patientId}/consultations');
      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _consultations = List<Map<String, dynamic>>.from(
              (response['data'] as List).map((c) => Map<String, dynamic>.from(c as Map))
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement consultations: $e');
    }
  }

  Future<void> _loadPrescriptions() async {
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get('/patient/${widget.patientId}/prescriptions');
      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _prescriptions = List<Map<String, dynamic>>.from(
              (response['data'] as List).map((p) => Map<String, dynamic>.from(p as Map))
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement ordonnances: $e');
    }
  }

  Future<void> _loadExams() async {
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get('/patient/${widget.patientId}/exams');
      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _exams = List<Map<String, dynamic>>.from(
              (response['data'] as List).map((e) => Map<String, dynamic>.from(e as Map))
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement examens: $e');
    }
  }

  Future<void> _loadMedicalHistory() async {
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get('/medical-dossier/${widget.patientId}/summary');
      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _medicalHistory = Map<String, dynamic>.from(response['data'] as Map);
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement antécédents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _patientData['first_name'] ?? '?';
    final lastName = _patientData['last_name'] ?? '?';
    final bloodGroup = _patientData['blood_group'] ?? 'Unknown';
    final gender = _patientData['gender'] ?? '?';
    final dateOfBirth = _patientData['date_of_birth'] ?? 'N/A';
    final email = _patientData['email'] ?? 'N/A';
    final phone = _patientData['phone'] ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Dossier: $firstName $lastName'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(20),
                  child: AppCard(
                    child: Row(
                      children: [
                        UserAvatar(
                          initiales: '$firstName $lastName'
                              .split(' ')
                              .map((e) => e[0])
                              .join()
                              .toUpperCase(),
                          size: 64,
                          backgroundColor: AppColors.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$firstName $lastName',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${widget.patientId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  StatusBadge(text: bloodGroup, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  StatusBadge(text: gender, color: AppColors.info),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildTabButton('Infos', 0),
                      _buildTabButton('Consultations', 1),
                      _buildTabButton('Ordonnances', 2),
                      _buildTabButton('Examens', 3),
                      _buildTabButton('Antécédents', 4),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedTab == 0) ...[
                          _buildInfoCard('Informations Personnelles', [
                            _buildInfoRow('Nom complet', '$firstName $lastName'),
                            _buildInfoRow('Date de naissance', dateOfBirth),
                            _buildInfoRow('Genre', gender),
                            _buildInfoRow('Email', email),
                            _buildInfoRow('Téléphone', phone),
                            _buildInfoRow('Groupe sanguin', bloodGroup),
                          ]),
                          const SizedBox(height: 20),
                          _buildInfoCard('Infos Médicales', [
                            _buildInfoRow('Statut', 'Actif'),
                            _buildInfoRow('Allergies', _patientData['allergies']?.toString() ?? 'Aucune'),
                            _buildInfoRow('Maladies chroniques', _patientData['chronic_diseases']?.toString() ?? 'Aucune'),
                          ]),
                        ] else if (_selectedTab == 1) ...[
                          if (_consultations.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    const Icon(Icons.medical_services_outlined, size: 48, color: AppColors.textSecondary),
                                    const SizedBox(height: 16),
                                    const Text('Aucune consultation'),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _consultations.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final consultation = _consultations[index];
                                return AppCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            consultation['date'] ?? 'Date inconnue',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          StatusBadge(
                                            text: consultation['status'] ?? 'Complétée',
                                            color: AppColors.success,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        consultation['diagnostic'] ?? 'Consultation générale',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        consultation['notes'] ?? 'Pas de notes',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final firstNameStr = _patientData['first_name'] ?? '?';
                                final lastNameStr = _patientData['last_name'] ?? '?';
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ConsultationScreen(
                                      patientNom: '$firstNameStr $lastNameStr',
                                      patientAge: 'N/A',
                                      patientId: widget.patientId,
                                    ),
                                  ),
                                );
                                _loadConsultations();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Nouvelle Consultation'),
                            ),
                          ),
                        ] else if (_selectedTab == 2) ...[
                          if (_prescriptions.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    const Icon(Icons.receipt, size: 48, color: AppColors.textSecondary),
                                    const SizedBox(height: 16),
                                    const Text('Aucune ordonnance'),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _prescriptions.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final prescription = _prescriptions[index];
                                final medications = prescription['medications'] is List
                                    ? (prescription['medications'] as List).map((m) => m is Map ? m['nom'] ?? m.toString() : m.toString()).toList()
                                    : [];
                                return AppCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            prescription['date'] ?? 'Date inconnue',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          StatusBadge(
                                            text: prescription['status'] ?? 'Active',
                                            color: AppColors.success,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ordonnance #${index + 1}',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      ...medications.map((med) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Text('• $med', style: Theme.of(context).textTheme.bodySmall),
                                      )),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final firstNameStr = _patientData['first_name'] ?? '?';
                                final lastNameStr = _patientData['last_name'] ?? '?';
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PrescribeOrdonnanceScreen(
                                      patientNom: lastNameStr,
                                      patientPrenom: firstNameStr,
                                      patientId: widget.patientId,
                                      medecinNom: 'Dr. Médecin',
                                    ),
                                  ),
                                );
                                _loadPrescriptions();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Prescrire une Ordonnance'),
                            ),
                          ),
                        ] else if (_selectedTab == 3) ...[
                          if (_exams.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    const Icon(Icons.science, size: 48, color: AppColors.textSecondary),
                                    const SizedBox(height: 16),
                                    const Text('Aucun examen'),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _exams.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final exam = _exams[index];
                                final exams = exam['exams'] is List ? (exam['exams'] as List).map((e) => e.toString()).toList() : [];
                                return AppCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            exam['date'] ?? 'Date inconnue',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          StatusBadge(
                                            text: exam['status'] ?? 'Pending',
                                            color: AppColors.info,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Demande d\'examen #${index + 1}',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Spécialité: ${exam['specialite'] ?? 'N/A'}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Urgence: ${exam['urgence'] ?? 'normal'}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      if (exams.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ...exams.map((e) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Text('• $e', style: Theme.of(context).textTheme.bodySmall),
                                        )),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final firstNameStr = _patientData['first_name'] ?? '?';
                                final lastNameStr = _patientData['last_name'] ?? '?';
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PrescribeExamScreen(
                                      patientId: widget.patientId,
                                      patientNom: '$firstNameStr $lastNameStr',
                                      medecinId: 'M001',
                                      medecinNom: 'Dr. Médecin',
                                    ),
                                  ),
                                );
                                _loadExams();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Prescrire un Examen'),
                            ),
                          ),
                        ] else if (_selectedTab == 4) ...[
                          _buildAntecedentsTab(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabButton(String label, int tabIndex) {
    final isActive = _selectedTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAntecedentsTab() {
    final conditions = _medicalHistory['medical_conditions'] is List
        ? (_medicalHistory['medical_conditions'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final chronicDiseases = _medicalHistory['chronic_diseases'] is List
        ? (_medicalHistory['chronic_diseases'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final allergies = _medicalHistory['known_allergies'] is List
        ? (_medicalHistory['known_allergies'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final familyHistory = _medicalHistory['family_history']?.toString() ?? '';
    final bloodGroup = _medicalHistory['blood_group']?.toString() ?? _patientData['blood_group']?.toString() ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Antécédents Médicaux',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final firstNameStr = _patientData['first_name'] ?? '?';
                final lastNameStr = _patientData['last_name'] ?? '?';
                await Navigator.of(context).push<Map<String, dynamic>>(
                  MaterialPageRoute(
                    builder: (context) => DoctorPatientMedicalHistoryScreen(
                      patientId: widget.patientId,
                      patientName: '$firstNameStr $lastNameStr',
                      initialData: _medicalHistory,
                    ),
                  ),
                );
                _loadMedicalHistory();
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

        // Groupe sanguin
        _buildInfoCard('Groupe Sanguin', [
          _buildInfoRow('Groupe', bloodGroup),
        ]),
        const SizedBox(height: 16),

        // Conditions médicales
        _buildInfoCard('Conditions Médicales', conditions.isEmpty
            ? [_buildInfoRow('Aucune condition', '')]
            : conditions.map((c) => _buildInfoRow('•', c)).toList()),
        const SizedBox(height: 16),

        // Maladies chroniques
        _buildInfoCard('Maladies Chroniques', chronicDiseases.isEmpty
            ? [_buildInfoRow('Aucune', '')]
            : chronicDiseases.map((d) => _buildInfoRow('•', d)).toList()),
        const SizedBox(height: 16),

        // Allergies
        _buildInfoCard('Allergies Connues', allergies.isEmpty
            ? [_buildInfoRow('Aucune', '')]
            : allergies.map((a) => _buildInfoRow('•', a)).toList()),
        const SizedBox(height: 16),

        // Antécédents familiaux
        _buildInfoCard('Antécédents Familiaux', [
          _buildInfoRow('Historique', familyHistory.isNotEmpty ? familyHistory : 'Aucun'),
        ]),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== REMAINING SCREENS (Keep original with light premium touches) ==========
class _MedecinPatientsScreen extends StatefulWidget {
  const _MedecinPatientsScreen();

  @override
  State<_MedecinPatientsScreen> createState() => _MedecinPatientsScreenState();
}

class _MedecinPatientsScreenState extends State<_MedecinPatientsScreen> {
  late ApiService _apiService;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _filteredPatients = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() => _filteredPatients = []);
      return;
    }

    _searchAnyPatient(query);
  }

  Future<void> _searchAnyPatient(String query) async {
    try {
      await TokenHelper.ensureTokenReady();

      final response = await _apiService.post(
        '/doctor/search-any-patient',
        body: {'search_query': query},
      ).timeout(const Duration(seconds: 3));

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List;
        
        if (data.isEmpty) {
          if (mounted) {
            setState(() {
              _filteredPatients = [];
              _errorMessage = 'Aucun patient trouvé pour: "$query"';
            });
          }
          return;
        }
        
        final patients = List<Map<String, dynamic>>.from(
          data.map((p) => Map<String, dynamic>.from(p as Map))
        );

        if (mounted) {
          setState(() {
            _filteredPatients = patients;
            _errorMessage = '';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _filteredPatients = [];
            _errorMessage = response['message'] ?? 'Aucun patient trouvé';
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _filteredPatients = [];
          _errorMessage = 'Timeout - serveur trop lent (3s)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _filteredPatients = [];
          _errorMessage = 'Erreur: $e';
        });
      }
    }
  }

@override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mes Patients',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par ID ou nom...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textLight, size: 24),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(_errorMessage, textAlign: TextAlign.center),
                      ],
                    ),
                  )
                : _filteredPatients.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchController.text.isEmpty
                                      ? Icons.people_outline
                                      : Icons.search_off,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Aucun patient affiché'
                                      : 'Aucun résultat pour "${_searchController.text}"',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                if (_searchController.text.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Pour trouver un patient, recherchez par :',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.info.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.badge, color: AppColors.info, size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Son ID (ex: PAT-0001)',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.person, color: AppColors.info, size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Son nom ou prénom',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _filteredPatients.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final patient = _filteredPatients[index];
                              return _PatientCard(
                                nom: patient['full_name'] ?? 'Anonyme',
                                email: patient['email'] ?? '',
                                phone: patient['phone'] ?? '',
                                patientId: patient['patient_id']?.toString() ?? '?',
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ========== AGENDA & PROFILE (Keep existing with minor premium tweaks) ==========
class _MedecinAgendaScreen extends StatefulWidget {
  const _MedecinAgendaScreen();

  @override
  State<_MedecinAgendaScreen> createState() => _MedecinAgendaScreenState();
}

class _MedecinAgendaScreenState extends State<_MedecinAgendaScreen> {
  late ApiService _apiService;
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _allAppointments = [];
  List<Map<String, dynamic>> _selectedDateAppointments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _selectedDate = DateTime.now();
    _loadAllAppointments();
  }

  Future<void> _loadAllAppointments() async {
    try {
      setState(() => _isLoading = true);
      await TokenHelper.ensureTokenReady();

      final response = await _apiService.get('/doctor/agenda?page=1&limit=100');

      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _allAppointments = List<Map<String, dynamic>>.from(
              (response['data'] as List).map((a) => Map<String, dynamic>.from(a as Map))
            );
            _filterAppointmentsByDate();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur chargement agenda: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAppointmentsByDate() {
    if (_selectedDate == null) {
      _selectedDateAppointments = [];
      return;
    }

    final selectedDateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    
    _selectedDateAppointments = _allAppointments.where((appt) {
      final apptDate = appt['appointment_date']?.toString() ?? '';
      return apptDate.startsWith(selectedDateStr);
    }).toList();

    _selectedDateAppointments.sort((a, b) {
      final timeA = a['appointment_date']?.toString() ?? '00:00';
      final timeB = b['appointment_date']?.toString() ?? '00:00';
      return timeA.compareTo(timeB);
    });
  }

  List<Map<String, dynamic>> _getAppointmentsForDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _allAppointments.where((appt) {
      final apptDate = appt['appointment_date']?.toString() ?? '';
      return apptDate.startsWith(dateStr);
    }).toList();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _showCreateAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateAppointmentDialog(
        onSubmit: (patientId, appointmentDate, reason) async {
          try {
            await TokenHelper.ensureTokenReady();
            final response = await _apiService.post(
              '/appointments',
              body: {
                'patient_id': int.parse(patientId),
                'appointment_date': appointmentDate,
                'reason_for_appointment': reason,
              },
            );

            if (response['success'] == true && mounted) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Rendez-vous créé avec succès'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
              _loadAllAppointments();
              if (mounted) {
                Navigator.pop(context);
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ ${response['message'] ?? "Erreur lors de la création"}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Erreur: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _filterAppointmentsByDate();
    });
  }

  Future<void> _approveAppointment(int appointmentId) async {
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.put(
        '/appointments/$appointmentId/approve',
        body: {},
        requireAuth: true,
      );

      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rendez-vous confirmé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadAllAppointments();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${response['message'] ?? "Erreur lors de la confirmation"}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mon Agenda',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gérez vos rendez-vous',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _loadAllAppointments,
                          icon: const Icon(Icons.refresh, color: AppColors.primary),
                          tooltip: 'Rafraîchir',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: _buildCalendarWidget(context),
                  ),
                ),
                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rendez-vous du jour',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}'
                                : '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selectedDateAppointments.length}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _isLoading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(strokeWidth: 3),
                              const SizedBox(height: 16),
                              Text(
                                'Chargement des rendez-vous...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _selectedDateAppointments.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.event_available,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun rendez-vous',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Créez une nouveau rendez-vous en cliquant sur le bouton ci-dessous',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedDateAppointments.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final appt = _selectedDateAppointments[index];
                              return _AppointmentCard(
                                appointmentId: appt['appointment_id'],
                                patientName: appt['patient_name'] ?? 'Anonyme',
                                time: appt['appointment_date']?.toString().split(' ')[1].substring(0, 5) ?? '??:??',
                                status: appt['status'] ?? 'pending',
                                duration: appt['appointment_duration_minutes'] ?? 30,
                                notes: appt['reason_for_appointment'] ?? '',
                                appointmentRequestId: appt['appointment_request_id'],
                                onApprove: appt['status'] == 'pending' && appt['appointment_request_id'] != null
                                    ? () => _approveAppointment(appt['appointment_id'])
                                    : null,
                              );
                            },
                          ),
              ],
            ),
          ),

          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: _showCreateAppointmentDialog,
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 8,
              icon: const Icon(Icons.add_rounded, size: 28),
              label: const Text(
                'Créer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarWidget(BuildContext context) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstDayWeekday = firstDay.weekday % 7;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F1A2E).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  color: const Color(0xFF0F1A2E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Text(
                  '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1A2E),
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  color: const Color(0xFF0F1A2E),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Day headers
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              childAspectRatio: 1.6,
              children: List.generate(7, (index) {
                final days = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];
                return Center(
                  child: Text(
                    days[index],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),

            // Date grid
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.1,
              children: [
                ...List.generate(firstDayWeekday, (_) => const SizedBox()),

                ...List.generate(daysInMonth, (index) {
                  final date = DateTime(_currentMonth.year, _currentMonth.month, index + 1);
                  final isSelected = _selectedDate != null &&
                    _selectedDate!.year == date.year &&
                    _selectedDate!.month == date.month &&
                    _selectedDate!.day == date.day;
                  final isToday = DateTime.now().year == date.year &&
                    DateTime.now().month == date.month &&
                    DateTime.now().day == date.day;
                  final hasAppointments = _getAppointmentsForDate(date).isNotEmpty;

                  return GestureDetector(
                    onTap: () => _selectDate(date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFC9A84C)
                            : isToday
                                ? const Color(0xFF0F1A2E)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isSelected || isToday
                                  ? Colors.white
                                  : const Color(0xFF0F1A2E),
                              fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          if (hasAppointments && !isSelected)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFC9A84C),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return months[month - 1];
  }
}

class _AppointmentCard extends StatelessWidget {
  final int? appointmentId;
  final String patientName;
  final String time;
  final String status;
  final int duration;
  final String notes;
  final int? appointmentRequestId;
  final VoidCallback? onApprove;

  const _AppointmentCard({
    this.appointmentId,
    required this.patientName,
    required this.time,
    required this.status,
    required this.duration,
    required this.notes,
    this.appointmentRequestId,
    this.onApprove,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmé';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.schedule, color: AppColors.primary, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$duration min',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (notes.isNotEmpty)
                        Expanded(
                          child: Text(
                            notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Text(
                _getStatusLabel(status),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAppointmentDialog extends StatefulWidget {
  final Function(String, String, String) onSubmit;

  const _CreateAppointmentDialog({required this.onSubmit});

  @override
  State<_CreateAppointmentDialog> createState() => _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState extends State<_CreateAppointmentDialog> {
  late ApiService _apiService;
  String? _selectedPatientId;
  String? _selectedPatientName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _reasonController = TextEditingController();
  final _patientIdController = TextEditingController();
  bool _isSearchingPatient = false;
  String? _patientSearchError;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

  Future<void> _searchPatient(String patientInput) async {
    if (patientInput.isEmpty) {
      setState(() {
        _selectedPatientId = null;
        _selectedPatientName = null;
        _patientSearchError = null;
      });
      return;
    }

    try {
      setState(() {
        _isSearchingPatient = true;
        _patientSearchError = null;
      });

      await TokenHelper.ensureTokenReady();

      final response = await _apiService.post(
        '/doctor/search-any-patient',
        body: {'search_query': patientInput},
      );

      if (response['success'] == true && response['data'] != null) {
        final patients = List<Map<String, dynamic>>.from(
          (response['data'] as List).map((p) => Map<String, dynamic>.from(p as Map))
        );

        if (patients.isNotEmpty) {
          final patient = patients[0];
          setState(() {
            _selectedPatientId = patient['patient_id']?.toString();
            _selectedPatientName = '${patient['first_name']} ${patient['last_name']}';
            _isSearchingPatient = false;
            _patientSearchError = null;
          });
        } else {
          setState(() {
            _selectedPatientId = null;
            _selectedPatientName = null;
            _isSearchingPatient = false;
            _patientSearchError = 'Patient non trouvé';
          });
        }
      } else {
        setState(() {
          _selectedPatientId = null;
          _selectedPatientName = null;
          _isSearchingPatient = false;
          _patientSearchError = response['message'] ?? 'Erreur lors de la recherche';
        });
      }
    } catch (e) {
      setState(() {
        _selectedPatientId = null;
        _selectedPatientName = null;
        _isSearchingPatient = false;
        _patientSearchError = 'Erreur: $e';
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _patientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un Rendez-vous'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _patientIdController,
              onChanged: _searchPatient,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelText: 'ID Patient',
                hintText: 'Ex: PAT-0006 ou 6',
                prefixIcon: const Icon(Icons.person_search),
                suffixIcon: _isSearchingPatient
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedPatientName != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Patient trouvé',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedPatientName!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (_patientSearchError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _patientSearchError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelText: 'Date du rendez-vous',
                ),
                child: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Sélectionner une date',
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelText: 'Heure du rendez-vous',
                ),
                child: Text(
                  _selectedTime != null
                      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                      : 'Sélectionner une heure',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelText: 'Raison du rendez-vous',
                hintText: 'Ex: Consultation générale',
              ),
              maxLines: 3,
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
          onPressed: _selectedPatientId != null && _selectedDate != null && _selectedTime != null
              ? () {
                  final dateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _selectedTime!.hour,
                    _selectedTime!.minute,
                    0,
                  );
                  final formattedDate = 
                    '${dateTime.year.toString().padLeft(4, '0')}-'
                    '${dateTime.month.toString().padLeft(2, '0')}-'
                    '${dateTime.day.toString().padLeft(2, '0')} '
                    '${dateTime.hour.toString().padLeft(2, '0')}:'
                    '${dateTime.minute.toString().padLeft(2, '0')}:'
                    '${dateTime.second.toString().padLeft(2, '0')}';
                  
                  widget.onSubmit(
                    _selectedPatientId!,
                    formattedDate,
                    _reasonController.text,
                  );
                }
              : null,
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

class _MedecinProfileScreen extends StatefulWidget {
  const _MedecinProfileScreen();

  @override
  State<_MedecinProfileScreen> createState() => _MedecinProfileScreenState();
}

class _MedecinProfileScreenState extends State<_MedecinProfileScreen> {
  late ApiService _apiService;
  bool _isLoading = true;
  Map<String, dynamic> _doctorData = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    try {
      await TokenHelper.ensureTokenReady();
      
      final response = await _apiService.get('/doctor/profile');

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _doctorData = Map<String, dynamic>.from(response['data'] as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Erreur de chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement profil médecin: $e');
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Chargement du profil...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Erreur: $_error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadDoctorProfile();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final fullName = _doctorData['full_name'] ?? 'Médecin';
    final email = _doctorData['email'] ?? 'N/A';
    final phone = _doctorData['phone'] ?? 'N/A';
    final hospitalName = _doctorData['hospital_name'] ?? 'Non spécifié';
    final licenseNumber = _doctorData['license_number'] ?? 'N/A';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.secondary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${fullName.split(' ').isNotEmpty ? fullName.split(' ')[0][0].toUpperCase() : 'D'}${fullName.split(' ').length > 1 ? fullName.split(' ')[1][0].toUpperCase() : 'R'}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Médecin',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 36),

            const SectionHeader(titre: 'Informations personnelles'),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  _ProfileInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: email,
                  ),
                  const Divider(height: 20),
                  _ProfileInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Téléphone',
                    value: phone,
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 28),

            const SectionHeader(titre: 'Informations professionnelles'),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  _ProfileInfoRow(
                    icon: Icons.local_hospital_outlined,
                    label: 'Hôpital/Établissement',
                    value: hospitalName,
                  ),
                  const Divider(height: 20),
                  _ProfileInfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Numéro de licence',
                    value: licenseNumber,
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                ),
                onPressed: () async {
                  final authService = AuthService();
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Déconnexion',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 300.ms).fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}