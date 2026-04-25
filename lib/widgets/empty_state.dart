import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_layout.dart';
import 'app_text.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? subMessage;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.subMessage,
    this.icon = Icons.hourglass_empty,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppLayout.paddingL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: AppLayout.spaceL),
            AppText.subtitle(
              message,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: AppLayout.spaceS),
              AppText.detail(
                subMessage!,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
