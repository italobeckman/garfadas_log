import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/prato.dart';
import '../models/restaurante.dart';
import '../widgets/prato_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_text.dart';
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
          content: AppText('$contagem avaliação(ões) excluída(s).', color: Colors.white),
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
        if (_selectedPratos.isEmpty) {
          _isSelectionMode = false;
        }
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
          content: AppText('Cadastre um restaurante primeiro!', color: Colors.white), 
          backgroundColor: AppColors.warning
        ),
      );
      return;
    }

    final selectedRestaurante = await showDialog<Restaurante>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: AppText.subtitle('Escolha o Restaurante'),
          shape: RoundedRectangleBorder(borderRadius: AppLayout.borderMedium),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: restaurantes.length,
              itemBuilder: (context, index) {
                final rest = restaurantes[index];
                return ListTile(
                  leading: const Icon(Icons.store, color: AppColors.primary),
                  title: AppText.body(rest.nome),
                  onTap: () => Navigator.pop(context, rest),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const AppText('Cancelar', color: AppColors.textSecondary),
            ),
          ],
        );
      },
    );

    if (selectedRestaurante != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CadastroPratoScreen(restauranteId: selectedRestaurante.id!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: AppText.subtitle(
          _isSelectionMode ? '${_selectedPratos.length} Selecionados' : 'Todas as Refeições', 
          color: _isSelectionMode ? AppColors.danger : AppColors.primary,
        ),
        backgroundColor: _isSelectionMode ? AppColors.dangerLight : Colors.transparent,
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
                )
              ]
            : [
                IconButton(
                  icon: Icon(_sortDesc ? Icons.arrow_downward : Icons.arrow_upward, color: AppColors.primary),
                  tooltip: _sortDesc ? 'Maior para Menor' : 'Menor para Maior',
                  onPressed: () {
                    setState(() {
                      _sortDesc = !_sortDesc;
                    });
                  },
                )
              ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.pratos.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          List<Prato> pratos = List.from(provider.pratos);
          if (_sortDesc) {
            pratos.sort((a, b) => b.mediaAvaliacao.compareTo(a.mediaAvaliacao));
          } else {
            pratos.sort((a, b) => a.mediaAvaliacao.compareTo(b.mediaAvaliacao));
          }

          if (pratos.isEmpty) {
            return const EmptyState(
              message: 'Nenhuma refeição registrada.',
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
                onCheckboxChanged: (val) {
                  _toggleSelection(prato.id!);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? null 
          : FloatingActionButton.extended(
              onPressed: _novoPratoGlobal,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const AppText('Novo Prato', type: AppTextType.button, color: Colors.white),
            ),
    );
  }
}
