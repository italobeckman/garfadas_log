import 'package:flutter/material.dart';
import '../models/prato.dart';
import '../models/restaurante.dart';
import '../database/database_helper.dart';
import 'cadastro_prato_screen.dart';

class PratosTab extends StatefulWidget {
  const PratosTab({super.key});

  @override
  State<PratosTab> createState() => _PratosTabState();
}

class _PratosTabState extends State<PratosTab> {
  late Future<List<Prato>> _pratosFuture;
  bool _sortDesc = true; 

  // Estado para Seleção Múltipla
  bool _isSelectionMode = false;
  Set<int> _selectedPratos = {};

  @override
  void initState() {
    super.initState();
    _loadPratos();
  }

  void _loadPratos() {
    setState(() {
      _pratosFuture = DatabaseHelper().getAllPratosComRestaurante().then((pratos) {
        if (_sortDesc) {
          pratos.sort((a, b) => b.mediaAvaliacao.compareTo(a.mediaAvaliacao));
        } else {
          pratos.sort((a, b) => a.mediaAvaliacao.compareTo(b.mediaAvaliacao));
        }
        return pratos;
      });
    });
  }

  Future<void> _deleteSelectedPratos() async {
    if (_selectedPratos.isEmpty) return;
    
    // Deleta do BD
    for (int id in _selectedPratos) {
      await DatabaseHelper().deletePrato(id);
    }
    
    final int contagem = _selectedPratos.length;
    
    setState(() {
      _isSelectionMode = false;
      _selectedPratos.clear();
    });
    
    _loadPratos();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$contagem avaliação(ões) excluída(s).'),
          backgroundColor: Colors.red.shade800,
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
    if (_isSelectionMode) return; // Bloqueia criar se estiver apagando

    final restaurantes = await DatabaseHelper().getAllRestaurantes();
    if (!mounted) return;

    if (restaurantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um restaurante primeiro!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final selectedRestaurante = await showDialog<Restaurante>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escolha o Restaurante'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: restaurantes.length,
              itemBuilder: (context, index) {
                final rest = restaurantes[index];
                return ListTile(
                  leading: const Icon(Icons.store),
                  title: Text(rest.nome),
                  onTap: () => Navigator.pop(context, rest),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (selectedRestaurante != null && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CadastroPratoScreen(restauranteId: selectedRestaurante.id!),
        ),
      );
      if (result == true) {
        _loadPratos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? '${_selectedPratos.length} Selecionados' : 'Todas as Refeições', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: _isSelectionMode ? Colors.red.shade100 : Colors.transparent,
        foregroundColor: _isSelectionMode ? Colors.red.shade900 : Theme.of(context).colorScheme.primary,
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
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedPratos,
                  tooltip: 'Apagar seleção',
                )
              ]
            : [
                IconButton(
                  icon: Icon(_sortDesc ? Icons.arrow_downward : Icons.arrow_upward),
                  tooltip: _sortDesc ? 'Maior para Menor' : 'Menor para Maior',
                  onPressed: () {
                    setState(() {
                      _sortDesc = !_sortDesc;
                      _loadPratos();
                    });
                  },
                )
              ],
      ),
      body: FutureBuilder<List<Prato>>(
        future: _pratosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar as refeições.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final pratos = snapshot.data!;
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemCount: pratos.length,
            itemBuilder: (context, index) {
              final prato = pratos[index];
              return _buildPratoCard(prato);
            },
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? null // Oculta botão de mais se tiver apagando
          : FloatingActionButton.extended(
              onPressed: _novoPratoGlobal,
              icon: const Icon(Icons.add),
              label: const Text('Novo Prato'),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'Nenhuma refeição registrada.',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPratoCard(Prato prato) {
    final bool isSelected = _selectedPratos.contains(prato.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), 
        side: isSelected ? BorderSide(color: Colors.red.shade400, width: 2) : BorderSide.none
      ),
      color: isSelected ? Colors.red.shade50 : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedPratos.add(prato.id!);
          });
        },
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(prato.id!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  activeColor: Colors.red.shade600,
                  onChanged: (val) {
                    _toggleSelection(prato.id!);
                  },
                ),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  title: Text(prato.descricaoPrato, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.storefront, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(prato.nomeLocal ?? 'Desconhecido', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(prato.data, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(prato.voltaria ? Icons.thumb_up : Icons.thumb_down, 
                           color: prato.voltaria ? Colors.green : Colors.red, size: 20),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(prato.mediaAvaliacao.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
}
