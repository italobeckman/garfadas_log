import 'package:flutter/material.dart';
import '../models/restaurante.dart';
import '../models/prato.dart';
import '../database/database_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Restaurante> _restaurantes = [];
  List<Prato> _pratos = [];
  bool _isLoading = false;
  String? _errorMessage;

  AppProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        loadAllData();
      } else if (event == AuthChangeEvent.signedOut) {
        _restaurantes = [];
        _pratos = [];
        notifyListeners();
      }
    });
  }

  List<Restaurante> get restaurantes => _restaurantes;
  List<Prato> get pratos => _pratos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        loadRestaurantes(),
        loadPratos(),
      ]);
    } catch (e) {
      _errorMessage = "Erro ao carregar dados: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRestaurantes() async {
    try {
      _restaurantes = await _dbHelper.getAllRestaurantes();
      notifyListeners();
    } catch (e) {
      _errorMessage = "Erro ao carregar restaurantes";
      notifyListeners();
    }
  }

  Future<void> loadPratos() async {
    try {
      _pratos = await _dbHelper.getAllPratosComRestaurante();
      notifyListeners();
    } catch (e) {
      _errorMessage = "Erro ao carregar pratos";
      notifyListeners();
    }
  }

  // CRUD Restaurante
  Future<void> addRestaurante(Restaurante restaurante) async {
    try {
      await _dbHelper.insertRestaurante(restaurante);
      await loadRestaurantes();
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> updateRestaurante(Restaurante restaurante) async {
    try {
      await _dbHelper.updateRestaurante(restaurante);
      await loadAllData(); 
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> deleteRestaurante(int id) async {
    try {
      await _dbHelper.deleteRestaurante(id);
      await loadAllData();
    } catch (e) {
      return Future.error(e);
    }
  }

  // CRUD Prato
  Future<void> addPrato(Prato prato) async {
    try {
      await _dbHelper.insertPrato(prato);
      await loadAllData();
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> deletePrato(int id) async {
    try {
      await _dbHelper.deletePrato(id);
      await loadAllData();
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> deleteMultiplePratos(Set<int> ids) async {
    for (var id in ids) {
      await _dbHelper.deletePrato(id);
    }
    await loadAllData();
  }
}
