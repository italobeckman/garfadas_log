import 'dart:io';
import 'package:flutter/material.dart';
import '../models/restaurante.dart';
import '../models/prato.dart';
import '../services/restaurante_service.dart';
import '../services/prato_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppProvider extends ChangeNotifier {
  final RestauranteService _restauranteService;
  final PratoService _pratoService;

  List<Restaurante> _restaurantes = [];
  List<Prato> _pratos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Estado dos Filtros — Restaurantes ───────────────────────────────────
  String _searchRestaurante = '';
  String? _tipoFilter;
  bool? _voltariaRestauranteFilter; // null = todos
  double _notaMinimaRestaurante = 0.0;

  // ─── Estado dos Filtros — Pratos ─────────────────────────────────────────
  String _searchPrato = '';
  int? _restauranteIdFilter;
  bool? _voltariaPratoFilter; // null = todos
  double _notaMinimaPrato = 0.0;

  AppProvider({
    required RestauranteService restauranteService,
    required PratoService pratoService,
  })  : _restauranteService = restauranteService,
        _pratoService = pratoService {
    _initAuthListener();
  }

  void _initAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        loadAllData();
      } else if (event == AuthChangeEvent.signedOut) {
        _restaurantes = [];
        _pratos = [];
        _limparEstadoFiltros();
        notifyListeners();
      }
    });
  }

  // ─── Getters base ─────────────────────────────────────────────────────────
  List<Restaurante> get restaurantes => _restaurantes;
  List<Prato> get pratos => _pratos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Getters de filtros — Restaurantes ───────────────────────────────────
  String get searchRestaurante => _searchRestaurante;
  String? get tipoFilter => _tipoFilter;
  bool? get voltariaRestauranteFilter => _voltariaRestauranteFilter;
  double get notaMinimaRestaurante => _notaMinimaRestaurante;

  // ─── Getters de filtros — Pratos ─────────────────────────────────────────
  String get searchPrato => _searchPrato;
  int? get restauranteIdFilter => _restauranteIdFilter;
  bool? get voltariaPratoFilter => _voltariaPratoFilter;
  double get notaMinimaPrato => _notaMinimaPrato;

  // ─── Lista de tipos únicos para o filtro ─────────────────────────────────
  List<String> get tiposDeRestaurante {
    final tipos = _restaurantes.map((r) => r.tipo).toSet().toList();
    tipos.sort();
    return tipos;
  }

  // ─── Getters filtrados ────────────────────────────────────────────────────
  List<Restaurante> get restaurantesFiltrados {
    return _restaurantes.where((r) {
      // Busca por nome
      if (_searchRestaurante.isNotEmpty &&
          !r.nome.toLowerCase().contains(_searchRestaurante.toLowerCase())) {
        return false;
      }
      // Tipo
      if (_tipoFilter != null && r.tipo != _tipoFilter) return false;
      // Voltaria
      if (_voltariaRestauranteFilter != null &&
          r.voltaria != _voltariaRestauranteFilter) {
        return false;
      }
      // Nota mínima (apenas para restaurantes que têm nota)
      if (_notaMinimaRestaurante > 0.0) {
        if (r.notaGeral == null || r.notaGeral! < _notaMinimaRestaurante) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<Prato> get pratosFiltrados {
    return _pratos.where((p) {
      // Busca por descrição
      if (_searchPrato.isNotEmpty &&
          !p.descricaoPrato.toLowerCase().contains(_searchPrato.toLowerCase())) {
        return false;
      }
      // Restaurante específico
      if (_restauranteIdFilter != null &&
          p.restauranteId != _restauranteIdFilter) {
        return false;
      }
      // Voltaria
      if (_voltariaPratoFilter != null && p.voltaria != _voltariaPratoFilter) {
        return false;
      }
      // Nota mínima
      if (_notaMinimaPrato > 0.0 && p.mediaAvaliacao < _notaMinimaPrato) {
        return false;
      }
      return true;
    }).toList();
  }

  // ─── Flags de filtros ativos ──────────────────────────────────────────────
  bool get filtrosRestauranteAtivos =>
      _searchRestaurante.isNotEmpty ||
      _tipoFilter != null ||
      _voltariaRestauranteFilter != null ||
      _notaMinimaRestaurante > 0.0;

  bool get filtrosPratoAtivos =>
      _searchPrato.isNotEmpty ||
      _restauranteIdFilter != null ||
      _voltariaPratoFilter != null ||
      _notaMinimaPrato > 0.0;

  // ─── Métodos para aplicar/limpar filtros ─────────────────────────────────
  void setFiltrosRestaurante({
    String? search,
    String? tipo,
    bool? voltaria,
    double? notaMinima,
    bool clearTipo = false,
    bool clearVoltaria = false,
    bool clearNota = false,
  }) {
    if (search != null) _searchRestaurante = search;
    if (clearTipo) {
      _tipoFilter = null;
    } else if (tipo != null) {
      _tipoFilter = tipo;
    }
    if (clearVoltaria) {
      _voltariaRestauranteFilter = null;
    } else if (voltaria != null) {
      _voltariaRestauranteFilter = voltaria;
    }
    if (clearNota) {
      _notaMinimaRestaurante = 0.0;
    } else if (notaMinima != null) {
      _notaMinimaRestaurante = notaMinima;
    }
    notifyListeners();
  }

  void limparFiltrosRestaurante() {
    _searchRestaurante = '';
    _tipoFilter = null;
    _voltariaRestauranteFilter = null;
    _notaMinimaRestaurante = 0.0;
    notifyListeners();
  }

  void setFiltrosPrato({
    String? search,
    int? restauranteId,
    bool? voltaria,
    double? notaMinima,
    bool clearRestaurante = false,
    bool clearVoltaria = false,
    bool clearNota = false,
  }) {
    if (search != null) _searchPrato = search;
    if (clearRestaurante) {
      _restauranteIdFilter = null;
    } else if (restauranteId != null) {
      _restauranteIdFilter = restauranteId;
    }
    if (clearVoltaria) {
      _voltariaPratoFilter = null;
    } else if (voltaria != null) {
      _voltariaPratoFilter = voltaria;
    }
    if (clearNota) {
      _notaMinimaPrato = 0.0;
    } else if (notaMinima != null) {
      _notaMinimaPrato = notaMinima;
    }
    notifyListeners();
  }

  void limparFiltrosPrato() {
    _searchPrato = '';
    _restauranteIdFilter = null;
    _voltariaPratoFilter = null;
    _notaMinimaPrato = 0.0;
    notifyListeners();
  }

  void _limparEstadoFiltros() {
    _searchRestaurante = '';
    _tipoFilter = null;
    _voltariaRestauranteFilter = null;
    _notaMinimaRestaurante = 0.0;
    _searchPrato = '';
    _restauranteIdFilter = null;
    _voltariaPratoFilter = null;
    _notaMinimaPrato = 0.0;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Carregamento de dados ────────────────────────────────────────────────
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
      _restaurantes = await _restauranteService.getRestaurantes();
      notifyListeners();
    } catch (e) {
      _errorMessage = "Erro ao carregar restaurantes";
      notifyListeners();
    }
  }

  Future<void> loadPratos() async {
    try {
      _pratos = await _pratoService.getAllPratosComRestaurante();
      notifyListeners();
    } catch (e) {
      _errorMessage = "Erro ao carregar pratos";
      notifyListeners();
    }
  }

  // ─── CRUD Restaurante ─────────────────────────────────────────────────────
  Future<void> addRestaurante(Restaurante restaurante) async {
    try {
      await _restauranteService.insertRestaurante(restaurante);
      await loadRestaurantes();
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> updateRestaurante(Restaurante restaurante) async {
    try {
      await _restauranteService.updateRestaurante(restaurante);
      await loadAllData();
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> deleteRestaurante(int id) async {
    try {
      await _restauranteService.deleteRestaurante(id);
      await loadAllData();
    } catch (e) {
      return Future.error(e);
    }
  }

  // ─── CRUD Prato ───────────────────────────────────────────────────────────
  Future<void> addPrato(Prato prato) async {
    try {
      await _pratoService.insertPrato(prato);
      await loadAllData();
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> updatePrato(Prato prato) async {
    try {
      await _pratoService.updatePrato(prato);
      await loadAllData();
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> deletePrato(int id) async {
    try {
      await _pratoService.deletePrato(id);
      await loadAllData();
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> deleteMultiplePratos(Set<int> ids) async {
    for (var id in ids) {
      await _pratoService.deletePrato(id);
    }
    await loadAllData();
  }

  Future<String?> uploadPratoImage(File image) async {
    return await _pratoService.uploadImage(image);
  }
}
