import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_layout.dart';
import 'app_text.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: color ?? AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppLayout.borderMedium),
      padding: const EdgeInsets.symmetric(vertical: 14),
      elevation: 2,
    );

    final labelWidget = AppText(
      label,
      type: AppTextType.button,
      color: Colors.white,
    );

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: labelWidget,
        style: style,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: labelWidget,
    );
  }
}
