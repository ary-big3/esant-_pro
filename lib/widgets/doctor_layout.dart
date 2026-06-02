import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hopital/utils/token_helper.dart';
import '../../core/theme/doctor_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../screens/auth/welcome_screen.dart';

/// Layout principal pour l'interface médecin avec sidebar et topbar
class DoctorLayout extends StatefulWidget {
  final int currentIndex;
  final Function(int) onNavigate;
  final List<Widget> pages;
  final String doctorName;
  final String specialty;
  final List<({String label, IconData icon, String route})>? navigationItems;

  const DoctorLayout({
    Key? key,
    required this.currentIndex,
    required this.onNavigate,
    required this.pages,
    required this.doctorName,
    required this.specialty,
    this.navigationItems,
  }) : super(key: key);

  @override
  State<DoctorLayout> createState() => _DoctorLayoutState();
}

class _DoctorLayoutState extends State<DoctorLayout> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  static const List<({String label, IconData icon, String route})> _defaultNavigationItems = [
    (label: 'Tableau de bord', icon: Icons.dashboard_rounded, route: 'dashboard'),
    (label: 'Patients', icon: Icons.people_rounded, route: 'patients'),
    (label: 'Rendez-vous', icon: Icons.calendar_today_rounded, route: 'agenda'),
    (label: 'Notifications', icon: Icons.notifications_rounded, route: 'notifications'),
    (label: 'Profil', icon: Icons.person_rounded, route: 'profile'),
  ];

  List<({String label, IconData icon, String route})> get _navigationItems =>
      widget.navigationItems ?? _defaultNavigationItems;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      // Version mobile avec bottom navigation
      return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: widget.pages[widget.currentIndex],
          ),
          bottomNavigationBar: _buildBottomNavigation(),
        );
    }

    // Version desktop avec sidebar + right panel
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
          children: [
            // Left Sidebar
            _buildSidebar(),
            // Contenu principal
            Expanded(
              child: Column(
                children: [
                  // Topbar
                  _buildTopbar(),
                  // Contenu
                  Expanded(
                    child: widget.pages[widget.currentIndex],
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: DoctorTheme.sidebarWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A2E),
        border: Border(
          right: BorderSide(
            color: const Color(0xFFC9A84C).withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1A2E).withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Branding
          Padding(
            padding: const EdgeInsets.all(DoctorTheme.spacing20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(DoctorTheme.spacing8),
                  decoration: BoxDecoration(
                    borderRadius: DoctorTheme.radiusSmall,
                    boxShadow: DoctorTheme.neonGlow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/icone.ico',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.all(DoctorTheme.spacing12),
                        decoration: BoxDecoration(
                          gradient: DoctorTheme.goldGradient,
                          borderRadius: DoctorTheme.radiusSmall,
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: Color(0xFF0F1A2E),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DoctorTheme.spacing12),
                const Text(
                  'E-Santé',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC9A84C),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView.builder(
              itemCount: _navigationItems.length,
              padding: const EdgeInsets.symmetric(horizontal: DoctorTheme.spacing12),
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isActive = widget.currentIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: DoctorTheme.spacing8),
                  child: _buildNavItem(
                    label: item.label,
                    icon: item.icon,
                    isActive: isActive,
                    onTap: () => widget.onNavigate(index),
                  ),
                );
              },
            ),
          ),

          // Bouton logout
          Padding(
            padding: const EdgeInsets.all(DoctorTheme.spacing20),
            child: GestureDetector(
              onTap: () => _handleLogout(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DoctorTheme.spacing12,
                  vertical: DoctorTheme.spacing12,
                ),
                decoration: BoxDecoration(
                  color: DoctorTheme.dangerRed.withValues(alpha: 0.08),
                  borderRadius: DoctorTheme.radiusSmall,
                  border: Border.all(
                    color: DoctorTheme.dangerRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout_rounded, color: DoctorTheme.dangerRed, size: 18),
                    SizedBox(width: DoctorTheme.spacing8),
                    Text(
                      'Déconnexion',
                      style: TextStyle(
                        color: DoctorTheme.dangerRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DoctorTheme.spacing12,
          vertical: DoctorTheme.spacing12,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFC9A84C).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: DoctorTheme.radiusSmall,
          border: isActive
              ? Border.all(
                  color: const Color(0xFFC9A84C).withValues(alpha: 0.25),
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFC9A84C).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFFC9A84C) : DoctorTheme.textOnDarkSecondary,
            ),
            const SizedBox(width: DoctorTheme.spacing12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? const Color(0xFFC9A84C) : DoctorTheme.textOnDarkSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopbar() {
    return Container(
      height: DoctorTheme.topbarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DoctorTheme.spacing24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: DoctorTheme.spacing24),
            // Right side
            Row(
              children: [
                // Notifications
                GestureDetector(
                  onTap: _showNotifications,
                  child: Container(
                    padding: const EdgeInsets.all(DoctorTheme.spacing8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: Color(0xFF0F1A2E),
                        ),
                        if (_unreadCount > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: DoctorTheme.dangerRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: DoctorTheme.spacing12),
                // User avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: DoctorTheme.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: Color(0xFF0F1A2E),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            _navigationItems.length,
            (index) {
              final item = _navigationItems[index];
              final isActive = widget.currentIndex == index;
              return _buildBottomNavItem(
                icon: item.icon,
                label: item.label,
                isActive: isActive,
                onTap: () => widget.onNavigate(index),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DoctorTheme.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? const Color(0xFFC9A84C) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? const Color(0xFFC9A84C) : const Color(0xFF94A3B8),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNotifications() async {
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.get('/doctor/notifications');
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> notificationsData = response['data'] as List<dynamic>;
        setState(() {
          _notifications = notificationsData.cast<Map<String, dynamic>>();
          _unreadCount = _notifications.where((n) => n['is_read'] == 0 || n['is_read'] == false).length;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement notifications: $e');
    }

    // Afficher le bottom sheet
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildNotificationsSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildNotificationsSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Demandes de rendez-vous',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1A2E),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showNotifications,
                      child: const Icon(Icons.refresh, color: Color(0xFF0F1A2E)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Color(0xFF0F1A2E)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _notifications.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune demande',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final patientName = notification['patient_name'] ?? 'Patient';
                      final appointmentDate = notification['related_appointment_id'];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F1A2E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notification['message'] ?? 'Demande de rendez-vous',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                            ),
                            if (notification['created_at'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  notification['created_at'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _approveAppointment(
                                  notification['related_appointment_id'] as int?,
                                  index,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC9A84C),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Approuver',
                                  style: TextStyle(
                                    color: Color(0xFF0F1A2E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveAppointment(int? appointmentId, int index) async {
    if (appointmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Rendez-vous non trouvé')),
      );
      return;
    }

    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.put(
        '/appointments/$appointmentId/approve',
        body: {},
      );

      if (response['success'] == true) {
        setState(() {
          _notifications.removeAt(index);
          _unreadCount = _notifications.where((n) => n['is_read'] == 0 || n['is_read'] == false).length;
        });

        if (!mounted) return;
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous approuvé ✓'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Erreur lors de l\'approbation');
      }
    } catch (e) {
      debugPrint('Erreur approbation: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Déconnexion', style: TextStyle(color: DoctorTheme.dangerRed)),
          ),
        ],
      ),
    );
  }
}
