import '../models/restaurante.dart';
import '../models/prato.dart';
import '../database/database_helper.dart';

class RestauranteService {
  final DatabaseHelper _dbHelper;

  RestauranteService(this._dbHelper);

  Future<int> insertRestaurante(Restaurante r) async {
    return await _dbHelper.insertRestaurante(r);
  }

  Future<List<Restaurante>> getRestaurantes() async {
    final List<Map<String, dynamic>> rawMaps = await _dbHelper.getRawRestaurantesComPratos();

    List<Restaurante> restaurantes = [];
    for (var map in rawMaps) {
      Restaurante rest = Restaurante.fromMap(map);
      _calcularMetricasRestaurante(map, rest);
      restaurantes.add(rest);
    }
    return restaurantes;
  }

  Future<List<Restaurante>> getRestaurantesByClassificacao(bool voltaria) async {
    List<Restaurante> tds = await getRestaurantes();
    return tds.where((r) => r.voltaria == voltaria).toList();
  }

  void _calcularMetricasRestaurante(Map<String, dynamic> map, Restaurante rest) {
    List<dynamic> pratosMap = map['pratos'] ?? [];
    
    if (pratosMap.isNotEmpty) {
      rest.totalPratos = pratosMap.length;
      
      double somaAvaliacao = 0;
      // Encontrar o prato mais recente
      Map<String, dynamic>? ultimoPrato;

      for (var pMap in pratosMap) {
        final prato = Prato.fromMap(pMap as Map<String, dynamic>);
        somaAvaliacao += prato.mediaAvaliacao;
        
        if (ultimoPrato == null || (pMap['id'] as int) > (ultimoPrato['id'] as int)) {
          ultimoPrato = pMap;
        }
      }

      rest.notaGeral = somaAvaliacao / rest.totalPratos;
      
      if (ultimoPrato != null) {
        rest.ultimoPrato = ultimoPrato['descricaoPrato'] as String;
      }

      if (rest.overrideVoltaria != null) {
        rest.voltaria = rest.overrideVoltaria;
      } else {
        rest.voltaria = rest.notaGeral! >= 3.5;
      }
    } else {
      rest.totalPratos = 0;
      rest.notaGeral = null;
      rest.voltaria = rest.overrideVoltaria;
      rest.ultimoPrato = null;
    }
  }

  Future<int> updateRestaurante(Restaurante r) async {
    return await _dbHelper.updateRestaurante(r);
  }

  Future<int> deleteRestaurante(int id) async {
    return await _dbHelper.deleteRestaurante(id);
  }
}
