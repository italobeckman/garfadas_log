import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_layout.dart';
import 'app_text.dart';

class RatingSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final Color activeColor;

  const RatingSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.body(label, bold: true),
        const SizedBox(height: AppLayout.spaceXS),
        Slider(
          value: value,
          min: 1.0,
          max: 5.0,
          divisions: 8,
          label: value.toStringAsFixed(1),
          activeColor: activeColor,
          inactiveColor: Colors.grey.shade200,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
