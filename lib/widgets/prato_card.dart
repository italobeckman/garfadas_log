import 'dart:io';
import 'package:flutter/material.dart';
import '../models/prato.dart';
import 'app_colors.dart';
import 'app_layout.dart';
import 'app_text.dart';

class PratoCard extends StatelessWidget {
  final Prato prato;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?>? onCheckboxChanged;

  const PratoCard({
    super.key,
    required this.prato,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onTap,
    required this.onLongPress,
    this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppLayout.spaceM, vertical: AppLayout.spaceS),
      elevation: isSelected ? 4 : AppLayout.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: AppLayout.borderMedium, 
        side: isSelected ? const BorderSide(color: AppColors.danger, width: 2) : BorderSide.none
      ),
      color: isSelected ? AppColors.dangerLight : AppColors.cardBackground,
      child: InkWell(
        borderRadius: AppLayout.borderMedium,
        onLongPress: onLongPress,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceS, vertical: AppLayout.spaceXS),
          child: Row(
            children: [
              if (isSelectionMode)
                Checkbox(
                  value: isSelected,
                  activeColor: AppColors.danger,
                  onChanged: onCheckboxChanged,
                ),
              if (prato.imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                  child: ClipRRect(
                    borderRadius: AppLayout.borderSmall,
                    child: _buildImage(prato.imagePath!),
                  ),
                ),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  title: AppText.body(prato.descricaoPrato, bold: true),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          AppText.detail(prato.nomeLocal ?? 'Desconhecido'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          AppText(prato.data, type: AppTextType.caption),
                        ],
                      ),
                      if (prato.observacoes != null && prato.observacoes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        AppText.detail(
                          prato.observacoes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.textLight,
                        ),
                      ],
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        prato.voltaria ? Icons.thumb_up : Icons.thumb_down, 
                        color: prato.voltaria ? AppColors.success : AppColors.danger, 
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          AppText.subtitle(
                            prato.mediaAvaliacao.toStringAsFixed(1),
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
      );
    }
    return Image.file(
      File(path),
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
    );
  }
}
