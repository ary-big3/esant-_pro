import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';
import 'access_requests_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late ApiService _apiService;
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);
      await TokenHelper.ensureTokenReady();

      debugPrint('📢 Chargement des notifications...');
      final response = await _apiService.get('/notifications?page=1&limit=50', requireAuth: true);

      debugPrint('📢 Réponse API complète: ${response.toString()}');
      debugPrint('📢 Réponse success: ${response['success']}');
      debugPrint('📢 Réponse data: ${response['data']}');
      debugPrint('📢 Réponse data type: ${response['data'].runtimeType}');
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        debugPrint('✅ ${(data as List).length} notifications reçues');
        
        if (mounted) {
          setState(() {
            _notifications = List.from(data);
            _isLoading = false;
          });
          debugPrint('✅ UI mise à jour avec ${_notifications.length} notifications');
        }
      } else {
        debugPrint('⚠️ Pas de données ou succès=false');
        debugPrint('⚠️ Message: ${response['message']}');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.post(
        '/notifications/$notificationId/read',
        body: {},
      );

      if (response['success'] == true) {
        // Rechargement des notifications
        _loadNotifications();
      }
    } catch (e) {
      debugPrint('Erreur lors du marquage de la notification: $e');
    }
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'appointment_scheduled':
        return '📅';
      case 'appointment_reminder':
        return '⏰';
      case 'exam_requested':
        return '🔬';
      case 'prescription':
        return '💊';
      case 'access_request':
        return '🔐';
      case 'access_approved':
        return '✅';
      case 'access_rejected':
        return '❌';
      default:
        return '📢';
    }
  }



  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'À l\'instant';
      } else if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays}j';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune notification',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          final isRead = notif['is_read'] == 1 || notif['is_read'] == true;
                          
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isRead
                                    ? AppColors.textLight.withValues(alpha: 0.2)
                                    : AppColors.secondary.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isRead
                                  ? Colors.transparent
                                  : AppColors.secondary.withValues(alpha: 0.05),
                            ),
                            child: InkWell(
                              onTap: () {
                                // Si c'est une notification de demande d'accès, naviguer vers l'écran des demandes
                                if (notif['notification_type'] == 'access_request') {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const AccessRequestsScreen(),
                                    ),
                                  );
                                }
                                // Marquer comme lue
                                _markAsRead(notif['notification_id'].toString());
                              },
                              child: ListTile(
                                leading: Text(
                                  _getNotificationIcon(notif['notification_type'] ?? 'default'),
                                  style: const TextStyle(fontSize: 24),
                                ),
                                title: Text(
                                  notif['title'] ?? 'Notification',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      notif['message'] ?? '',
                                      style: Theme.of(context).textTheme.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(notif['created_at'] ?? ''),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                                trailing: isRead
                                    ? null
                                    : Container(
                                        height: 12,
                                        width: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
    );
  }
}
