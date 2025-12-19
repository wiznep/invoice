import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/invoice.dart';

/// Badge widget for displaying payment/estimate status
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.isSmall = false,
  });

  factory StatusBadge.fromPaymentStatus(
    PaymentStatus status, {
    bool isSmall = false,
  }) {
    switch (status) {
      case PaymentStatus.paid:
        return StatusBadge(
          label: 'Paid',
          color: AppColors.paid.withOpacity(0.15),
          textColor: AppColors.paid,
          isSmall: isSmall,
        );
      case PaymentStatus.partial:
        return StatusBadge(
          label: 'Partial',
          color: AppColors.partial.withOpacity(0.15),
          textColor: AppColors.partial,
          isSmall: isSmall,
        );
      case PaymentStatus.unpaid:
        return StatusBadge(
          label: 'Unpaid',
          color: AppColors.unpaid.withOpacity(0.15),
          textColor: AppColors.unpaid,
          isSmall: isSmall,
        );
    }
  }

  factory StatusBadge.overdue({bool isSmall = false}) {
    return StatusBadge(
      label: 'Overdue',
      color: AppColors.overdue.withOpacity(0.15),
      textColor: AppColors.overdue,
      isSmall: isSmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(isSmall ? 4 : 6),
      ),
      child: Text(
        label,
        style: (isSmall ? AppTypography.labelSmall : AppTypography.labelMedium)
            .copyWith(
              color: textColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
