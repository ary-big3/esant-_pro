import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class _C {
  static const Color gold        = Color(0xFFC9A84C);
  static const Color goldLight   = Color(0xFF0A1628);
  static const Color goldDeep    = Color(0xFFA8873A);
  static const Color navy        = Color(0xFF0A1628);
  static const Color navyMid     = Color(0xFF142035);
  static const Color charcoal    = Color(0xFF3A3A3A);
  static const Color stone       = Color(0xFF7A7A7A);
  static const Color pearl       = Color(0xFFF2EFE9);
  static const Color white       = Color(0xFFFFFFFF);
  static const Color border      = Color(0xFFE5E2DB);
}

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late ScrollController _scrollController;
  bool _showMobileMenu = false;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() => _scrolled = _scrollController.offset > 50);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _HeroSection(),
                _ServicesSection(),
                _StatsSection(),
                _AboutSection(),
                _DoctorsSection(),
                _HowItWorksSection(),
                _BenefitsSection(),
                _FaqSection(),
                _ContactSection(),
                _CtaFinalSection(),
                _PremiumFooter(),
              ],
            ),
          ),
          _StickyNavbar(
            scrolled: _scrolled,
            onMenuToggle: () => setState(() => _showMobileMenu = !_showMobileMenu),
          ),
          if (_showMobileMenu)
            _MobileMenuOverlay(
              onClose: () => setState(() => _showMobileMenu = false),
            ),
        ],
      ),
    );
  }
}

class _StickyNavbar extends StatelessWidget {
  final bool scrolled;
  final VoidCallback onMenuToggle;

