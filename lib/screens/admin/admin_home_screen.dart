import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentTabIndex = 0;
  final ApiService _apiService = ApiService();

  // Lists from API
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;

  // Stats from API
  int _totalConsultations = 0;
  int _totalPatients = 0;
  int _totalMedecins = 0;
  int _totalNurses = 0;
  bool _isLoadingStats = true;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialiteController = TextEditingController();
  final _parentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  String _selectedGender = 'M';
  String? _selectedBloodGroup;
  String? _selectedParentId;
  List<Map<String, dynamic>> _parentPatients = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadUsers();
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _loadStats() async {
    try {
      final response = await _apiService.get('/admin/statistics');
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _totalPatients = _parseInt(data['total_patients']);
          _totalMedecins = _parseInt(data['total_doctors']);
          _totalNurses = _parseInt(data['total_nurses']);
          _totalConsultations = _parseInt(data['total_consultations']);
          _isLoadingStats = false;
        });
      } else {
        setState(() => _isLoadingStats = false);
      }
    } catch (e) {
      if (kDebugMode) print('Error loading stats: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await _apiService.get('/admin/users', params: {'limit': 50});
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> usersData = response['data'] is List
            ? response['data']
            : (response['data']['items'] ?? []);
        setState(() {
          _users = usersData.cast<Map<String, dynamic>>();
          _isLoadingUsers = false;
        });
      } else {
        setState(() => _isLoadingUsers = false);
      }
    } catch (e) {
      if (kDebugMode) print('Error loading users: $e');
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _createUserViaApi(String role, {bool isChild = false}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final fullName = '${_prenomController.text.trim()} ${_nomController.text.trim()}';
    
    final body = <String, dynamic>{
      'email': _emailController.text.trim(),
      'full_name': fullName.trim(),
      'phone': _phoneController.text.trim().isEmpty ? '0000000000' : _phoneController.text.trim(),
      'role': role,
      if (_passwordController.text.isNotEmpty) 'password': _passwordController.text,
    };

    if (role == 'medecin') {
      body['specialty'] = _specialiteController.text.trim().isEmpty 
          ? 'Généraliste' 
          : _specialiteController.text.trim();
    }

    if (isChild) {
      body['is_child'] = true;
      body['gender'] = _selectedGender;
      if (_selectedBloodGroup != null) {
        body['blood_group'] = _selectedBloodGroup;
      }
      if (_selectedParentId != null && _selectedParentId != '__manual') {
        body['parent_identifier'] = _selectedParentId;
      } else if (_parentIdController.text.trim().isNotEmpty) {
        body['parent_identifier'] = _parentIdController.text.trim();
      }
      if (_dateOfBirthController.text.trim().isNotEmpty) {
        body['date_of_birth'] = _dateOfBirthController.text.trim();
      }
    }

    try {
      final response = await _apiService.post('/admin/users', body: body);
      if (response['success'] == true) {
        _clearForm();
        if (mounted) {
          Navigator.pop(context); // Close dialog
          _loadStats();
          _loadUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Compte créé avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Erreur lors de la création'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nomController.clear();
    _prenomController.clear();
    _emailController.clear();
    _phoneController.clear();
    _specialiteController.clear();
    _parentIdController.clear();
    _passwordController.clear();
    _dateOfBirthController.clear();
    _selectedGender = 'M';
    _selectedBloodGroup = null;
    _selectedParentId = null;
  }

  Future<void> _loadParentPatients([StateSetter? setDialogState]) async {
    try {
      final response = await _apiService.get('/admin/users?limit=100', requireAuth: true);
      if (response['success'] == true && response['data'] is List) {
        _parentPatients = (response['data'] as List)
            .where((u) => u['role'] == 'patient')
            .map((u) => {
              'user_id': u['user_id'],
              'full_name': u['full_name'] ?? '',
              'email': u['email'] ?? '',
            })
            .toList();
        if (setDialogState != null) {
          setDialogState(() {});
        } else {
          setState(() {});
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erreur chargement parents: $e');
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialiteController.dispose();
    _parentIdController.dispose();
    _passwordController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1A2E),
        elevation: 0,
        title: const Text('Administration', style: TextStyle(color: Color(0xFFC9A84C), fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Color(0xFFC9A84C)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _currentTabIndex == 0 ? _buildDashboard() : _buildUserManagement(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        selectedItemColor: const Color(0xFFC9A84C),
        unselectedItemColor: const Color(0xFF64748B),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F1A2E), Color(0xFF1A2744)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9A84C).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Color(0xFFC9A84C), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Administration',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gestion de la plateforme E-Santé',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Stats cards 2x2
          _isLoadingStats
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildGraphStat('Patients', _totalPatients, Icons.people, const Color(0xFFC9A84C), [8, 12, 15, 18, 20, 22, 25]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGraphStat('Consultations', _totalConsultations, Icons.assignment, const Color(0xFF3B82F6), [3, 5, 4, 7, 6, 8, 9]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGraphStat('Médecins', _totalMedecins, Icons.medical_services, const Color(0xFF14B8A6), [2, 3, 4, 4, 5, 5, 6]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGraphStat('Infirmiers', _totalNurses, Icons.health_and_safety, const Color(0xFF10B981), [1, 2, 2, 3, 3, 4, 4]),
                        ),
                      ],
                    ),
                  ],
                ),
          const SizedBox(height: 24),
          // Quick actions
          Text('Actions rapides', style: TextStyle(fontWeight: FontWeight.w700, color: const Color(0xFF0F1A2E), fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildQuickAction('Médecin', Icons.medical_services, const Color(0xFF14B8A6), () => _showCreateDialog('medecin'))),
              const SizedBox(width: 10),
              Expanded(child: _buildQuickAction('Infirmier', Icons.health_and_safety, const Color(0xFF10B981), () => _showCreateDialog('infirmiere'))),
              const SizedBox(width: 10),
              Expanded(child: _buildQuickAction('Enfant', Icons.child_care, const Color(0xFF3B82F6), () => _showCreateDialog('enfant'))),
              const SizedBox(width: 10),
              Expanded(child: _buildQuickAction('Labo', Icons.science, const Color(0xFF8B5CF6), () => _showCreateDialog('laboratoire'))),
            ],
          ),
          const SizedBox(height: 24),
          // Info panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF0F1A2E).withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0F1A2E).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFF0F1A2E).withValues(alpha: 0.6), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'E-Santé - Plateforme Nationale',
                      style: TextStyle(color: Color(0xFF0F1A2E), fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person_add, 'Créez des comptes professionnels via les actions rapides ci-dessus'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.people, 'Consultez la liste des utilisateurs dans l\'onglet Utilisateurs'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.security, 'Mot de passe par défaut : Esante2026!'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.lock_open, 'Les utilisateurs doivent changer leur mot de passe à la première connexion'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC9A84C), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: const Color(0xFF64748B), fontSize: 12.5, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildGraphStat(String title, int value, IconData icon, Color color, List<double> sparkData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F1A2E).withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$value',
            style: const TextStyle(
              color: Color(0xFF0F1A2E),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (sparkData.isNotEmpty)
            SizedBox(
              height: 36,
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

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF0F1A2E), const Color(0xFF0F1A2E).withValues(alpha: 0.85)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gestion des utilisateurs', style: const TextStyle(color: Color(0xFF0F1A2E), fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          // Create buttons
          Row(
            children: [
              Expanded(child: _buildQuickAction('Médecin', Icons.medical_services, const Color(0xFF14B8A6), () => _showCreateDialog('medecin'))),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickAction('Infirmier', Icons.health_and_safety, const Color(0xFF10B981), () => _showCreateDialog('infirmiere'))),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickAction('Enfant', Icons.child_care, const Color(0xFF3B82F6), () => _showCreateDialog('enfant'))),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickAction('Labo', Icons.science, const Color(0xFF8B5CF6), () => _showCreateDialog('laboratoire'))),
            ],
          ),
          const SizedBox(height: 20),
          _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          Icon(Icons.people_outline, size: 48, color: const Color(0xFF64748B)),
                          const SizedBox(height: 12),
                          Text('Aucun utilisateur', style: TextStyle(color: const Color(0xFF64748B))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      itemBuilder: (context, index) => _buildUserTile(_users[index]),
                    ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final role = user['role'] ?? '';
    final fullName = user['full_name'] ?? 'N/A';
    final email = user['email'] ?? '';
    final isActive = user['is_active'] == 1 || user['is_active'] == true;
    
    Color roleColor;
    IconData roleIcon;
    String roleLabel;
    switch (role) {
      case 'medecin':
        roleColor = const Color(0xFF14B8A6);
        roleIcon = Icons.medical_services;
        roleLabel = 'Médecin';
        break;
      case 'infirmiere':
        roleColor = const Color(0xFF10B981);
        roleIcon = Icons.health_and_safety;
        roleLabel = 'Infirmier';
        break;
      case 'admin':
        roleColor = const Color(0xFFC9A84C);
        roleIcon = Icons.admin_panel_settings;
        roleLabel = 'Admin';
        break;
      case 'laboratoire':
        roleColor = const Color(0xFF8B5CF6);
        roleIcon = Icons.science;
        roleLabel = 'Laboratoire';
        break;
      default:
        roleColor = const Color(0xFF3B82F6);
        roleIcon = Icons.person;
        roleLabel = 'Patient';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: const Color(0xFF0F1A2E).withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(roleIcon, color: roleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F1A2E), fontSize: 14)),
                Text(email, style: TextStyle(fontSize: 12, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(roleLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: roleColor)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(String role) {
    final isMedecin = role == 'medecin';
    final isInfirmiere = role == 'infirmiere';
    final isEnfant = role == 'enfant';
    final isLaboratoire = role == 'laboratoire';
    final title = isMedecin
        ? 'Créer un médecin'
        : isInfirmiere
            ? 'Créer un infirmier'
            : isLaboratoire
                ? 'Créer un laboratoire'
                : 'Créer un compte enfant';

    // Reset child-specific state
    _selectedGender = 'M';
    _selectedBloodGroup = null;
    _selectedParentId = null;
    _parentPatients = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Load parents on first build for child accounts
          if (isEnfant && _parentPatients.isEmpty) {
            _loadParentPatients(setDialogState);
          }
          return AlertDialog(
          title: Text(title),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: 'Prénom',
                    controller: _prenomController,
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: 'Nom',
                    controller: _nomController,
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: 'Téléphone',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: 'Mot de passe (défaut: Esante2026!)',
                    controller: _passwordController,
                    obscureText: true,
                  ),
                  if (isMedecin) ...[
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Spécialité',
                      controller: _specialiteController,
                      validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                    ),
                  ],
                  if (isEnfant) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Sexe',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF1F5F9),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Masculin')),
                        DropdownMenuItem(value: 'F', child: Text('Féminin')),
                        DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                      ],
                      onChanged: (v) {
                        _selectedGender = v ?? 'M';
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedBloodGroup,
                      decoration: const InputDecoration(
                        labelText: 'Groupe sanguin (optionnel)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF1F5F9),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'A+', child: Text('A+')),
                        DropdownMenuItem(value: 'A-', child: Text('A-')),
                        DropdownMenuItem(value: 'B+', child: Text('B+')),
                        DropdownMenuItem(value: 'B-', child: Text('B-')),
                        DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                        DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                        DropdownMenuItem(value: 'O+', child: Text('O+')),
                        DropdownMenuItem(value: 'O-', child: Text('O-')),
                      ],
                      onChanged: (v) {
                        _selectedBloodGroup = v;
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Date de naissance (YYYY-MM-DD)',
                      controller: _dateOfBirthController,
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedParentId,
                      decoration: InputDecoration(
                        labelText: 'Parent *',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        errorText: _selectedParentId == null && _parentIdController.text.trim().isEmpty
                            ? 'Requis'
                            : (_selectedParentId == '__manual' && _parentIdController.text.trim().isEmpty ? 'Saisissez l\'ID' : null),
                      ),
                      items: [
                        ..._parentPatients.map((p) => DropdownMenuItem(
                          value: p['user_id']?.toString(),
                          child: Text('${p['full_name']} (${p['email']})', overflow: TextOverflow.ellipsis),
                        )),
                        const DropdownMenuItem(value: '__manual', child: Text('Saisir manuellement...')),
                      ],
                      onChanged: (v) {
                        _selectedParentId = v;
                        if (v != '__manual') {
                          _parentIdController.clear();
                        }
                        setDialogState(() {});
                      },
                    ),
                    if (_selectedParentId == null || _selectedParentId == '__manual') ...[
                      const SizedBox(height: 10),
                      AppTextField(
                        label: 'ID du parent (user_id)',
                        controller: _parentIdController,
                        prefixIcon: Icons.person,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearForm();
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final apiRole = isEnfant ? 'patient' : role;
                _createUserViaApi(apiRole, isChild: isEnfant);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1A2E)),
              child: const Text('Créer', style: TextStyle(color: Color(0xFFC9A84C))),
            ),
          ],
        );
        },
      ),
    );
  }
}
