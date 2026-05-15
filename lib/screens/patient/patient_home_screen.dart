import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_background.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/nfc_card_widget.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/vitals_service.dart';
import '../../models/vitals_model.dart';
import '../../utils/token_helper.dart';
import 'patient_dossier_screen.dart';
import 'patient_rdv_screen.dart';
import 'patient_ordonnances_screen.dart';
import 'patient_profile_screen.dart';
import 'notifications_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final String? childId;
  final String? childName;
  final String? childAge;

  const PatientHomeScreen({
    super.key,
    this.childId,
    this.childName,
    this.childAge,
  });

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _buildScreens();
  }

  void _buildScreens() {
    _screens = [
      _PatientDashboard(
        childId: widget.childId,
        childName: widget.childName,
        childAge: widget.childAge,
        isChildAccount: widget.childId != null,
      ),
      PatientDossierScreen(
        childId: widget.childId,
        childName: widget.childName,
      ),
      PatientRdvScreen(
        childId: widget.childId,
        childName: widget.childName,
      ),
      PatientOrdonnancesScreen(
        childId: widget.childId,
        childName: widget.childName,
      ),
      PatientProfileScreen(
        childId: widget.childId,
        childName: widget.childName,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Accueil',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder,
                  label: 'Dossier',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label: 'RDV',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Ordo.',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textLight,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textLight,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientDashboard extends StatefulWidget {
  final String? childId;
  final String? childName;
  final String? childAge;
  final bool isChildAccount;

  const _PatientDashboard({
    this.childId,
    this.childName,
    this.childAge,
    this.isChildAccount = false,
  });

  @override
  State<_PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<_PatientDashboard> {
  String _displayName = 'Patient';
  String _initiales = 'P';
  List<dynamic> _appointments = [];
  List<dynamic> _consultations = [];
  String _patientId = 'PAT-0000';
  String _nfcCardId = 'PAT-0000';
  String _bloodType = 'A+';
  bool _isLoadingNfc = true;
  
  // Variables pour la barre de demandes d'accès
  List<dynamic> _pendingRequests = [];
  bool _isLoadingRequests = false;
  
  // Variables pour les vitales
  VitalsModel? _latestVitals;
  bool _isLoadingVitals = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Attendre que le token soit prêt
    await TokenHelper.ensureTokenReady();
    
    // Maintenant charger les données
    _loadUserData();
    _loadAppointmentsAndConsultations();
    _loadNfcData();
    _loadPendingRequests();
    _loadVitals();
  }

  void _loadUserData() {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    if (currentUser != null) {
      setState(() {
        _displayName = '${currentUser.prenom} ${currentUser.nom}';
        _initiales = '${currentUser.prenom.isNotEmpty ? currentUser.prenom[0].toUpperCase() : 'P'}${currentUser.nom.isNotEmpty ? currentUser.nom[0].toUpperCase() : 'P'}';
        if (kDebugMode) {
          print('User loaded: $_displayName');
          print('Initiales: $_initiales');
        }
      });
    }
    
    _loadPatientProfile();
  }

  Future<void> _loadPatientProfile() async {
    try {
      final apiService = ApiService();
      // Charger le profil de l'enfant si childId est fourni
      final profileUrl = widget.childId != null 
          ? '/patient/${widget.childId}/profile' 
          : '/patient/profile';
      final response = await apiService.get(profileUrl, requireAuth: true);
      
      if (response['success'] == true && response['data'] != null) {
        final patientData = response['data'];
        setState(() {
          _patientId = patientData['patient_id']?.toString() ?? 'PAT-0000';
          _bloodType = patientData['blood_group'] ?? 'A+';
          // Mettre à jour le nom si on est sur un compte enfant
          if (widget.isChildAccount) {
            final firstName = patientData['first_name'] ?? '';
            final lastName = patientData['last_name'] ?? '';
            if (firstName.isNotEmpty || lastName.isNotEmpty) {
              _displayName = '$firstName $lastName'.trim();
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors du chargement du profil patient: $e');
    }
  }

  Future<void> _loadNfcData() async {
    try {
      final apiService = ApiService();
      // Charger les données NFC de l'enfant si childId est fourni
      final nfcUrl = widget.childId != null 
          ? '/patient/${widget.childId}/nfc-card' 
          : '/patient/nfc-card';
      final response = await apiService.get(nfcUrl, requireAuth: true);
      
      if (kDebugMode) print('🔍 NFC Response: $response');
      
      if (response['success'] == true && response['data'] != null) {
        final nfcData = response['data'];
        if (kDebugMode) print('📋 NFC Data keys: ${nfcData.keys.toList()}');
        
        setState(() {
          // ✅ CORRECTION: Utiliser 'nfc_card_number' (pas 'nfc_card_id')
          final cardNumber = nfcData['nfc_card_number']?.toString() ?? 
                           nfcData['nfc_card_id']?.toString() ?? 
                           'PAT-0000';
          _nfcCardId = cardNumber;
          
          if (kDebugMode) print('✅ NFC Card Number récupéré: $cardNumber');
          
          // Récupérer le nom du patient
          if (nfcData['full_name'] != null && nfcData['full_name'].toString().isNotEmpty) {
            _displayName = nfcData['full_name'].toString().trim();
            if (kDebugMode) print('✅ Patient Name récupéré: $_displayName');
          }
          
          // Récupérer l'ID patient
          if (nfcData['patient_id'] != null) {
            _patientId = nfcData['patient_id'].toString();
            if (kDebugMode) print('✅ Patient ID récupéré: $_patientId');
          }
          
          // Récupérer le groupe sanguin (optionnel)
          if (nfcData['blood_group'] != null && nfcData['blood_group'].toString().isNotEmpty) {
            _bloodType = nfcData['blood_group'].toString();
            if (kDebugMode) print('✅ Blood Group récupéré: $_bloodType');
          }
          
          _isLoadingNfc = false;
          
          if (kDebugMode) {
            print('🎯 RÉSUMÉ NFC:');
            print('   - Card ID: $_nfcCardId');
            print('   - Patient ID: $_patientId');
            print('   - Nom: $_displayName');
            print('   - Groupe sanguin: $_bloodType');
          }
        });
        
        // Charger les vitales une fois que le patient ID est disponible
        await _loadVitals();
      } else {
        if (kDebugMode) print('⚠️ NFC Response - Success: ${response['success']}, Data: ${response['data']}');
        setState(() => _isLoadingNfc = false);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur lors du chargement des données NFC: $e');
      setState(() => _isLoadingNfc = false);
    }
  }

  Future<void> _loadAppointmentsAndConsultations() async {
    try {
      final apiService = ApiService();

      final appointmentsResponse = await apiService.get('/appointments/patient?limit=10', requireAuth: true);
      if (appointmentsResponse['success'] == true && appointmentsResponse['data'] != null) {
        setState(() {
          _appointments = appointmentsResponse['data'] is List ? appointmentsResponse['data'] : [];
        });
      }

      final consultationsResponse = await apiService.get('/consultations/patient?limit=10', requireAuth: true);
      if (consultationsResponse['success'] == true && consultationsResponse['data'] != null) {
        setState(() {
          _consultations = consultationsResponse['data'] is List ? consultationsResponse['data'] : [];
        });
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> _loadPendingRequests() async {
    try {
      setState(() => _isLoadingRequests = true);
      await TokenHelper.ensureTokenReady();
      
      final apiService = ApiService();
      final response = await apiService.get('/patient/pending-requests', requireAuth: true);

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _pendingRequests = List<dynamic>.from(response['data'] as List);
          _isLoadingRequests = false;
        });
      } else {
        setState(() {
          _pendingRequests = [];
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Erreur lors du chargement des demandes: $e');
      setState(() {
        _pendingRequests = [];
        _isLoadingRequests = false;
      });
    }
  }

  Future<void> _approveRequest(int requestId) async {
    try {
      await TokenHelper.ensureTokenReady();
      final apiService = ApiService();

      final response = await apiService.post(
        '/patient/approve-request/$requestId',
        body: {},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Demande approuvée'),
            backgroundColor:
                response['success'] == true ? Colors.green : Colors.red,
          ),
        );
        if (response['success'] == true) {
          _loadPendingRequests();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    try {
      await TokenHelper.ensureTokenReady();
      final apiService = ApiService();

      final response = await apiService.post(
        '/patient/reject-request/$requestId',
        body: {},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Demande rejetée'),
            backgroundColor:
                response['success'] == true ? Colors.green : Colors.red,
          ),
        );
        if (response['success'] == true) {
          _loadPendingRequests();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Charger les dernières vitales de l'infirmière
  Future<void> _loadVitals() async {
    try {
      setState(() => _isLoadingVitals = true);
      
      if (_patientId.isEmpty || _patientId == 'PAT-0000') {
        if (kDebugMode) print('⚠️ Patient ID not ready yet');
        setState(() => _isLoadingVitals = false);
        return;
      }

      if (kDebugMode) print('📊 Chargement des vitales pour patient: $_patientId');
      
      final vitals = await VitalsService.getLatestVitals(_patientId);
      
      if (mounted) {
        setState(() {
          _latestVitals = vitals;
          _isLoadingVitals = false;
        });
        
        if (kDebugMode) {
          if (vitals != null) {
            print('✅ Vitales chargées: ${vitals.temperature}°C');
          } else {
            print('⚠️ Aucune vitale trouvée');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur lors du chargement des vitales: $e');
      if (mounted) {
        setState(() => _isLoadingVitals = false);
      }
    }
  }

  Widget _buildPendingRequestsSection() {
    if (_isLoadingRequests) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_pendingRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Demandes d\'accès en attente',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ..._pendingRequests.asMap().entries.map((entry) {
          final request = entry.value;
          final requestId = request['request_id'] ?? 0;
          final doctorName = request['full_name'] ?? 'Dr. Inconnu';
          final speciality = request['speciality_name'] ?? 'Médecin';
          final hospital = request['hospital_name'] ?? 'Établissement';
          final reason = request['reason'] ?? '';

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(Icons.health_and_safety, color: AppColors.secondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$speciality • $hospital',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Raison: $reason',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approveRequest(requestId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(
                          'Accepter',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectRequest(requestId),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.error),
                        ),
                        child: Text(
                          'Rejeter',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate(delay: (entry.key * 50).ms).fadeIn(duration: 300.ms);
        }).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Widget pour afficher les dernières vitales enregistrées
  Widget _buildVitalsCard() {
    if (_isLoadingVitals) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  'Chargement des vitales...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_latestVitals == null) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Aucune donnée vitale enregistrée',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final vitals = _latestVitals!;
    final recordDate = DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(vitals.recordedAt);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dernière consultation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recordDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Normal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Grille de vitales (2 colonnes)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _VitalMetricTile(
                label: 'Température',
                value: '${vitals.temperature.toStringAsFixed(1)}',
                unit: '°C',
                icon: Icons.thermostat,
                color: AppColors.error,
              ),
              _VitalMetricTile(
                label: 'Tension',
                value: '${vitals.tensionSystolique}/${vitals.tensionDiastolique}',
                unit: 'mmHg',
                icon: Icons.favorite,
                color: AppColors.error,
              ),
              _VitalMetricTile(
                label: 'Fréq. Cardiaque',
                value: vitals.frequenceCardiaque.toString(),
                unit: 'bpm',
                icon: Icons.favorite_border,
                color: AppColors.secondary,
              ),
              _VitalMetricTile(
                label: 'O₂ Saturation',
                value: '${vitals.saturOxygene.toStringAsFixed(1)}',
                unit: '%',
                icon: Icons.air,
                color: AppColors.info,
              ),
            ],
          ),
          
          // Autres données (poids, taille, notes)
          if (vitals.poids != null || vitals.taille != null || vitals.notes != null) ...[
            const SizedBox(height: 16),
            Divider(color: Color(0xFFE0E0E0)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (vitals.poids != null)
                  Column(
                    children: [
                      Text(
                        '${vitals.poids?.toStringAsFixed(1)} kg',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Poids',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                if (vitals.taille != null)
                  Column(
                    children: [
                      Text(
                        '${vitals.taille?.toStringAsFixed(0)} cm',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Taille',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (vitals.notes != null && vitals.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Notes: ${vitals.notes}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }

  /// Afficher la carte d'un rendez-vous
  Widget _buildAppointmentCard(dynamic appointment) {
    try {
      final date = DateTime.tryParse(appointment['appointment_date'] ?? '')?.toLocal() ?? DateTime.now();
      final dayStr = date.day.toString().padLeft(2, '0');
      final monthStr = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'][date.month - 1];
      final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      
      final doctorName = '${appointment['doctor_first_name'] ?? 'Dr.'}' + 
                        (appointment['doctor_last_name'] != null ? ' ${appointment['doctor_last_name']}' : '');
      final speciality = appointment['speciality_name'] ?? 'Consultation';
      final hospital = appointment['hospital_name'] ?? 'Hôpital';
      final status = appointment['status'] ?? 'Prévu';

      return AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    dayStr,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    monthStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    doctorName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$speciality • $hospital',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      StatusBadge(
                        text: status,
                        color: status.toLowerCase() == 'confirmé' ? AppColors.success : AppColors.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la construction de la carte RDV: $e');
      return const SizedBox.shrink();
    }
  }

  /// Afficher la carte d'une consultation
  Widget _buildConsultationCard(dynamic consultation, int index) {
    try {
      final doctorFirstName = consultation['doctor_first_name'] ?? 'Dr.';
      final doctorLastName = consultation['doctor_last_name'] ?? '';
      final doctorName = '$doctorFirstName ${doctorLastName.isNotEmpty ? doctorLastName : ''}';
      final speciality = consultation['speciality_name'] ?? 'Consultation';
      final date = DateTime.tryParse(consultation['consultation_date'] ?? '');
      final dateStr = date != null ? '${date.day} ${['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'][date.month - 1]} ${date.year}' : 'N/A';
      final diagnostic = consultation['diagnosis'] ?? consultation['reason'] ?? 'Consultation';

      return _ConsultationCard(
        medecinNom: doctorName,
        specialite: speciality,
        date: dateStr,
        diagnostic: diagnostic,
      );
    } catch (e) {
      if (kDebugMode) print('Erreur lors de la construction de la carte consultation: $e');
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                      'Bonjour,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isChildAccount ? widget.childName ?? 'Patient' : _displayName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (widget.isChildAccount)
                      Text(
                        '${widget.childAge}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_outlined, size: 28),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    UserAvatar(initiales: _initiales, size: 48),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // Afficher les demandes d'accès en attente
            _buildPendingRequestsSection(),
            _isLoadingNfc
                ? AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              'Chargement de la carte NFC...',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : NfcCardWidget(
                    patientId: _nfcCardId,
                    patientNom: _displayName,
                    groupeSanguin: _bloodType,
                    isActive: true,
                    onTap: () {},
                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            const SectionHeader(titre: 'Prochain rendez-vous'),
            const SizedBox(height: 12),
            _appointments.isNotEmpty
                ? _buildAppointmentCard(_appointments.first)
                : AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Aucun rendez-vous prévu',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            // ✅ NOUVELLE CARD: Données vitales de l'infirmière
            const SectionHeader(titre: 'Données sanitaires'),
            const SizedBox(height: 12),
            _buildVitalsCard(),
            const SizedBox(height: 24),
            SectionHeader(
              titre: 'Dernières consultations',
              actionText: 'Voir tout',
              onAction: () {},
            ),
            const SizedBox(height: 12),
            _consultations.isEmpty
                ? AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Aucune consultation enregistrée',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      ..._consultations.take(2).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final consultation = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildConsultationCard(consultation, index),
                        ).animate(delay: Duration(milliseconds: 500 + (index * 100))).fadeIn(duration: 400.ms);
                      }).toList(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}



class _ConsultationCard extends StatelessWidget {
  final String medecinNom;
  final String specialite;
  final String date;
  final String diagnostic;

  const _ConsultationCard({
    required this.medecinNom,
    required this.specialite,
    required this.date,
    required this.diagnostic,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const UserAvatar(
            initiales: 'DR',
            size: 48,
            backgroundColor: AppColors.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medecinNom,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  specialite,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  diagnostic,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
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
}

/// Widget pour afficher une métrique vitale en petit format (pour la grille)
class _VitalMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _VitalMetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Row(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
