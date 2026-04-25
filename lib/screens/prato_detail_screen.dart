import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prato.dart';
import '../providers/app_provider.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_text.dart';

class PratoDetailScreen extends StatelessWidget {
  final Prato prato;

  const PratoDetailScreen({super.key, required this.prato});

  Future<void> _deletarPrato(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText('Excluir Avaliação', bold: true),
        content: const AppText('Tem certeza que deseja apagar esta avaliação permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText('Cancelar', color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const AppText('Excluir', color: AppColors.danger, bold: true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<AppProvider>();
      await provider.deletePrato(prato.id!);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText('Avaliação excluída.', color: Colors.white),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppLayout.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildRatings(),
                  const SizedBox(height: 24),
                  if (prato.observacoes != null && prato.observacoes!.isNotEmpty) _buildObservations(),
                  const SizedBox(height: 40),
                  _buildDeleteButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: prato.imagePath != null ? 300.0 : 120.0,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: prato.imagePath != null
            ? Hero(
                tag: 'prato_${prato.id}',
                child: Image.file(
                  File(prato.imagePath!),
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: const Icon(Icons.fastfood, size: 80, color: Colors.white24),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AppText.title(prato.descricaoPrato, color: AppColors.textPrimary),
            ),
            _buildVoltariaBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.storefront, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            AppText.subtitle(prato.nomeLocal ?? 'Restaurante', color: AppColors.textSecondary),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.textLight),
            const SizedBox(width: 6),
            AppText(prato.data, type: AppTextType.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildVoltariaBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: prato.voltaria ? AppColors.successLight : AppColors.dangerLight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        prato.voltaria ? Icons.thumb_up : Icons.thumb_down,
        color: prato.voltaria ? AppColors.success : AppColors.danger,
        size: 24,
      ),
    );
  }

  Widget _buildRatings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppLayout.borderLarge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRatingRow('Qualidade da Comida', prato.notaComida, Colors.orange),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildRatingRow('Custo-Benefício', prato.notaCustoBeneficio, Colors.green),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText('Média Final', bold: true),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppLayout.borderSmall,
                ),
                child: AppText(
                  prato.mediaAvaliacao.toStringAsFixed(1),
                  color: Colors.white,
                  bold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.body(label),
            AppText.body(value.toStringAsFixed(1), bold: true, color: color),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value / 5.0,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(10),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildObservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText('Observações', type: AppTextType.subtitle),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: AppLayout.borderMedium,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: AppText.body(prato.observacoes!),
        ),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _deletarPrato(context),
        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
        label: const AppText('Excluir Avaliação', color: AppColors.danger, bold: true),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.danger),
          shape: RoundedRectangleBorder(borderRadius: AppLayout.borderMedium),
        ),
      ),
    );
  }
}
