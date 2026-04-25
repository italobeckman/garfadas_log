import 'package:flutter/material.dart';
import '../models/restaurante.dart';
import 'app_colors.dart';
import 'app_layout.dart';
import 'app_text.dart';

class RestauranteCard extends StatelessWidget {
  final Restaurante restaurante;
  final VoidCallback onTap;

  const RestauranteCard({
    super.key,
    required this.restaurante,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppLayout.spaceM, vertical: AppLayout.spaceS),
      elevation: AppLayout.cardElevation,
      shape: RoundedRectangleBorder(borderRadius: AppLayout.borderMedium),
      color: AppColors.cardBackground,
      child: InkWell(
        borderRadius: AppLayout.borderMedium,
        onTap: onTap,
        child: Padding(
          padding: AppLayout.paddingM,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AppText.subtitle(
                      restaurante.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (restaurante.voltaria != null)
                    _buildVoltariaBadge(restaurante.voltaria!),
                ],
              ),
              const SizedBox(height: AppLayout.spaceS),
              Row(
                children: [
                  const Icon(Icons.category, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppLayout.spaceXS),
                  AppText.detail(restaurante.tipo),
                  const SizedBox(width: AppLayout.spaceM),
                  const Icon(Icons.restaurant_menu, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppLayout.spaceXS),
                  AppText.detail('${restaurante.totalPratos} Pratos'),
                ],
              ),
              if (restaurante.ultimoPrato != null) ...[
                const SizedBox(height: AppLayout.spaceM),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: AppLayout.borderSmall,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const AppText('Último: ', type: AppTextType.caption, bold: true),
                      Expanded(
                        child: AppText(
                          restaurante.ultimoPrato!,
                          type: AppTextType.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppLayout.spaceM),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const AppText('Nota Geral', type: AppTextType.caption),
                  const SizedBox(width: AppLayout.spaceXS),
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 2),
                  AppText.subtitle(
                    restaurante.notaGeral != null ? restaurante.notaGeral!.toStringAsFixed(1) : '-',
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoltariaBadge(bool voltaria) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: voltaria ? AppColors.successLight : AppColors.dangerLight,
        borderRadius: AppLayout.borderLarge,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            voltaria ? Icons.thumb_up : Icons.thumb_down, 
            size: 14, 
            color: voltaria ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 6),
          AppText(
            voltaria ? 'Voltaria' : 'Não voltaria',
            type: AppTextType.caption,
            bold: true,
            color: voltaria ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }
}
