import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/token_helper.dart';

class AccessRequestsScreen extends StatefulWidget {
  const AccessRequestsScreen({super.key});

  @override
  State<AccessRequestsScreen> createState() => _AccessRequestsScreenState();
}

class _AccessRequestsScreenState extends State<AccessRequestsScreen> {
  late ApiService _apiService;
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() => _isLoading = true);
      await TokenHelper.ensureTokenReady();

      final response = await _apiService.get(
        '/patients/pending-requests?page=1&limit=50',
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _requests = (response['data'] as List).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des demandes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      await TokenHelper.ensureTokenReady();
      final response = await _apiService.post(
        '/patients/requests/$requestId/approve',
        body: {},
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Accès approuvé✅')),
          );
          _loadRequests();
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'approbation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Demandes d\'accès'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune demande en attente',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.secondary.withValues(alpha: 0.05),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '👨‍⚕️',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request['full_name'] ?? 'Médecin',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        request['speciality_name'] ?? request['hospital_name'] ?? 'Spécialiste',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (request['reason'] != null && request['reason'].toString().isNotEmpty) ...[
                              Text(
                                'Raison:',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                request['reason'],
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              'Demande le: ${_formatDate(request['requested_at'] ?? '')}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Refuser'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _approveRequest(
                                      request['request_id'].toString(),
                                    ),
                                    child: const Text('Approuver'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
