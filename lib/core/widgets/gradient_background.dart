import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget wrapper pour appliquer le dégradé background à un Scaffold
/// 
/// Utilisation:
/// ```dart
/// GradientBackground(
///   child: Scaffold(
///     appBar: AppBar(title: Text('Titre')),
///     body: YourContent(),
///   ),
/// )
/// ```
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: child,
    );
  }
}

/// Extension pour Scaffold avec gradient background
extension ScaffoldWithGradient on Scaffold {
  /// Enveloppe ce Scaffold avec un GradientBackground
  Widget withGradientBackground() {
    return GradientBackground(child: this);
  }
}
