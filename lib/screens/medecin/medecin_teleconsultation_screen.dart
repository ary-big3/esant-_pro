import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class MedecinTeleconsultationScreen extends StatefulWidget {
  final String patientNom;
  final String consultationId;

  const MedecinTeleconsultationScreen({
    super.key,
    required this.patientNom,
    required this.consultationId,
  });

  @override
  State<MedecinTeleconsultationScreen> createState() => _MedecinTeleconsultationScreenState();
}

class _MedecinTeleconsultationScreenState extends State<MedecinTeleconsultationScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isScreenSharing = false;
  bool _showChat = false;
  bool _showNotes = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vidéo principale (patient)
          Positioned.fill(
            child: Container(
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    UserAvatar(
                      initiales: widget.patientNom.split(' ').map((e) => e[0]).join(),
                      size: 120,
                      backgroundColor: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.patientNom,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Connecté',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Vidéo du médecin (coin)
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                color: _isVideoOff ? Colors.grey[800] : AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: _isVideoOff
                  ? const Center(
                      child: Icon(Icons.videocam_off, color: Colors.white, size: 32),
                    )
                  : const Center(
                      child: UserAvatar(
                        initiales: 'FD',
                        size: 48,
                        backgroundColor: Colors.white24,
                      ),
                    ),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, duration: 400.ms),
          ),

          // Barre supérieure
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _showEndCallDialog(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  // Durée
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '15:32',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _showNotes = !_showNotes),
                    icon: Icon(
                      Icons.note_alt,
                      color: _showNotes ? AppColors.secondary : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Panneau de notes (si actif)
          if (_showNotes)
            Positioned(
              left: 16,
              top: 100,
              child: Container(
                width: 280,
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.note_alt, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'Notes de consultation',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(() => _showNotes = false),
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Prenez des notes...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2, duration: 300.ms),
            ),

          // Chat (si actif)
          if (_showChat)
            Positioned(
              right: 16,
              bottom: 140,
              child: Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text('Chat', style: Theme.of(context).textTheme.titleSmall),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(() => _showChat = false),
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          _ChatBubble(
                            message: 'Bonjour Docteur',
                            isMe: false,
                            time: '15:20',
                          ),
                          _ChatBubble(
                            message: 'Bonjour, comment vous sentez-vous aujourd\'hui ?',
                            isMe: true,
                            time: '15:21',
                          ),
                          _ChatBubble(
                            message: 'Un peu mieux, mais j\'ai toujours des douleurs',
                            isMe: false,
                            time: '15:22',
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Message...',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.send, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, duration: 300.ms),
            ),

          // Barre d'outils inférieure
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: 'Micro',
                    isActive: !_isMuted,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  _ControlButton(
                    icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    label: 'Vidéo',
                    isActive: !_isVideoOff,
                    onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                  ),
                  _ControlButton(
                    icon: Icons.screen_share,
                    label: 'Partager',
                    isActive: _isScreenSharing,
                    onTap: () => setState(() => _isScreenSharing = !_isScreenSharing),
                  ),
                  _ControlButton(
                    icon: Icons.chat,
                    label: 'Chat',
                    isActive: _showChat,
                    onTap: () => setState(() => _showChat = !_showChat),
                  ),
                  _ControlButton(
                    icon: Icons.folder_open,
                    label: 'Dossier',
                    onTap: () => _showPatientDossier(),
                  ),
                  _EndCallButton(onTap: () => _showEndCallDialog()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPatientDossier() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    UserAvatar(
                      initiales: widget.patientNom.split(' ').map((e) => e[0]).join(),
                      size: 48,
                      backgroundColor: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientNom,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '45 ans • Groupe A+',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SectionHeader(titre: 'Antécédents'),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(label: 'Pathologies', value: 'Hypertension, Diabète type 2'),
                          const SizedBox(height: 8),
                          _InfoRow(label: 'Allergies', value: 'Pénicilline'),
                          const SizedBox(height: 8),
                          _InfoRow(label: 'Chirurgies', value: 'Appendicectomie (2018)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SectionHeader(titre: 'Traitement en cours'),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Column(
                        children: [
                          _MedicationRow(nom: 'Amlodipine', dosage: '5mg', posologie: '1x/jour'),
                          const Divider(),
                          _MedicationRow(nom: 'Metformine', dosage: '500mg', posologie: '2x/jour'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SectionHeader(titre: 'Dernières constantes'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _VitalCard(label: 'Tension', value: '14/9')),
                        const SizedBox(width: 8),
                        Expanded(child: _VitalCard(label: 'Pouls', value: '78 bpm')),
                        const SizedBox(width: 8),
                        Expanded(child: _VitalCard(label: 'Glycémie', value: '1.2 g/L')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer l\'appel'),
        content: const Text(
          'Voulez-vous mettre fin à cette téléconsultation ? Vous pourrez ensuite compléter le compte-rendu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPostConsultationSheet();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _showPostConsultationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Téléconsultation terminée',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Durée: 15 min 32 sec',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compte-rendu rapide',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Résumé de la consultation...',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _ActionTile(
                      icon: Icons.receipt_long,
                      title: 'Créer une ordonnance',
                      subtitle: 'Prescrire des médicaments',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.science,
                      title: 'Demander des examens',
                      subtitle: 'Analyses, imagerie...',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.calendar_today,
                      title: 'Planifier un suivi',
                      subtitle: 'Prochain rendez-vous',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Plus tard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Valider'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.white70,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.call_end, color: Colors.white, size: 28),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? AppColors.secondary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: const BoxConstraints(maxWidth: 220),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _MedicationRow extends StatelessWidget {
  final String nom;
  final String dosage;
  final String posologie;

  const _MedicationRow({
    required this.nom,
    required this.dosage,
    required this.posologie,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.medication, color: AppColors.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '$dosage • $posologie',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
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

class _VitalCard extends StatelessWidget {
  final String label;
  final String value;

  const _VitalCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
        ],
      ),
    );
  }
}
