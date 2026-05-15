import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class NfcCardWidget extends StatelessWidget {
  final String patientId;
  final String patientNom;
  final String? groupeSanguin;
  final bool isActive;
  final VoidCallback? onTap;

  const NfcCardWidget({
    super.key,
    required this.patientId,
    required this.patientNom,
    this.groupeSanguin,
    this.isActive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F1A2E), Color(0xFF1A2744)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F1A2E).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Motif décoratif
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.nfc,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Carte Biomédicale',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.success.withValues(alpha: 0.2)
                              : AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? AppColors.success : AppColors.error,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: isActive ? AppColors.success : AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    patientNom.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID Patient',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatPatientId(patientId),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      if (groupeSanguin != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            groupeSanguin!,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }

  String _formatPatientId(String id) {
    if (id.length <= 4) return id;
    return '${id.substring(0, 4)} •••• ${id.substring(id.length - 4)}';
  }
}

// Widget pour scanner NFC
class NfcScannerWidget extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onScan;
  final String? lastScannedId;

  const NfcScannerWidget({
    super.key,
    this.isScanning = false,
    required this.onScan,
    this.lastScannedId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isScanning ? AppColors.primary : AppColors.surfaceVariant,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isScanning
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant,
            ),
            child: Icon(
              Icons.nfc,
              size: 48,
              color: isScanning ? AppColors.primary : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isScanning
                ? 'Approchez la carte NFC...'
                : 'Scanner une carte NFC',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isScanning ? AppColors.primary : AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isScanning
                ? 'Maintenez la carte près du lecteur'
                : 'Appuyez pour démarrer le scan',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (lastScannedId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'ID: $lastScannedId',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: 180,
            child: ElevatedButton.icon(
              onPressed: onScan,
              icon: Icon(isScanning ? Icons.stop : Icons.contactless),
              label: Text(isScanning ? 'Arrêter' : 'Scanner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isScanning ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
