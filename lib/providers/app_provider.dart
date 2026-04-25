import 'package:flutter/material.dart';
import '../models/restaurante.dart';
import '../models/prato.dart';
import '../database/database_helper.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Restaurante> _restaurantes = [];
  List<Prato> _pratos = [];
  bool _isLoading = false;

  List<Restaurante> get restaurantes => _restaurantes;
  List<Prato> get pratos => _pratos;
  bool get isLoading => _isLoading;

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadRestaurantes(),
      loadPratos(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRestaurantes() async {
    _restaurantes = await _dbHelper.getAllRestaurantes();
    notifyListeners();
  }

  Future<void> loadPratos() async {
    _pratos = await _dbHelper.getAllPratosComRestaurante();
    notifyListeners();
  }

  // CRUD Restaurante
  Future<void> addRestaurante(Restaurante restaurante) async {
    await _dbHelper.insertRestaurante(restaurante);
    await loadRestaurantes();
  }

  Future<void> updateRestaurante(Restaurante restaurante) async {
    await _dbHelper.updateRestaurante(restaurante);
    await loadAllData(); // Refresh everything in case override changed
  }

  Future<void> deleteRestaurante(int id) async {
    await _dbHelper.deleteRestaurante(id);
    await loadAllData(); // Cascading delete affects plates
  }

  // CRUD Prato
  Future<void> addPrato(Prato prato) async {
    await _dbHelper.insertPrato(prato);
    await loadAllData(); // New plate might change restaurant metrics
  }

  Future<void> deletePrato(int id) async {
    await _dbHelper.deletePrato(id);
    await loadAllData(); // Removing plate might change restaurant metrics
  }

  Future<void> deleteMultiplePratos(Set<int> ids) async {
    for (var id in ids) {
      await _dbHelper.deletePrato(id);
    }
    await loadAllData();
  }
}
