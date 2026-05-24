import 'package:flutter/material.dart';
import 'app_colors.dart';

enum AppTextType {
  title,
  subtitle,
  body,
  detail,
  caption,
  button,
}

class AppText extends StatelessWidget {
  final String text;
  final AppTextType type;
  final Color? color;
  final bool bold;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
    this.text, {
    super.key,
    this.type = AppTextType.body,
    this.color,
    this.bold = false,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  const AppText.title(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow}) : 
    type = AppTextType.title, bold = true;
    
  const AppText.subtitle(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow}) : 
    type = AppTextType.subtitle, bold = true;
    
  const AppText.body(this.text, {super.key, this.color, this.bold = false, this.textAlign, this.maxLines, this.overflow}) : 
    type = AppTextType.body;

  const AppText.detail(this.text, {super.key, this.color, this.bold = false, this.textAlign, this.maxLines, this.overflow}) : 
    type = AppTextType.detail;

  @override
  Widget build(BuildContext context) {
    TextStyle style;
    
    switch (type) {
      case AppTextType.title:
        style = TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: color ?? AppColors.textPrimary,
        );
        break;
      case AppTextType.subtitle:
        style = TextStyle(
          fontSize: 18,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: color ?? AppColors.textPrimary,
        );
        break;
      case AppTextType.body:
        style = TextStyle(
          fontSize: 16,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppColors.textPrimary,
        );
        break;
      case AppTextType.detail:
        style = TextStyle(
          fontSize: 14,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppColors.textSecondary,
        );
        break;
      case AppTextType.caption:
        style = TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppColors.textLight,
        );
        break;
      case AppTextType.button:
        style = TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.white,
        );
        break;
    }

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
