import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/auth_service.dart';
import '../patient/patient_home_screen.dart';
import '../medecin/medecin_home_screen.dart';
import '../admin/admin_home_screen.dart';
import '../nurse/nurse_home_screen.dart';
import '../laboratory/laboratory_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Patient login
  final _patientFormKey = GlobalKey<FormState>();
  final _patientEmailController = TextEditingController();
  final _patientPasswordController = TextEditingController();
  
  // Professionnel login
  final _proFormKey = GlobalKey<FormState>();
  final _proEmailController = TextEditingController();
  final _proCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _rememberMe = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _patientEmailController.dispose();
    _patientPasswordController.dispose();
    _proEmailController.dispose();
    _proCodeController.dispose();
    super.dispose();
  }

  // ============================================
  // IDENTIFIANTS DE TEST - DÉMONSTRATION
  // ============================================
  // PATIENT:
  //   Email: patient@test.com
  //   Mot de passe: patient123
  //
  // MÉDECIN:
  //   Email: medecin@hopital.sn
  //   Code: 123456
  //
  // INFIRMIÈRE/INFIRMIER:
  //   Email: infirmiere@hopital.sn
  //   Code: 111222
  //
  // ADMIN HOSPITALIER:
  //   Email: admin@hopital.sn
  //   Code: 654321
  //
  // LABORATOIRE:
  //   Email: laboratoire@hopital.sn
  //   Code: 789456
  //
  //
  // ============================================

  Future<void> _handlePatientLogin() async {
    if (_patientFormKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final authService = AuthService();
        await authService.login(
          email: _patientEmailController.text.trim(),
          password: _patientPasswordController.text,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de connexion: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleProLogin() async {
    if (_proFormKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final authService = AuthService();
        await authService.login(
          email: _proEmailController.text.trim(),
          password: _proCodeController.text, // Utiliser le code comme mot de passe
        );

        if (mounted) {
          setState(() => _isLoading = false);
          
          // Déterminer l'écran d'accueil basé sur le rôle
          final userRole = authService.currentUser?.role.toString().split('.').last ?? 'user';
          
          Widget homeScreen;
          if (userRole == 'admin') {
            homeScreen = const AdminHomeScreen();
          } else if (userRole == 'nurse') {
            homeScreen = const NurseHomeScreen();
          } else if (userRole == 'laboratory') {
            homeScreen = const LaboratoryHomeScreen();
          } else {
            homeScreen = const MedecinHomeScreen();
          }
          
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => homeScreen),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de connexion: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final formWidth = screenWidth > 500 ? 420.0 : screenWidth - 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1A2E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formWidth),
              child: Column(
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC9A84C), Color(0xFFE2D08E)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC9A84C).withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      size: 36,
                      color: Color(0xFF0F1A2E),
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(duration: 300.ms),
                  const SizedBox(height: 20),
                  Text(
                    'E-Santé PRO',
                    style: const TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    'Plateforme Nationale de Santé',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 28),

                  // Card blanche
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tabs
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: const Color(0xFF0F1A2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: Colors.white,
                              unselectedLabelColor: const Color(0xFF64748B),
                              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              dividerColor: Colors.transparent,
                              padding: const EdgeInsets.all(3),
                              tabs: const [
                                Tab(
                                  height: 36,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person, size: 15),
                                      SizedBox(width: 6),
                                      Text('Patient'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  height: 36,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.medical_services, size: 15),
                                      SizedBox(width: 6),
                                      Text('Professionnel'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Form content
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.48,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildPatientTab(),
                              _buildProTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 300.ms).fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 20),
                  // Security footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.3), size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'Conforme RGPD • Chiffrement bout-en-bout',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _patientFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Adresse email',
            hint: 'exemple@email.com',
            controller: _patientEmailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!value.contains('@')) {
                return 'Email invalide';
              }
              return null;
            },
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Mot de passe',
            hint: '••••••••',
            controller: _patientPasswordController,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre mot de passe';
              }
              if (value.length < 6) {
                return 'Minimum 6 caractères';
              }
              return null;
            },
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) => setState(() => _rememberMe = value ?? false),
                      activeColor: const Color(0xFF0F1A2E),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('Se souvenir', style: TextStyle(fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text('Mot de passe oublié ?', style: TextStyle(fontSize: 12, color: const Color(0xFFC9A84C), fontWeight: FontWeight.w500)),
              ),
            ],
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Se connecter',
            isLoading: _isLoading,
            onPressed: _handlePatientLogin,
            icon: Icons.login,
          ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Pas de compte ? ', style: TextStyle(fontSize: 12, color: const Color(0xFF64748B))),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text('S\'inscrire', style: TextStyle(fontSize: 12, color: const Color(0xFFC9A84C), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
        ],
        ),
      ),
    );
  }

  Widget _buildProTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _proFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Email professionnel',
              hint: 'prenom.nom@hopital.sn',
              controller: _proEmailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email requis';
                }
                if (!value.contains('@')) {
                  return 'Email invalide';
                }
                return null;
              },
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Mot de passe / Code d\'accès',
              hint: 'Entrez votre mot de passe',
              controller: _proCodeController,
              keyboardType: TextInputType.visiblePassword,
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Mot de passe requis';
                }
                if (value.length < 6) {
                  return 'Minimum 6 caractères';
                }
                return null;
              },
            ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Accéder à mon espace',
              isLoading: _isLoading,
              onPressed: _handleProLogin,
              icon: Icons.login,
            ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Accès réservé au personnel de santé. Utilisez vos identifiants fournis par votre établissement.',
                      style: TextStyle(fontSize: 11, color: const Color(0xFF64748B), height: 1.4),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 900.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
