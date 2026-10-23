import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('open_moi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWebNoWebWorker;
      return await openDatabase(
        filePath,
        version: 1,
        onCreate: _createDB,
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE measurement_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        mass REAL NOT NULL DEFAULT 0.0,
        massUnit TEXT NOT NULL DEFAULT 'oz',
        length REAL NOT NULL DEFAULT 0.0,
        lengthUnit TEXT NOT NULL DEFAULT 'in',
        width REAL NOT NULL DEFAULT 0.0,
        widthUnit TEXT NOT NULL DEFAULT 'in',
        groupType TEXT NOT NULL DEFAULT 'Pickleball Paddle'
      )
    ''');

    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        groupId INTEGER,
        type TEXT NOT NULL,
        period REAL NOT NULL,
        moi REAL NOT NULL,
        tareMode TEXT NOT NULL DEFAULT 'None',
        rawData TEXT NOT NULL DEFAULT '',
        cyclePeriods TEXT NOT NULL DEFAULT '',
        totalDuration REAL NOT NULL DEFAULT 0.0,
        fitResidual REAL NOT NULL DEFAULT 0.0,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (groupId) REFERENCES measurement_groups (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX index_measurements_groupId ON measurements (groupId)');

    await db.execute('''
      CREATE TABLE estimation_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT NOT NULL,
        mass REAL NOT NULL DEFAULT 0.0,
        massUnit TEXT NOT NULL DEFAULT 'oz',
        length REAL NOT NULL DEFAULT 0.0,
        lengthUnit TEXT NOT NULL DEFAULT 'in',
        width REAL NOT NULL DEFAULT 0.0,
        widthUnit TEXT NOT NULL DEFAULT 'in',
        balancePoint REAL NOT NULL DEFAULT 0.0,
        bpUnit TEXT NOT NULL DEFAULT 'in',
        radius REAL NOT NULL DEFAULT 0.0,
        radiusUnit TEXT NOT NULL DEFAULT 'cm',
        type TEXT NOT NULL DEFAULT 'Pickleball Paddle',
        resultSW REAL NOT NULL DEFAULT 0.0,
        resultTW REAL NOT NULL DEFAULT 0.0,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  // --- Measurements ---

  Future<List<Measurement>> getMeasurementsByType(String type) async {
    final db = await database;
    final maps = await db.query(
      'measurements',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => Measurement.fromMap(map)).toList();
  }

  Future<List<Measurement>> getMeasurementsByGroup(int groupId) async {
    final db = await database;
    final maps = await db.query(
      'measurements',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => Measurement.fromMap(map)).toList();
  }

  Future<int> insertMeasurement(Measurement measurement) async {
    final db = await database;
    return await db.insert('measurements', measurement.toMap());
  }

  Future<void> insertMeasurementsBatch(List<Measurement> measurements) async {
    if (measurements.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final m in measurements) {
        batch.insert('measurements', m.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<int> deleteMeasurement(int id) async {
    final db = await database;
    return await db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMeasurementsByGroup(int groupId) async {
    final db = await database;
    return await db.delete('measurements', where: 'groupId = ?', whereArgs: [groupId]);
  }

  Future<int> deleteMeasurementsByIds(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      'measurements',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<int> deleteMeasurementsByType(String type) async {
    final db = await database;
    return await db.delete('measurements', where: 'type = ?', whereArgs: [type]);
  }

  // --- Groups ---

  Future<List<MeasurementGroup>> getAllGroups() async {
    final db = await database;
    final maps = await db.query('measurement_groups', orderBy: 'timestamp DESC');
    return maps.map((map) => MeasurementGroup.fromMap(map)).toList();
  }

  Future<List<MeasurementGroup>> searchGroups(String query) async {
    final db = await database;
    final maps = await db.query(
      'measurement_groups',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => MeasurementGroup.fromMap(map)).toList();
  }

  Future<MeasurementGroup?> getGroupById(int id) async {
    final db = await database;
    final maps = await db.query(
      'measurement_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return MeasurementGroup.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertGroup(MeasurementGroup group) async {
    final db = await database;
    return await db.insert('measurement_groups', group.toMap());
  }

  Future<int> updateGroup(MeasurementGroup group) async {
    final db = await database;
    return await db.update(
      'measurement_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(int id) async {
    final db = await database;
    return await db.delete('measurement_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteGroupsByIds(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      'measurement_groups',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<int> getGroupCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM measurement_groups');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- Estimations ---

  Future<List<EstimationGroup>> getAllEstimationGroups() async {
    final db = await database;
    final maps = await db.query('estimation_groups', orderBy: 'timestamp ASC');
    return maps.map((map) => EstimationGroup.fromMap(map)).toList();
  }

  Future<List<EstimationGroup>> searchEstimationGroups(String query) async {
    final db = await database;
    final maps = await db.query(
      'estimation_groups',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => EstimationGroup.fromMap(map)).toList();
  }

  Future<EstimationGroup?> getEstimationGroupById(int id) async {
    final db = await database;
    final maps = await db.query(
      'estimation_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return EstimationGroup.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertEstimationGroup(EstimationGroup group) async {
    final db = await database;
    return await db.insert('estimation_groups', group.toMap());
  }

  Future<void> insertEstimationGroupsBatch(List<EstimationGroup> groups) async {
    if (groups.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final g in groups) {
        batch.insert('estimation_groups', g.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<int> updateEstimationGroup(EstimationGroup group) async {
    final db = await database;
    return await db.update(
      'estimation_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteEstimationGroup(int id) async {
    final db = await database;
    return await db.delete('estimation_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEstimationGroupsByIds(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      'estimation_groups',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<int> getEstimationGroupsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM estimation_groups');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
