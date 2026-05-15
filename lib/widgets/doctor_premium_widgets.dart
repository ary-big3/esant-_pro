import 'package:flutter/material.dart';
import '../../core/theme/doctor_theme.dart';

/// Card premium pour la UI médecin
class DoctorCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final bool isHoverable;

  const DoctorCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(DoctorTheme.spacing20),
    this.onTap,
    this.backgroundColor,
    this.shadows,
    this.isHoverable = true,
  }) : super(key: key);

  @override
  State<DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<DoctorCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? const Color(0xFF0F1A2E).withValues(alpha: 0.6),
            borderRadius: DoctorTheme.radiusMedium,
            border: Border.all(
              color: DoctorTheme.neonViolet.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: _isHovering && widget.onTap != null
                ? DoctorTheme.shadowMedium
                : (widget.shadows ?? DoctorTheme.shadowSoft),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Bouton premium dégradé
class DoctorButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final LinearGradient? gradient;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;

  const DoctorButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.gradient,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
  }) : super(key: key);

  @override
  State<DoctorButton> createState() => _DoctorButtonState();
}

class _DoctorButtonState extends State<DoctorButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? DoctorTheme.neonVioletGradient;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.isLoading || widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          padding: const EdgeInsets.symmetric(
            horizontal: DoctorTheme.spacing20,
            vertical: DoctorTheme.spacing12,
          ),
          decoration: BoxDecoration(
            gradient: widget.isDisabled
                ? null
                : gradient,
            color: widget.isDisabled ? DoctorTheme.surfaceSecondary : null,
            borderRadius: DoctorTheme.radiusMedium,
            boxShadow: _isHovering && !widget.isDisabled
                ? DoctorTheme.shadowMedium
                : DoctorTheme.shadowSoft,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon,
                            size: 18,
                            color: widget.isDisabled
                                ? DoctorTheme.textLight
                                : Colors.white),
                        const SizedBox(width: DoctorTheme.spacing8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.isDisabled
                              ? DoctorTheme.textLight
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Card de statistique premium
class StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final String? trend;
  final bool trendIsPositive;

  const StatisticCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.trend,
    this.trendIsPositive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(DoctorTheme.spacing12),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: DoctorTheme.radiusSmall,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DoctorTheme.spacing8,
                    vertical: DoctorTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: trendIsPositive
                        ? DoctorTheme.successGreen.withValues(alpha: 0.1)
                        : DoctorTheme.dangerRed.withValues(alpha: 0.1),
                    borderRadius: DoctorTheme.radiusSmall,
                  ),
                  child: Text(
                    trend!,
                    style: TextStyle(
                      color: trendIsPositive
                          ? DoctorTheme.successGreen
                          : DoctorTheme.dangerRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DoctorTheme.spacing16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: DoctorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: DoctorTheme.spacing4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: DoctorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header premium
class SectionHeaderDoctorUI extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeaderDoctorUI({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DoctorTheme.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DoctorTheme.spacing4),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: DoctorTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Action card avec icône et description
class ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final LinearGradient? gradient;

  const ActionCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(DoctorTheme.spacing12),
            decoration: BoxDecoration(
              gradient: gradient ?? DoctorTheme.blueVioletGradient,
              borderRadius: DoctorTheme.radiusSmall,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: DoctorTheme.spacing12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DoctorTheme.textPrimary,
            ),
          ),
          const SizedBox(height: DoctorTheme.spacing4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: DoctorTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
