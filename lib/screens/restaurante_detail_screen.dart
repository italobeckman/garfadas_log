import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/restaurante.dart';
import '../models/prato.dart';
import '../widgets/prato_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_text.dart';
import 'cadastro_prato_screen.dart';
import 'prato_detail_screen.dart';

class RestauranteDetailScreen extends StatefulWidget {
  final int restauranteId;

  const RestauranteDetailScreen({super.key, required this.restauranteId});

  @override
  State<RestauranteDetailScreen> createState() => _RestauranteDetailScreenState();
}

class _RestauranteDetailScreenState extends State<RestauranteDetailScreen> {
  // Estado para Seleção Múltipla
  bool _isSelectionMode = false;
  final Set<int> _selectedPratos = {};

  Future<void> _deletarRestaurante() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 60, color: AppColors.danger),
              const SizedBox(height: 16),
              AppText.subtitle('Aviso de Remoção'),
              const SizedBox(height: 8),
              const AppText(
                'Esta ação apagará o restaurante e todas as avaliações vinculadas de forma definitiva.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: AppLayout.borderMedium),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final provider = context.read<AppProvider>();
                    await provider.deleteRestaurante(widget.restauranteId);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: AppText('Restaurante excluído com sucesso.', color: Colors.white), 
                        backgroundColor: AppColors.danger
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const AppText('Excluir Restaurante', type: AppTextType.button),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const AppText('Cancelar', color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteSelectedPratos() async {
    if (_selectedPratos.isEmpty) return;
    
    final int contagem = _selectedPratos.length;
    final provider = context.read<AppProvider>();
    
    await provider.deleteMultiplePratos(_selectedPratos);
    
    setState(() {
      _isSelectionMode = false;
      _selectedPratos.clear();
    });
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText('$contagem avaliação(ões) excluída(s).', color: Colors.white),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedPratos.contains(id)) {
        _selectedPratos.remove(id);
        if (_selectedPratos.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPratos.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final restaurante = provider.restaurantes.firstWhere(
          (r) => r.id == widget.restauranteId,
          orElse: () => Restaurante(id: -1, nome: '', tipo: ''),
        );

        if (restaurante.id == -1) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: AppText('Restaurante não encontrado')),
          );
        }

        final pratos = provider.pratos.where((p) => p.restauranteId == restaurante.id).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(restaurante),
              SliverToBoxAdapter(
                child: _buildHeader(restaurante),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 10, bottom: 80),
                sliver: _buildPratosList(pratos),
              ),
            ],
          ),
          floatingActionButton: _isSelectionMode
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CadastroPratoScreen(restauranteId: restaurante.id!),
                      ),
                    );
                  },
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const AppText('Nova Avaliação', type: AppTextType.button, color: Colors.white),
                ),
        );
      },
    );
  }

  Widget _buildAppBar(Restaurante restaurante) {
    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      elevation: 0,
      backgroundColor: _isSelectionMode ? AppColors.dangerLight : AppColors.primary,
      foregroundColor: _isSelectionMode ? AppColors.danger : Colors.white,
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedPratos.clear();
                });
              },
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        title: AppText.subtitle(
          _isSelectionMode ? '${_selectedPratos.length} Selecionados' : restaurante.nome,
          color: _isSelectionMode ? AppColors.danger : Colors.white,
        ),
        background: Hero(
          tag: 'rest_${restaurante.id}',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _isSelectionMode ? AppColors.dangerLight : AppColors.primary,
                  _isSelectionMode ? AppColors.dangerLight.withOpacity(0.8) : AppColors.primary.withOpacity(0.7),
                ],
              ),
            ),
            child: Icon(
              Icons.restaurant, 
              size: 80, 
              color: _isSelectionMode ? AppColors.danger.withOpacity(0.1) : Colors.white24
            ),
          ),
        ),
      ),
      actions: _isSelectionMode
          ? [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedPratos,
                tooltip: 'Apagar seleção',
              )
            ]
          : [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deletarRestaurante();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.danger),
                        SizedBox(width: 8),
                        AppText('Excluir Restaurante', color: AppColors.danger),
                      ],
                    ),
                  ),
                ],
              ),
            ],
    );
  }

  Widget _buildHeader(Restaurante restaurante) {
    return Container(
      padding: AppLayout.paddingL,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.body(restaurante.tipo, color: AppColors.textSecondary),
                  const SizedBox(height: AppLayout.spaceXS),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.warning, size: 20),
                      const SizedBox(width: 4),
                      AppText.title(
                        restaurante.notaGeral?.toStringAsFixed(1) ?? '-',
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ],
              ),
              if (restaurante.voltaria != null)
                _buildStatusCircle(restaurante.voltaria!),
            ],
          ),
          const SizedBox(height: AppLayout.spaceM),
          
          // Override Manual UI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: AppLayout.borderMedium,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.body('Classificação Manual', bold: true),
                      AppText('Ignorar as notas e forçar opinião', type: AppTextType.caption),
                    ],
                  ),
                ),
                PopupMenuButton<bool?>(
                  tooltip: 'Escolha manual',
                  onSelected: (bool? value) async {
                    restaurante.overrideVoltaria = value;
                    final provider = context.read<AppProvider>();
                    await provider.updateRestaurante(restaurante);
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<bool?>(
                      value: null,
                      child: AppText('Automático (Média)'),
                    ),
                    const PopupMenuItem<bool?>(
                      value: true,
                      child: AppText('Voltaria 👍'),
                    ),
                    const PopupMenuItem<bool?>(
                      value: false,
                      child: AppText('Não Voltaria 👎'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppLayout.borderSmall,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText.body(
                          restaurante.overrideVoltaria == null
                              ? 'Auto'
                              : (restaurante.overrideVoltaria! ? 'Sim' : 'Não'),
                          color: AppColors.primary,
                          bold: true,
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppLayout.spaceM),
          const Divider(),
          const SizedBox(height: AppLayout.spaceM),
          AppText.subtitle('Avaliações do Cardápio'),
        ],
      ),
    );
  }

  Widget _buildStatusCircle(bool voltaria) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: voltaria ? AppColors.successLight : AppColors.dangerLight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        voltaria ? Icons.thumb_up : Icons.thumb_down,
        color: voltaria ? AppColors.success : AppColors.danger,
        size: 28,
      ),
    );
  }

  Widget _buildPratosList(List<Prato> pratos) {
    if (pratos.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyState(
          message: 'Nenhum prato avaliado ainda.',
          icon: Icons.no_food,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
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
            onCheckboxChanged: (val) {
              _toggleSelection(prato.id!);
            },
          );
        },
        childCount: pratos.length,
      ),
    );
  }
}
