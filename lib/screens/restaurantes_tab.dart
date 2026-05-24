import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/restaurante.dart';
import '../widgets/restaurante_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_text.dart';
import 'cadastro_restaurante_screen.dart';
import 'restaurante_detail_screen.dart';
import '../services/auth_service.dart';

class RestaurantesTab extends StatefulWidget {
  const RestaurantesTab({super.key});

  @override
  State<RestaurantesTab> createState() => _RestaurantesTabState();
}

class _RestaurantesTabState extends State<RestaurantesTab> {
  // 0 = Todos, 1 = Voltaria, 2 = Não Voltaria
  int _filterState = 0;

  void _cycleFilter() {
    setState(() {
      _filterState = (_filterState + 1) % 3;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: AppText.title('GarfadasLog', color: AppColors.primary),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_getFilterIcon(), color: AppColors.primary),
            tooltip: _getFilterTooltip(),
            onPressed: _cycleFilter,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger),
            tooltip: 'Sair da conta',
            onPressed: () async {
              await AuthService().signOut();
              // O AuthGate lidará com o redirecionamento automaticamente.
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.restaurantes.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          List<Restaurante> restaurantes = provider.restaurantes;
          if (_filterState == 1) {
            restaurantes = restaurantes.where((r) => r.voltaria == true).toList();
          } else if (_filterState == 2) {
            restaurantes = restaurantes.where((r) => r.voltaria == false).toList();
          }

          if (restaurantes.isEmpty) {
            String msg = 'Nenhum restaurante registrado.';
            if (_filterState == 1) msg = 'Nenhum local que você voltaria.';
            if (_filterState == 2) msg = 'Nenhum local marcado como "Não voltaria".';
            
            return EmptyState(
              message: msg,
              subMessage: 'Adicione um restaurante ou remova os filtros.',
              icon: Icons.store_outlined,
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemCount: restaurantes.length,
            itemBuilder: (context, index) {
              final rest = restaurantes[index];
              return RestauranteCard(
                restaurante: rest,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestauranteDetailScreen(restauranteId: rest.id!),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastroRestauranteScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const AppText('Novo Restaurante', type: AppTextType.button, color: Colors.white),
      ),
    );
  }
}