  const _StickyNavbar({required this.scrolled, required this.onMenuToggle});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        boxShadow: scrolled
            ? [BoxShadow(color: _C.navy.withValues(alpha: 0.1), blurRadius: 8)]
            : [],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 12),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/icone.ico',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_C.gold, _C.goldDeep])),
                    child: const Icon(Icons.medical_services, color: _C.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('E-Santé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _C.navy)),
              const Spacer(),
              if (!isMobile)
                Row(
                  children: [
                    FilledButton(onPressed: () => _push(context, const LoginScreen()), style: FilledButton.styleFrom(backgroundColor: _C.gold, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('Connexion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.navy))),
                    const SizedBox(width: 12),
                    OutlinedButton(onPressed: () => _push(context, const RegisterScreen()), style: OutlinedButton.styleFrom(side: const BorderSide(color: _C.gold, width: 1.5), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text("S'inscrire", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.gold))),
                  ],
                )
              else
                IconButton(icon: const Icon(Icons.menu, color: _C.navy, size: 24), onPressed: onMenuToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileMenuOverlay extends StatelessWidget {
  final VoidCallback onClose;
  const _MobileMenuOverlay({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: _C.navy.withValues(alpha: 0.4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 220,
                  color: _C.white,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                    children: [
                      _MobileMenuItem(label: 'Accueil', onTap: onClose),
                      _MobileMenuItem(label: 'Services', onTap: onClose),
                      _MobileMenuItem(label: 'À propos', onTap: onClose),
                      _MobileMenuItem(label: 'Médecins', onTap: onClose),
                      const SizedBox(height: 20),
                      SizedBox(width: double.infinity, child: FilledButton(onPressed: () { onClose(); _push(context, const LoginScreen()); }, style: FilledButton.styleFrom(backgroundColor: _C.gold, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('Connexion', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.navy)))),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () { onClose(); _push(context, const RegisterScreen()); }, style: OutlinedButton.styleFrom(side: const BorderSide(color: _C.gold), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text("S'inscrire", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.gold)))),
                    ],
                  ),
                ),
              ),
              Expanded(child: GestureDetector(onTap: onClose, child: const SizedBox.expand())),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileMenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MobileMenuItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(onTap: onTap, child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _C.navy))),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.80,
      decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/cli.png'), fit: BoxFit.cover), color: _C.navy),
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [_C.navy.withValues(alpha: 0.5), _C.navyMid.withValues(alpha: 0.3)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [_C.gold.withValues(alpha: 0.08), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48, vertical: isMobile ? 20 : 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('La santé digitale réinventée', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 24 : 48, fontWeight: FontWeight.w800, color: _C.white, height: 1.2, shadows: [Shadow(color: _C.navy.withValues(alpha: 0.5), offset: const Offset(0, 2), blurRadius: 8)])).animate().fadeIn(duration: 300.ms).slideY(begin: 0.02, duration: 300.ms),
                  const SizedBox(height: 16),
                  Text('Connectez-vous avec les meilleurs médecins', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 13 : 16, color: _C.white, height: 1.5, shadows: [Shadow(color: _C.navy.withValues(alpha: 0.3), offset: const Offset(0, 1), blurRadius: 4)])).animate().fadeIn(duration: 300.ms, delay: 50.ms),
                  const SizedBox(height: 32),
                  if (isMobile)
                    Column(children: [FilledButton(onPressed: () => _push(context, const RegisterScreen()), style: FilledButton.styleFrom(backgroundColor: _C.gold, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('Commencer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.navy))).animate().fadeIn(duration: 300.ms, delay: 100.ms), const SizedBox(height: 12), OutlinedButton(onPressed: () => _push(context, const LoginScreen()), style: OutlinedButton.styleFrom(side: const BorderSide(color: _C.gold, width: 2), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('Me connecter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.gold))).animate().fadeIn(duration: 300.ms, delay: 150.ms)])
                  else
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [FilledButton(onPressed: () => _push(context, const RegisterScreen()), style: FilledButton.styleFrom(backgroundColor: _C.gold, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('Commencer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.navy))).animate().fadeIn(duration: 300.ms, delay: 100.ms), const SizedBox(width: 20), OutlinedButton(onPressed: () => _push(context, const LoginScreen()), style: OutlinedButton.styleFrom(side: const BorderSide(color: _C.gold, width: 2), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('Me connecter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.gold))).animate().fadeIn(duration: 300.ms, delay: 150.ms)]),
                  const SizedBox(height: 40),
                  if (isMobile)
                    Column(children: [_HeroStat(value: '150K+', label: 'Patients', delay: 200), const SizedBox(height: 12), _HeroStat(value: '500+', label: 'Médecins', delay: 250), const SizedBox(height: 12), _HeroStat(value: '4.9★', label: 'Note', delay: 300)])
                  else
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_HeroStat(value: '150K+', label: 'Patients', delay: 200), _HeroStat(value: '500+', label: 'Médecins', delay: 250), _HeroStat(value: '99.9%', label: 'Disponibilité', delay: 300), _HeroStat(value: '4.9★', label: 'Note', delay: 350)]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final int delay;
  const _HeroStat({required this.value, required this.label, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _C.gold)).animate().scaleXY(begin: 0.8, duration: 400.ms, delay: Duration(milliseconds: delay)), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12, color: _C.white, fontWeight: FontWeight.w500)).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: delay + 50))]);
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _C.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: isMobile ? 50 : 100),
      child: Column(
        children: [
          Text('Nos Services', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 28 : 40, fontWeight: FontWeight.w800, color: _C.navy)).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text('Accédez à tous nos services médicaux en ligne', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 13 : 15, color: _C.stone, fontWeight: FontWeight.w500)).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          ),
          const SizedBox(height: 60),
          GridView.count(crossAxisCount: isMobile ? 2 : 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 24, crossAxisSpacing: 24, childAspectRatio: 1.05, children: [_ServiceCard(icon: Icons.video_call, title: 'Consultations Vidéo', description: 'Parlez avec un médecin', delay: 0), _ServiceCard(icon: Icons.medication_liquid, title: 'Ordonnances', description: 'Recevez vos ordonnances', delay: 50), _ServiceCard(icon: Icons.health_and_safety, title: 'Dossiers Médicaux', description: 'Tous vos documents', delay: 100), _ServiceCard(icon: Icons.favorite, title: 'Suivi Vital', description: 'Suivez votre santé', delay: 150), _ServiceCard(icon: Icons.calendar_today, title: 'Prise de RDV', description: 'Réservez vos consultations', delay: 200), _ServiceCard(icon: Icons.chat, title: 'Support 24/7', description: 'Aide toujours disponible', delay: 250)]),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;

  const _ServiceCard({required this.icon, required this.title, required this.description, required this.delay});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: _C.white,
          border: Border.all(color: _hovered ? _C.gold : _C.border, width: _hovered ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _hovered
              ? [BoxShadow(color: _C.gold.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))]
              : [BoxShadow(color: _C.navy.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.gold.withValues(alpha: 0.15), _C.gold.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: _C.gold, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.navy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                widget.description,
                style: const TextStyle(fontSize: 11, color: _C.stone, height: 1.4),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: widget.delay)).slideY(begin: 0.02, duration: 300.ms);
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _C.navy,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: isMobile ? 50 : 100),
      child: GridView.count(
        crossAxisCount: isMobile ? 2 : 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 30,
        crossAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.3 : 1.0,
        children: [
          _StatCard(value: '150K+', label: 'Patients actifs', delay: 0),
          _StatCard(value: '500+', label: 'Médecins', delay: 50),
          _StatCard(value: '99.9%', label: 'Disponibilité', delay: 100),
          _StatCard(value: '4.9★', label: 'Note moyenne', delay: 150),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final int delay;

  const _StatCard({required this.value, required this.label, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _C.gold)).animate().scaleXY(begin: 0.8, duration: 400.ms, delay: Duration(milliseconds: delay)),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _C.white, fontWeight: FontWeight.w500)).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: delay + 50)),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _C.pearl,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: isMobile ? 50 : 100),
      child: Column(
        children: [
          Text('À Propos d\'E-Santé', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 28 : 40, fontWeight: FontWeight.w800, color: _C.navy)).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04),
          const SizedBox(height: 40),
          if (isMobile)
            Column(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/doc.png', height: 240, fit: BoxFit.cover)).animate().fadeIn(duration: 400.ms, delay: 100.ms), const SizedBox(height: 32), Text('E-Santé révolutionne l\'accès aux soins en connectant les patients avec les meilleurs médecins.', style: const TextStyle(fontSize: 14, color: _C.charcoal, height: 1.8, fontWeight: FontWeight.w500)).animate().fadeIn(duration: 400.ms, delay: 150.ms), const SizedBox(height: 20), Wrap(spacing: 10, runSpacing: 10, children: [_CertBadge(), _CertBadge(), _CertBadge()])])
          else
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(flex: 1, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/doc.png', fit: BoxFit.cover)).animate().fadeIn(duration: 400.ms, delay: 100.ms)), const SizedBox(width: 40), Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('E-Santé révolutionne l\'accès aux soins en connectant les patients avec les meilleurs médecins, simplement et rapidement.', style: const TextStyle(fontSize: 16, color: _C.charcoal, height: 1.8, fontWeight: FontWeight.w500)).animate().fadeIn(duration: 400.ms, delay: 150.ms), const SizedBox(height: 20), Wrap(spacing: 12, runSpacing: 12, children: [_CertBadge(), _CertBadge(), _CertBadge()])]))]),
        ],
      ),
    );
  }
}

