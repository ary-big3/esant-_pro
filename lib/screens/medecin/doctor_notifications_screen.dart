import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../core/theme/doctor_theme.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';

/// Écran de notifications pour les médecins
/// - Affiche les demandes de rendez-vous en attente
/// - Permet d'approuver ou refuser une demande
/// - Un seul médecin peut approuver (bloque les autres)
class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  State<DoctorNotificationsScreen> createState() =>
      _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> {
  late ApiService _apiService;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _page = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await TokenHelper.ensureTokenReady();

      final response = await _apiService.get(
        '/notifications?page=$_page&limit=$_pageSize',
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'] ?? [];
        
        // Filtrer pour obtenir seulement les notifications de rendez-vous
        final appointmentNotifications = data
            .cast<Map<String, dynamic>>()
            .where((notif) => 
                notif['type'] == 'appointment_reminder' ||
                notif['type'] == 'appointment_request'
            )
            .toList();

        setState(() {
          _notifications = appointmentNotifications;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Erreur lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
      debugPrint('Erreur chargement notifications: $e');
    }
  }

  Future<void> _approveAppointment(
    int appointmentId,
    int notificationIndex,
  ) async {
    try {
      _showLoadingDialog('Approbation en cours...');

      final response = await _apiService.put(
        '/appointments/$appointmentId/approve',
        body: {},
      );

      if (mounted) Navigator.pop(context); // Fermer le dialog de loading

      if (response['success'] == true) {
        // Marquer la notification comme lue et retirer de la liste
        setState(() {
          _notifications.removeAt(notificationIndex);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rendez-vous approuvé avec succès! 🎉'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Recharger les notifications après un court délai
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _loadNotifications();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Erreur lors de l\'approbation'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Erreur approbation: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DoctorTheme.neonViolet,
                  ),
                ),
              ),
              const SizedBox(height: DoctorTheme.spacing16),
              Text(
                message,
                style: const TextStyle(
                  color: DoctorTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DoctorTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: DoctorTheme.spacing24),
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage.isNotEmpty)
            _buildErrorState()
          else if (_notifications.isEmpty)
            _buildEmptyState()
          else
            _buildNotificationsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: DoctorTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DoctorTheme.spacing12,
                vertical: DoctorTheme.spacing8,
              ),
              decoration: BoxDecoration(
                color: DoctorTheme.neonViolet.withOpacity(0.2),
                borderRadius: BorderRadius.circular(DoctorTheme.radiusSmall as double),
              ),
              child: Text(
                _notifications.length.toString(),
                style: const TextStyle(
                  color: DoctorTheme.neonViolet,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DoctorTheme.spacing8),
        Text(
          'Demandes de rendez-vous en attente',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: DoctorTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slide(begin: const Offset(-0.1, 0));
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DoctorTheme.spacing32),
        child: Column(
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  DoctorTheme.neonViolet,
                ),
              ),
            ),
            const SizedBox(height: DoctorTheme.spacing16),
            Text(
              'Chargement des notifications...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DoctorTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(DoctorTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DoctorTheme.radiusSmall as double),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 24),
              const SizedBox(width: DoctorTheme.spacing12),
              Expanded(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.spacing16),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DoctorTheme.spacing32),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: DoctorTheme.neonViolet.withOpacity(0.3),
            ),
            const SizedBox(height: DoctorTheme.spacing16),
            Text(
              'Aucune notification',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DoctorTheme.textPrimary,
              ),
            ),
            const SizedBox(height: DoctorTheme.spacing8),
            Text(
              'Vous êtes à jour avec vos demandes de rendez-vous',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DoctorTheme.textSecondary,
              ),
            ),
            const SizedBox(height: DoctorTheme.spacing24),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DoctorTheme.neonViolet,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: DoctorTheme.spacing12),
      itemBuilder: (context, index) {
        return _buildNotificationCard(
          _notifications[index],
          index,
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slide(
              begin: const Offset(0, 0.1),
            );
      },
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    int index,
  ) {
    final String message = notification['message'] ?? '';
    final String title = notification['title'] ?? '';
    final int appointmentId = notification['appointment_id'] ?? 0;
    final String createdAt = notification['created_at'] ?? '';

    return Container(
      padding: const EdgeInsets.all(DoctorTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DoctorTheme.radiusMedium as double),
        border: Border.all(
          color: DoctorTheme.neonViolet.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et heure
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: DoctorTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DoctorTheme.spacing4),
                    Text(
                      _formatTime(createdAt),
                      style: const TextStyle(
                        color: DoctorTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DoctorTheme.spacing8,
                  vertical: DoctorTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color: DoctorTheme.neonViolet.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Nouveau',
                  style: TextStyle(
                    color: DoctorTheme.neonViolet,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.spacing12),

          // Message
          Container(
            padding: const EdgeInsets.all(DoctorTheme.spacing12),
            decoration: BoxDecoration(
              color: DoctorTheme.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DoctorTheme.neonViolet.withOpacity(0.1),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: DoctorTheme.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: DoctorTheme.spacing16),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveAppointment(appointmentId, index),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approuver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6), // Teal
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: DoctorTheme.spacing12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DoctorTheme.spacing12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _notifications.removeAt(index);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.red,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: DoctorTheme.spacing12,
                    ),
                  ),
                  child: const Text(
                    'Refuser',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateTime) {
    try {
      if (dateTime.isEmpty) return '';
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else {
        return 'Il y a ${difference.inDays}j';
      }
    } catch (e) {
      return '';
    }
  }
}
