import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/restaurante.dart';
import 'cadastro_restaurante_screen.dart';
import 'restaurante_detail_screen.dart';

class RestaurantesTab extends StatefulWidget {
  const RestaurantesTab({super.key});

  @override
  State<RestaurantesTab> createState() => _RestaurantesTabState();
}

class _RestaurantesTabState extends State<RestaurantesTab> {
  late Future<List<Restaurante>> _restaurantesFuture;
  
  // 0 = Todos, 1 = Voltaria, 2 = Não Voltaria
  int _filterState = 0;

  @override
  void initState() {
    super.initState();
    _loadRestaurantes();
  }

  void _loadRestaurantes() {
    setState(() {
      if (_filterState == 1) {
        _restaurantesFuture = DatabaseHelper().getRestaurantesByClassificacao(true);
      } else if (_filterState == 2) {
        _restaurantesFuture = DatabaseHelper().getRestaurantesByClassificacao(false);
      } else {
        _restaurantesFuture = DatabaseHelper().getAllRestaurantes();
      }
    });
  }

  void _cycleFilter() {
    setState(() {
      _filterState = (_filterState + 1) % 3;
      _loadRestaurantes();
    });
  }

  IconData _getFilterIcon() {
    if (_filterState == 1) return Icons.thumb_up;
    if (_filterState == 2) return Icons.thumb_down;
    return Icons.filter_list;
  }

  String _getFilterTooltip() {
    if (_filterState == 1) return 'Filtrando: Só os que eu voltaria';
    if (_filterState == 2) return 'Filtrando: Só os que não voltaria';
    return 'Exibindo Todos';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('GarfadasLog', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(_getFilterIcon()),
            tooltip: _getFilterTooltip(),
            onPressed: _cycleFilter,
          )
        ],
      ),
      body: FutureBuilder<List<Restaurante>>(
        future: _restaurantesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os dados.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final restaurantes = snapshot.data!;
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemCount: restaurantes.length,
            itemBuilder: (context, index) {
              final rest = restaurantes[index];
              return _buildRestauranteCard(rest);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastroRestauranteScreen()),
          );
          if (result == true) {
            _loadRestaurantes();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Restaurante'),
      ),
    );
  }

  Widget _buildEmptyState() {
    String msg = 'Nenhum restaurante registrado.';
    if (_filterState == 1) msg = 'Nenhum local que você voltaria.';
    if (_filterState == 2) msg = 'Nenhum local marcado como "Não voltaria".';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            msg,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            'Adicione um restaurante ou remova os filtros.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildRestauranteCard(Restaurante rest) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestauranteDetailScreen(restaurante: rest),
            ),
          );
          _loadRestaurantes();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      rest.nome,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rest.voltaria != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: rest.voltaria! ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(rest.voltaria! ? Icons.thumb_up : Icons.thumb_down, 
                               size: 14, 
                               color: rest.voltaria! ? Colors.green.shade700 : Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            rest.voltaria! ? 'Voltaria' : 'Não voltaria',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: rest.voltaria! ? Colors.green.shade700 : Colors.red.shade700
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(rest.tipo, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(width: 16),
                  Icon(Icons.restaurant_menu, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${rest.totalPratos} Pratos', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Nota Geral', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  Text(
                    rest.notaGeral != null ? rest.notaGeral!.toStringAsFixed(1) : '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