class _CertBadge extends StatelessWidget {
  const _CertBadge();

  @override
  Widget build(BuildContext context) {
    return Container(width: 54, height: 54, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_C.gold, _C.goldDeep])), child: const Center(child: Text('✓', style: TextStyle(fontSize: 24, color: _C.white, fontWeight: FontWeight.w800))));
  }
}

class _DoctorsSection extends StatelessWidget {
  const _DoctorsSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _C.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: isMobile ? 50 : 100),
      child: Column(
        children: [
          Text('Nos Médecins Spécialistes', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 28 : 40, fontWeight: FontWeight.w800, color: _C.navy)).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text('Consultez les meilleurs médecins certifiés', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 13 : 15, color: _C.stone, fontWeight: FontWeight.w500)).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          ),
          const SizedBox(height: 60),
          GridView.count(
            crossAxisCount: isMobile ? 1 : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 28,
            crossAxisSpacing: 24,
            childAspectRatio: 1.0,
            children: [
              _DoctorCard(name: 'Dr. Ahmed Médina', specialty: 'Cardiologue', experience: '15 ans', rating: 4.9, delay: 0),
              _DoctorCard(name: 'Dr. Marie Dupont', specialty: 'Dermatologue', experience: '12 ans', rating: 4.8, delay: 100),
              _DoctorCard(name: 'Dr. Jean Claude', specialty: 'Neurologue', experience: '18 ans', rating: 4.9, delay: 200),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatefulWidget {
  final String name;
  final String specialty;
  final String experience;
  final double rating;
  final int delay;

  const _DoctorCard({required this.name, required this.specialty, required this.experience, required this.rating, required this.delay});

  @override
  State<_DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<_DoctorCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _hovered ? _C.gold.withValues(alpha: 0.05) : _C.white,
          border: Border.all(color: _hovered ? _C.gold : _C.border, width: _hovered ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _hovered
              ? [BoxShadow(color: _C.gold.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))]
              : [BoxShadow(color: _C.navy.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_C.gold.withValues(alpha: 0.2), _C.gold.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(Icons.person, color: _C.gold, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              widget.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.navy),
            ),
            const SizedBox(height: 6),
            Text(
              widget.specialty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.gold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: _C.gold, size: 13),
                const SizedBox(width: 4),
                Text('${widget.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.navy)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: _C.border,
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.experience} d\'expérience',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: _C.stone, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: Duration(milliseconds: widget.delay)).slideY(begin: 0.04);
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _C.pearl,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: isMobile ? 50 : 100),
      child: Column(
        children: [
          Text('Comment ça Marche', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 28 : 40, fontWeight: FontWeight.w800, color: _C.navy)).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text('4 étapes simples pour démarrer', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 13 : 15, color: _C.stone, fontWeight: FontWeight.w500)).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          ),
          const SizedBox(height: 60),
          if (isMobile)
            Column(children: [_ProcessStep(number: '1', title: 'Créer un compte', description: 'Inscrivez-vous', delay: 0), const SizedBox(height: 24), _ProcessStep(number: '2', title: 'Trouver un médecin', description: 'Consultez nos spécialistes', delay: 100), const SizedBox(height: 24), _ProcessStep(number: '3', title: 'Prendre RDV', description: 'Réservez', delay: 200), const SizedBox(height: 24), _ProcessStep(number: '4', title: 'Consulter', description: 'Videocall sécurisée', delay: 300)])
          else
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_ProcessStep(number: '1', title: 'Créer un compte', description: 'Inscrivez-vous', delay: 0), Container(width: 2, height: 70, color: _C.gold), _ProcessStep(number: '2', title: 'Trouver un médecin', description: 'Consultez nos spécialistes', delay: 100), Container(width: 2, height: 70, color: _C.gold), _ProcessStep(number: '3', title: 'Prendre RDV', description: 'Réservez', delay: 200), Container(width: 2, height: 70, color: _C.gold), _ProcessStep(number: '4', title: 'Consulter', description: 'Videocall', delay: 300)]),
        ],
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final int delay;

  const _ProcessStep({required this.number, required this.title, required this.description, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_C.gold, _C.goldDeep])), child: Center(child: Text(number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _C.white)))).animate().scaleXY(begin: 0.8, duration: 600.ms, delay: Duration(milliseconds: delay)),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.navy)).animate().fadeIn(duration: 600.ms, delay: Duration(milliseconds: delay + 100)),
        const SizedBox(height: 4),
        Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: _C.stone)).animate().fadeIn(duration: 600.ms, delay: Duration(milliseconds: delay + 200)),
      ],
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _C.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: isMobile ? 50 : 100),
      child: Column(
        children: [
          Text('Pourquoi Nous Choisir', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 28 : 40, fontWeight: FontWeight.w800, color: _C.navy)).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text('Une plateforme fiable et sécurisée pour votre santé', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 13 : 15, color: _C.stone, fontWeight: FontWeight.w500)).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          ),
          const SizedBox(height: 60),
          GridView.count(crossAxisCount: isMobile ? 1 : 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 24, crossAxisSpacing: 24, childAspectRatio: 1.1, children: [_BenefitCard(icon: Icons.lock, title: 'Sécurité Garantie', description: 'Chiffrement 256-bit', delay: 0), _BenefitCard(icon: Icons.support_agent, title: 'Support 24/7', description: 'Toujours à votre écoute', delay: 100), _BenefitCard(icon: Icons.verified_user, title: 'Médecins Certifiés', description: 'Vérifiés et qualifiés', delay: 200)]),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;

  const _BenefitCard({required this.icon, required this.title, required this.description, required this.delay});

  @override
  State<_BenefitCard> createState() => _BenefitCardState();
}

