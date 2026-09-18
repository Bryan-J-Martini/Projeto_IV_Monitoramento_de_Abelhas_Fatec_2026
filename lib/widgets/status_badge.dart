import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class StatusBadge extends StatefulWidget {
  final bool isOnline;
  final String? customText;
  final bool compact;
  final bool enablePulse;

  const StatusBadge({
    super.key,
    required this.isOnline,
    this.customText,
    this.compact = false,
    this.enablePulse = true,
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOut,
      ),
    );

    if (widget.isOnline && widget.enablePulse) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline != oldWidget.isOnline) {
      if (widget.isOnline && widget.enablePulse) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        widget.isOnline ? AppColors.onlineGreen : AppColors.offlineRed;
    final text = widget.customText ??
        (widget.isOnline ? 'Online ESP32' : 'Offline');

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPulsingDot(statusColor, dotSize: 7.0),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.isOnline
                  ? AppColors.onlineGreen
                  : AppColors.mute,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (widget.isOnline ? AppColors.onlineGreen : AppColors.slate)
            .withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (widget.isOnline ? AppColors.onlineGreen : AppColors.slate)
              .withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPulsingDot(statusColor, dotSize: 8.0),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.isOnline ? AppColors.onlineGreen : AppColors.slate,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDot(Color color, {required double dotSize}) {
    if (!widget.isOnline || !widget.enablePulse) {
      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: color.withOpacity(
                    (1.0 - (_pulseController.value)).clamp(0.0, 0.7),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

