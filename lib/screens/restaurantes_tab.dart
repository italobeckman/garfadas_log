import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/restaurante.dart';
import '../services/pdf_service.dart';
import '../widgets/restaurante_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_text.dart';
import '../widgets/filter_sheet.dart';
import 'cadastro_restaurante_screen.dart';
import 'restaurante_detail_screen.dart';
import '../services/auth_service.dart';

class RestaurantesTab extends StatelessWidget {
  const RestaurantesTab({super.key});

  // ─── Filtro ───────────────────────────────────────────────────────────────
  void _abrirFiltros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RestauranteFilterSheet(),
    );
  }

  // ─── Exportação PDF ───────────────────────────────────────────────────────
  Future<void> _exportarPdf(
      BuildContext context, List<Restaurante> lista, bool filtroAtivo) async {
    if (lista.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText('Nenhum restaurante para exportar.',
              color: Colors.white),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            AppText('Gerando PDF...', color: Colors.white),
          ],
        ),
        duration: Duration(seconds: 30),
        backgroundColor: AppColors.primary,
      ),
    );

    try {
      final provider = context.read<AppProvider>();
      final descricao = _buildDescricaoFiltro(provider);
      await context.read<PdfService>().exportarRelatorioRestaurantes(
            lista,
            filtroAtivo ? descricao : '',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText('PDF gerado com sucesso!', color: Colors.white),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText('Erro ao gerar PDF: $e', color: Colors.white),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String _buildDescricaoFiltro(AppProvider p) {
    final parts = <String>[];
    if (p.searchRestaurante.isNotEmpty) parts.add('Nome: "${p.searchRestaurante}"');
    if (p.tipoFilter != null) parts.add('Tipo: ${p.tipoFilter}');
    if (p.voltariaRestauranteFilter != null) {
      parts.add(p.voltariaRestauranteFilter! ? 'Voltaria: Sim' : 'Voltaria: Não');
    }
    if (p.notaMinimaRestaurante > 0) {
      parts.add('Nota mín.: ${p.notaMinimaRestaurante.toStringAsFixed(1)}');
    }
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final lista = provider.restaurantesFiltrados;
        final filtroAtivo = provider.filtrosRestauranteAtivos;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: AppText.title('GarfadasLog', color: AppColors.primary),
            backgroundColor: Colors.transparent,
            centerTitle: true,
            actions: [
              // ── Botão de filtro (com badge quando ativo) ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      filtroAtivo ? Icons.filter_alt : Icons.filter_alt_outlined,
                      color: filtroAtivo ? AppColors.primary : AppColors.textSecondary,
                    ),
                    tooltip: filtroAtivo ? 'Filtros ativos' : 'Filtrar',
                    onPressed: () => _abrirFiltros(context),
                  ),
                  if (filtroAtivo)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),

              // ── Botão exportar PDF ──
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.textSecondary),
                tooltip: 'Exportar para PDF',
                onPressed: () => _exportarPdf(context, lista, filtroAtivo),
              ),

              // ── Sair ──
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.danger),
                tooltip: 'Sair da conta',
                onPressed: () async => await AuthService().signOut(),
              ),
            ],
          ),

          // ── Banner de filtros ativos ──
          body: Column(
            children: [
              if (filtroAtivo)
                _FiltroAtivosBanner(
                  descricao: _buildDescricaoFiltro(provider),
                  onLimpar: provider.limparFiltrosRestaurante,
                ),
              Expanded(
                child: _buildBody(context, provider, lista, filtroAtivo),
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CadastroRestauranteScreen()),
              );
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const AppText('Novo Restaurante',
                type: AppTextType.button, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppProvider provider,
      List<Restaurante> lista, bool filtroAtivo) {
    if (provider.isLoading && provider.restaurantes.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (lista.isEmpty) {
      return EmptyState(
        message: filtroAtivo
            ? 'Nenhum restaurante encontrado.'
            : 'Nenhum restaurante registrado.',
        subMessage: filtroAtivo
            ? 'Tente ajustar os filtros ou limpe a busca.'
            : 'Adicione seu primeiro restaurante!',
        icon: Icons.store_outlined,
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80, top: 4),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final rest = lista[index];
        return RestauranteCard(
          restaurante: rest,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RestauranteDetailScreen(restauranteId: rest.id!),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Banner de filtros ativos ─────────────────────────────────────────────────

class _FiltroAtivosBanner extends StatelessWidget {
  final String descricao;
  final VoidCallback onLimpar;

  const _FiltroAtivosBanner(
      {required this.descricao, required this.onLimpar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.infoLight,
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: AppText(
              descricao,
              type: AppTextType.caption,
              color: AppColors.info,
            ),
          ),
          GestureDetector(
            onTap: onLimpar,
            child: const AppText('Limpar',
                type: AppTextType.caption,
                color: AppColors.danger,
                bold: true),
          ),
        ],
      ),
    );
  }
}