class _BenefitCardState extends State<_BenefitCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _hovered ? _C.gold.withValues(alpha: 0.05) : _C.white,
          border: Border.all(color: _hovered ? _C.gold : _C.border, width: _hovered ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _hovered
              ? [BoxShadow(color: _C.gold.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))]
              : [BoxShadow(color: _C.navy.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_C.gold.withValues(alpha: 0.2), _C.gold.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(widget.icon, color: _C.gold, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.navy),
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _C.stone, height: 1.4),
            )
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: Duration(milliseconds: widget.delay)).slideY(begin: 0.04);
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _C.pearl,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: isMobile ? 50 : 100),
      child: Column(
        children: [
          Text('Questions Fréquentes', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 28 : 40, fontWeight: FontWeight.w800, color: _C.navy)).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text('Trouvez les réponses à vos questions', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 13 : 15, color: _C.stone, fontWeight: FontWeight.w500)).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          ),
          const SizedBox(height: 60),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(children: [_FaqItem(question: 'Comment m\'inscrire ?', answer: 'L\'inscription prend 2 minutes.', delay: 0), _FaqItem(question: 'Les consultations sont-elles sécurisées ?', answer: 'Oui, chiffrées avec le standard 256-bit SSL.', delay: 100), _FaqItem(question: 'Quel est le coût d\'une consultation ?', answer: 'Les tarifs varient selon la spécialité.', delay: 200), _FaqItem(question: 'Puis-je consulter la nuit ?', answer: 'Oui ! La plateforme fonctionne 24h/24, 7j/7.', delay: 300)]),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final int delay;

  const _FaqItem({required this.question, required this.answer, required this.delay});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _expanded ? _C.gold.withValues(alpha: 0.08) : _C.white, border: Border.all(color: _expanded ? _C.gold : _C.border, width: 1.5), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(widget.question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.navy))), Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: _C.gold, size: 20)]), if (_expanded) ...[const SizedBox(height: 10), Text(widget.answer, style: const TextStyle(fontSize: 12, color: _C.stone, height: 1.5))]]),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: Duration(milliseconds: widget.delay));
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _C.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: isMobile ? 50 : 100),
      child: Column(
        children: [
          Text('Nous Contacter', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 28 : 40, fontWeight: FontWeight.w800, color: _C.navy)).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text('Nous sommes à votre disposition pour toute question', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 13 : 15, color: _C.stone, fontWeight: FontWeight.w500)).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          ),
          const SizedBox(height: 60),
          GridView.count(crossAxisCount: isMobile ? 1 : 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 24, crossAxisSpacing: 24, childAspectRatio: isMobile ? 1.1 : 1.0, children: [_ContactCard(icon: Icons.email, title: 'Email', value: 'support@esante.com', delay: 0), _ContactCard(icon: Icons.phone, title: 'Téléphone', value: '+33 1 23 45 67 89', delay: 100), _ContactCard(icon: Icons.location_on, title: 'Adresse', value: 'Paris, France', delay: 200)]),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final int delay;

  const _ContactCard({required this.icon, required this.title, required this.value, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _C.pearl,
        border: Border.all(color: _C.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_C.gold, _C.goldDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: _C.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.navy),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: _C.stone),
          )
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: Duration(milliseconds: delay)).slideY(begin: 0.04);
  }
}

