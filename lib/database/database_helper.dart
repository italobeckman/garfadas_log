import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurante.dart';
import '../models/prato.dart';

class DatabaseHelper {
  // Construtor Singleton
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  final _client = Supabase.instance.client;

  // --- MÉTODOS PARA RESTAURANTES ---

  Future<int> insertRestaurante(Restaurante r) async {
    final map = r.toMap();
    map.remove('id');
    final response = await _client.from('restaurantes').insert(map).select('id').single();
    return response['id'] as int;
  }

  Future<List<Restaurante>> getAllRestaurantes() async {
    // Busca restaurantes e seus pratos associados para poder calcular as métricas no app
    final List<dynamic> maps = await _client.from('restaurantes').select('*, pratos(*)');

    List<Restaurante> restaurantes = [];
    for (var map in maps) {
      Restaurante rest = Restaurante.fromMap(map as Map<String, dynamic>);
      _carregarMetricasRestaurante(map, rest);
      restaurantes.add(rest);
    }
    return restaurantes;
  }

  Future<List<Restaurante>> getRestaurantesByClassificacao(bool voltaria) async {
    List<Restaurante> tds = await getAllRestaurantes();
    return tds.where((r) => r.voltaria == voltaria).toList();
  }

  void _carregarMetricasRestaurante(Map<String, dynamic> map, Restaurante rest) {
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
    final map = r.toMap();
    map.remove('id');
    await _client.from('restaurantes').update(map).eq('id', r.id!);
    return 1;
  }

  Future<int> deleteRestaurante(int id) async {
    await _client.from('restaurantes').delete().eq('id', id);
    return 1;
  }

  // --- MÉTODOS PARA PRATOS ---

  Future<int> insertPrato(Prato p) async {
    final map = p.toMap();
    map.remove('id'); // Remove null id on insert
    final response = await _client.from('pratos').insert(map).select('id').single();
    return response['id'] as int;
  }

  Future<List<Prato>> getAllPratosComRestaurante() async {
    // Usando inner join para trazer o nome do restaurante
    final List<dynamic> maps = await _client.from('pratos').select('*, restaurantes(nome)');
    return List.generate(maps.length, (i) => Prato.fromMap(maps[i] as Map<String, dynamic>));
  }

  Future<List<Prato>> getPratosByRestaurante(int restauranteId) async {
    final List<dynamic> maps = await _client.from('pratos').select().eq('restauranteId', restauranteId);
    return List.generate(maps.length, (i) => Prato.fromMap(maps[i] as Map<String, dynamic>));
  }

  Future<int> updatePrato(Prato p) async {
    final map = p.toMap();
    map.remove('id');
    await _client.from('pratos').update(map).eq('id', p.id!);
    return 1;
  }

  Future<int> deletePrato(int id) async {
    await _client.from('pratos').delete().eq('id', id);
    return 1;
  }
}
