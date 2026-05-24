import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_layout.dart';

class CustomInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final IconData? icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;
  final bool isPassword;

  const CustomInput({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.focusNode,
    this.onFieldSubmitted,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onFieldSubmitted: onFieldSubmitted,
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: isPassword,
      enableSuggestions: !isPassword,
      autocorrect: !isPassword,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
        border: OutlineInputBorder(borderRadius: AppLayout.borderMedium),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppLayout.borderMedium,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppLayout.borderMedium,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.cardBackground,
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    );
  }
}
