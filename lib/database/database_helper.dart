import 'dart:typed_data';
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
    final List<dynamic> maps = await _client.from('restaurantes').select();
    return maps.map((map) => Restaurante.fromMap(map as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getRawRestaurantesComPratos() async {
    final List<dynamic> maps = await _client.from('restaurantes').select('*, pratos(*)');
    return List<Map<String, dynamic>>.from(maps);
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

  Future<String> uploadPratoImage(String fileName, Uint8List imageBytes) async {
    await _client.storage.from('pratos_images').uploadBinary(fileName, imageBytes);
    return _client.storage.from('pratos_images').getPublicUrl(fileName);
  }
}
