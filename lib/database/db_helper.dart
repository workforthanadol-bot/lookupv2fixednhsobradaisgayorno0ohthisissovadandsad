import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/candidate.dart';

class DbHelper {
  static DbHelper? _instance;
  static Database? _database;

  DbHelper._internal();

  static DbHelper get instance {
    _instance ??= DbHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'data.db');

    // Copy from assets only if not already present
    if (!File(dbPath).existsSync()) {
      final data = await rootBundle.load('assets/data.db');
      final bytes = data.buffer.asUint8List();
      await File(dbPath).writeAsBytes(bytes, flush: true);
    }

    return openDatabase(dbPath, readOnly: true);
  }

  /// Returns distinct non-empty values for a given column (for dropdown filters)
  Future<List<String>> getDistinctValues(String column) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT $column FROM candidates WHERE $column IS NOT NULL AND $column != \'-\' ORDER BY $column',
    );
    return result.map((r) => r[column]?.toString() ?? '').where((v) => v.isNotEmpty).toList();
  }

  /// Search candidates with optional filters.
  /// [query] matches exam_id, full_name, or masked_id (LIKE).
  /// [region], [province], [status] are exact match filters (empty = all).
  Future<List<Candidate>> search({
    String query = '',
    String region = '',
    String province = '',
    String status = '',
    int limit = 500,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final params = <dynamic>[];

    if (query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      conditions.add(
        '(exam_id LIKE ? OR full_name LIKE ? OR masked_id LIKE ? OR first_name LIKE ? OR last_name LIKE ?)',
      );
      params.addAll([q, q, q, q, q]);
    }
    if (region.isNotEmpty) {
      conditions.add('region = ?');
      params.add(region);
    }
    if (province.isNotEmpty) {
      conditions.add('province = ?');
      params.add(province);
    }
    if (status.isNotEmpty) {
      conditions.add('status = ?');
      params.add(status);
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    params.add(limit);

    final rows = await db.rawQuery(
      'SELECT * FROM candidates $where ORDER BY order_no ASC LIMIT ?',
      params,
    );
    return rows.map(Candidate.fromMap).toList();
  }

  Future<Candidate?> getById(int id) async {
    final db = await database;
    final rows = await db.query('candidates', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Candidate.fromMap(rows.first);
  }
}
