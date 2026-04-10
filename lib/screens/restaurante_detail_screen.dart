import 'package:flutter/material.dart';
import '../models/restaurante.dart';
import '../models/prato.dart';
import '../database/database_helper.dart';
import 'cadastro_prato_screen.dart';

class RestauranteDetailScreen extends StatefulWidget {
  final Restaurante restaurante;

  const RestauranteDetailScreen({super.key, required this.restaurante});

  @override
  State<RestauranteDetailScreen> createState() => _RestauranteDetailScreenState();
}

class _RestauranteDetailScreenState extends State<RestauranteDetailScreen> {
  late Future<List<Prato>> _pratosFuture;
  late Restaurante _restaurante;

  bool _isSelectionMode = false;
  Set<int> _selectedPratos = {};

  @override
  void initState() {
    super.initState();
    _restaurante = widget.restaurante;
    _loadPratos();
  }

  void _loadPratos() {
    setState(() {
      _pratosFuture = DatabaseHelper().getPratosByRestaurante(_restaurante.id!);
    });
  }

  Future<void> _refreshMetrics() async {
    final tdRestaurantes = await DatabaseHelper().getAllRestaurantes();
    final updatedList = tdRestaurantes.where((r) => r.id == _restaurante.id).toList();
    if (updatedList.isNotEmpty && mounted) {
      setState(() {
        _restaurante = updatedList.first;
      });
    }
  }

  Future<void> _deletarRestaurante() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Aviso de Perda Total',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta ação apagará o restaurante e todos os pratos vinculados no cardápio de forma definitiva. Deseja continuar?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context); // Fecha o bottom sheet
                    await DatabaseHelper().deleteRestaurante(_restaurante.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Restaurante excluído com sucesso.'), backgroundColor: Colors.red),
                      );
                      Navigator.pop(context, true); // Volta para Home
                    }
                  },
                  child: const Text('Excluir Restaurante', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Manter Restaurante', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
    await _refreshMetrics();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? '${_selectedPratos.length} Pratos' : _restaurante.nome,
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
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
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
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir Restaurante', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _restaurante.tipo,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Nota Geral: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    Text(
                      _restaurante.notaGeral != null
                          ? _restaurante.notaGeral!.toStringAsFixed(1)
                          : 'Sem notas',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const Spacer(),
                    if (_restaurante.voltaria != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _restaurante.voltaria! ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_restaurante.voltaria! ? Icons.thumb_up : Icons.thumb_down, 
                                 size: 14, 
                                 color: _restaurante.voltaria! ? Colors.green.shade700 : Colors.red.shade700),
                            const SizedBox(width: 4),
                            Text(
                              _restaurante.voltaria! ? 'Voltaria' : 'Não voltaria',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _restaurante.voltaria! ? Colors.green.shade700 : Colors.red.shade700
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Prato>>(
              future: _pratosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum prato registrado ainda.'));
                }

                final pratos = snapshot.data!;
                return ListView.builder(
                  itemCount: pratos.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final prato = pratos[index];
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
                                  title: Text(prato.descricaoPrato, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(prato.data),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(prato.voltaria ? Icons.thumb_up : Icons.thumb_down, 
                                           color: prato.voltaria ? Colors.green : Colors.red, size: 20),
                                      Text(prato.mediaAvaliacao.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CadastroPratoScreen(restauranteId: _restaurante.id!),
                  ),
                );
                if (result == true) {
                  _loadPratos();
                  _refreshMetrics();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo Prato'),
            ),
    );
  }
}