class _CtaFinalSection extends StatelessWidget {
  const _CtaFinalSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: _C.navy,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48, vertical: isMobile ? 60 : 120),
      child: Column(
        children: [
          Text('Rejoignez E-Santé Aujourd\'hui', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 24 : 44, fontWeight: FontWeight.w800, color: _C.white)).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04),
          const SizedBox(height: 16),
          Text('Accédez aux meilleurs médecins, rapidement et simplement', textAlign: TextAlign.center, style: TextStyle(fontSize: isMobile ? 13 : 16, color: _C.white.withValues(alpha: 0.8))).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          const SizedBox(height: 32),
          FilledButton(onPressed: () => _push(context, const RegisterScreen()), style: FilledButton.styleFrom(backgroundColor: _C.gold, padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 48, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('Commencer Maintenant', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.navy))).animate().fadeIn(duration: 400.ms, delay: 100.ms),
        ],
      ),
    );
  }
}

class _PremiumFooter extends StatelessWidget {
  const _PremiumFooter();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: const Color(0xFF0D0D0D),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48, vertical: isMobile ? 32 : 60),
      child: Column(
        children: [
          if (isMobile)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_FooterColumn(title: 'Produit', items: ['Consultations', 'Ordonnances', 'Dossiers']), const SizedBox(height: 24), _FooterColumn(title: 'Entreprise', items: ['À Propos', 'Blog', 'Carrières']), const SizedBox(height: 24), _FooterColumn(title: 'Légal', items: ['Confidentialité', 'Conditions', 'Cookies'])])
          else
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [_FooterColumn(title: 'Produit', items: ['Consultations', 'Ordonnances', 'Dossiers']), _FooterColumn(title: 'Entreprise', items: ['À Propos', 'Blog', 'Carrières']), _FooterColumn(title: 'Légal', items: ['Confidentialité', 'Conditions', 'Cookies']), _FooterColumn(title: 'Support', items: ['Aide', 'Contact', 'FAQ'])]),
          const SizedBox(height: 32),
          Divider(color: const Color(0xFF3A3A3A).withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('© 2026 E-Santé. Tous droits réservés.', style: TextStyle(fontSize: 11, color: const Color(0xFF7A7A7A))),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;

  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.white)), const SizedBox(height: 12), ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(item, style: const TextStyle(fontSize: 11, color: Color(0xFF7A7A7A)))))]);
  }
}
