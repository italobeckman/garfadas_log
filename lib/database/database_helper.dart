import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/restaurante.dart';
import '../models/prato.dart';

class DatabaseHelper {
  // Construtor Singleton para garantir uma única instância do banco de dados
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'garfadas_log.db');
    return await openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Criação das tabelas
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE restaurantes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        overrideVoltaria INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE pratos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        restauranteId INTEGER NOT NULL,
        descricaoPrato TEXT NOT NULL,
        data TEXT NOT NULL,
        notaComida REAL NOT NULL,
        notaCustoBeneficio REAL NOT NULL,
        voltaria INTEGER NOT NULL,
        observacoes TEXT,
        imagePath TEXT,
        FOREIGN KEY (restauranteId) REFERENCES restaurantes (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS refeicoes');
      await db.execute('DROP TABLE IF EXISTS pratos');
      await db.execute('DROP TABLE IF EXISTS restaurantes');
      await _onCreate(db, newVersion);
    } 
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE pratos ADD COLUMN imagePath TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE restaurantes ADD COLUMN overrideVoltaria INTEGER');
    }
  }

  // --- MÉTODOS PARA RESTAURANTES ---

  Future<int> insertRestaurante(Restaurante r) async {
    final db = await database;
    return await db.insert('restaurantes', r.toMap());
  }

  Future<List<Restaurante>> getAllRestaurantes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('restaurantes');

    List<Restaurante> restaurantes = [];
    for (var map in maps) {
      Restaurante rest = Restaurante.fromMap(map);
      await _carregarMetricasRestaurante(db, rest);
      restaurantes.add(rest);
    }
    return restaurantes;
  }

  Future<List<Restaurante>> getRestaurantesByClassificacao(
    bool voltaria,
  ) async {
    List<Restaurante> tds = await getAllRestaurantes();
    return tds.where((r) => r.voltaria == voltaria).toList();
  }

  Future<void> _carregarMetricasRestaurante(
    Database db,
    Restaurante rest,
  ) async {
    var result = await db.rawQuery(
      '''
      SELECT 
        COUNT(id) as totalPratos, 
        AVG((notaComida * 0.6) + (notaCustoBeneficio * 0.4)) as mediaGeral
      FROM pratos 
      WHERE restauranteId = ?
    ''',
      [rest.id],
    );

    if (result.isNotEmpty && result.first['totalPratos'] != 0) {
      rest.totalPratos = result.first['totalPratos'] as int;
      rest.notaGeral = result.first['mediaGeral'] as double;
      
      // Busca o nome do último prato
      var lastPlateResult = await db.query(
        'pratos',
        columns: ['descricaoPrato'],
        where: 'restauranteId = ?',
        whereArgs: [rest.id],
        orderBy: 'id DESC',
        limit: 1,
      );
      if (lastPlateResult.isNotEmpty) {
        rest.ultimoPrato = lastPlateResult.first['descricaoPrato'] as String;
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
    final db = await database;
    return await db.update(
      'restaurantes',
      r.toMap(),
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  Future<int> deleteRestaurante(int id) async {
    final db = await database;
    return await db.delete('restaurantes', where: 'id = ?', whereArgs: [id]);
  }

  // --- MÉTODOS PARA PRATOS ---

  Future<int> insertPrato(Prato p) async {
    final db = await database;
    return await db.insert('pratos', p.toMap());
  }

  Future<List<Prato>> getAllPratosComRestaurante() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.*, r.nome as nomeLocal 
      FROM pratos p
      INNER JOIN restaurantes r ON p.restauranteId = r.id
    ''');
    return List.generate(maps.length, (i) => Prato.fromMap(maps[i]));
  }

  Future<List<Prato>> getPratosByRestaurante(int restauranteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pratos',
      where: 'restauranteId = ?',
      whereArgs: [restauranteId],
    );
    return List.generate(maps.length, (i) => Prato.fromMap(maps[i]));
  }

  Future<int> updatePrato(Prato p) async {
    final db = await database;
    return await db.update(
      'pratos',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<int> deletePrato(int id) async {
    final db = await database;
    return await db.delete('pratos', where: 'id = ?', whereArgs: [id]);
  }
}
