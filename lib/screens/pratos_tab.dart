import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/prato.dart';
import '../models/restaurante.dart';
import '../services/pdf_service.dart';
import '../widgets/prato_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_text.dart';
import '../widgets/filter_sheet.dart';
import 'cadastro_prato_screen.dart';
import 'prato_detail_screen.dart';

class PratosTab extends StatefulWidget {
  const PratosTab({super.key});

  @override
  State<PratosTab> createState() => _PratosTabState();
}

class _PratosTabState extends State<PratosTab> {
  bool _sortDesc = true;

  // Estado para Seleção Múltipla
  bool _isSelectionMode = false;
  final Set<int> _selectedPratos = {};

  // ─── Seleção múltipla ─────────────────────────────────────────────────────

  Future<void> _deleteSelectedPratos() async {
    if (_selectedPratos.isEmpty) return;

    final int contagem = _selectedPratos.length;
    final provider = context.read<AppProvider>();

    await provider.deleteMultiplePratos(_selectedPratos);

    setState(() {
      _isSelectionMode = false;
      _selectedPratos.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              AppText('$contagem avaliação(ões) excluída(s).', color: Colors.white),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedPratos.contains(id)) {
        _selectedPratos.remove(id);
        if (_selectedPratos.isEmpty) _isSelectionMode = false;
      } else {
        _selectedPratos.add(id);
      }
    });
  }

  Future<void> _novoPratoGlobal() async {
    if (_isSelectionMode) return;

    final provider = context.read<AppProvider>();
    final restaurantes = provider.restaurantes;

    if (restaurantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              AppText('Cadastre um restaurante primeiro!', color: Colors.white),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final selectedRestaurante = await showDialog<Restaurante>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: AppText.subtitle('Escolha o Restaurante'),
          shape:
              RoundedRectangleBorder(borderRadius: AppLayout.borderMedium),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: restaurantes.length,
              itemBuilder: (context, index) {
                final rest = restaurantes[index];
                return ListTile(
                  leading:
                      const Icon(Icons.store, color: AppColors.primary),
                  title: AppText.body(rest.nome),
                  onTap: () => Navigator.pop(context, rest),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const AppText('Cancelar',
                  color: AppColors.textSecondary),
            ),
          ],
        );
      },
    );

    if (selectedRestaurante != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CadastroPratoScreen(restauranteId: selectedRestaurante.id!),
        ),
      );
    }
  }

  // ─── Filtro ───────────────────────────────────────────────────────────────

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PratoFilterSheet(),
    );
  }

  // ─── Exportação PDF ───────────────────────────────────────────────────────

  Future<void> _exportarPdf(List<Prato> lista, bool filtroAtivo) async {
    if (lista.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              AppText('Nenhum prato para exportar.', color: Colors.white),
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
      await context.read<PdfService>().exportarRelatorioPratos(
            lista,
            filtroAtivo ? descricao : '',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                AppText('PDF gerado com sucesso!', color: Colors.white),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                AppText('Erro ao gerar PDF: $e', color: Colors.white),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String _buildDescricaoFiltro(AppProvider p) {
    final parts = <String>[];
    if (p.searchPrato.isNotEmpty) parts.add('Prato: "${p.searchPrato}"');
    if (p.restauranteIdFilter != null) {
      final rest = p.restaurantes
          .where((r) => r.id == p.restauranteIdFilter)
          .firstOrNull;
      if (rest != null) parts.add('Restaurante: ${rest.nome}');
    }
    if (p.voltariaPratoFilter != null) {
      parts.add(p.voltariaPratoFilter! ? 'Comeria: Sim' : 'Comeria: Não');
    }
    if (p.notaMinimaPrato > 0) {
      parts.add('Nota mín.: ${p.notaMinimaPrato.toStringAsFixed(1)}');
    }
    return parts.join(' | ');
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final filtroAtivo = provider.filtrosPratoAtivos;

        // Aplica ordenação sobre a lista já filtrada
        List<Prato> pratos = List.from(provider.pratosFiltrados);
        if (_sortDesc) {
          pratos.sort((a, b) => b.mediaAvaliacao.compareTo(a.mediaAvaliacao));
        } else {
          pratos.sort((a, b) => a.mediaAvaliacao.compareTo(b.mediaAvaliacao));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: AppText.subtitle(
              _isSelectionMode
                  ? '${_selectedPratos.length} Selecionados'
                  : 'Todas as Refeições',
              color: _isSelectionMode
                  ? AppColors.danger
                  : AppColors.primary,
            ),
            backgroundColor: _isSelectionMode
                ? AppColors.dangerLight
                : Colors.transparent,
            centerTitle: true,
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.danger),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedPratos.clear();
                      });
                    },
                  )
                : null,
            actions: _isSelectionMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.danger),
                      onPressed: _deleteSelectedPratos,
                      tooltip: 'Apagar seleção',
                    ),
                  ]
                : [
                    // Ordenação
                    IconButton(
                      icon: Icon(
                        _sortDesc
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: AppColors.primary,
                      ),
                      tooltip: _sortDesc
                          ? 'Maior para Menor'
                          : 'Menor para Maior',
                      onPressed: () =>
                          setState(() => _sortDesc = !_sortDesc),
                    ),
                    // Filtro (com badge)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: Icon(
                            filtroAtivo
                                ? Icons.filter_alt
                                : Icons.filter_alt_outlined,
                            color: filtroAtivo
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          tooltip: filtroAtivo
                              ? 'Filtros ativos'
                              : 'Filtrar',
                          onPressed: _abrirFiltros,
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
                    // Exportar PDF
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined,
                          color: AppColors.textSecondary),
                      tooltip: 'Exportar para PDF',
                      onPressed: () =>
                          _exportarPdf(pratos, filtroAtivo),
                    ),
                  ],
          ),
          body: Column(
            children: [
              // Banner de filtros ativos
              if (filtroAtivo)
                _FiltroAtivosBanner(
                  descricao: _buildDescricaoFiltro(provider),
                  onLimpar: provider.limparFiltrosPrato,
                ),
              Expanded(
                child: _buildBody(provider, pratos, filtroAtivo),
              ),
            ],
          ),
          floatingActionButton: _isSelectionMode
              ? null
              : FloatingActionButton.extended(
                  onPressed: _novoPratoGlobal,
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const AppText('Novo Prato',
                      type: AppTextType.button, color: Colors.white),
                ),
        );
      },
    );
  }

  Widget _buildBody(
      AppProvider provider, List<Prato> pratos, bool filtroAtivo) {
    if (provider.isLoading && provider.pratos.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (pratos.isEmpty) {
      return EmptyState(
        message: filtroAtivo
            ? 'Nenhuma avaliação encontrada.'
            : 'Nenhuma refeição registrada.',
        subMessage: filtroAtivo
            ? 'Ajuste os filtros ou limpe a busca.'
            : null,
        icon: Icons.fastfood_outlined,
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80, top: 10),
      itemCount: pratos.length,
      itemBuilder: (context, index) {
        final prato = pratos[index];
        return PratoCard(
          prato: prato,
          isSelected: _selectedPratos.contains(prato.id),
          isSelectionMode: _isSelectionMode,
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(prato.id!);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PratoDetailScreen(prato: prato),
                ),
              );
            }
          },
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedPratos.add(prato.id!);
            });
          },
          onCheckboxChanged: (val) => _toggleSelection(prato.id!),
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
