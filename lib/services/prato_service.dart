import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/prato.dart';
import '../database/database_helper.dart';

class PratoService {
  final DatabaseHelper _dbHelper;

  PratoService(this._dbHelper);

  Future<int> insertPrato(Prato p) async {
    return await _dbHelper.insertPrato(p);
  }

  Future<List<Prato>> getAllPratosComRestaurante() async {
    return await _dbHelper.getAllPratosComRestaurante();
  }

  Future<List<Prato>> getPratosByRestaurante(int restauranteId) async {
    return await _dbHelper.getPratosByRestaurante(restauranteId);
  }

  Future<int> updatePrato(Prato p) async {
    return await _dbHelper.updatePrato(p);
  }

  Future<int> deletePrato(int id) async {
    return await _dbHelper.deletePrato(id);
  }

  Future<String?> uploadImage(File image) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final imageBytes = await image.readAsBytes();
      return await _dbHelper.uploadPratoImage(fileName, imageBytes);
    } catch (e) {
      return null;
    }
  }
}
