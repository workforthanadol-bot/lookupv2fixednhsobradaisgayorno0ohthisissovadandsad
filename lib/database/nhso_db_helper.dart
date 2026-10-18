import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

class NhsoDbHelper {
  static Database? _db;
  static String? _foundPath;
  static String? get foundPath => _foundPath;

  static const _searchPaths = [
    '/storage/emulated/0/Download/nhso_data.db',
    '/storage/emulated/0/nhso_data.db',
    '/sdcard/Download/nhso_data.db',
    '/sdcard/nhso_data.db',
    '/storage/emulated/0/Documents/nhso_data.db',
  ];

  static const _csvFields = [
    'title', 'first_name', 'last_name', 'citizen_id', 'gender',
    'nationality', 'status', 'birth_day', 'birth_month', 'birth_year_bs',
    'birth_year_ad', 'age_text', 'prefix_title',
    'address_house_no', 'address_moo', 'address_village',
    'address_tambon', 'address_amphoe', 'address_province', 'address_full',
    'dopa_main_right', 'dopa_sub_right', 'dopa_hospital_code', 'dopa_hospital_name',
  ];

  static Future<Database?> get database async {
    if (_db != null) return _db;
    _db = await _init();
    return _db;
  }

  static Future<Database?> _init() async {
    // Request storage permission
    await _requestPermission();

    for (final path in _searchPaths) {
      try {
        if (File(path).existsSync()) {
          final db = await openDatabase(path, readOnly: true);
          _foundPath = path;
          return db;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static Future<void> _requestPermission() async {
    try {
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      // Fallback for older Android
      final status2 = await Permission.storage.status;
      if (!status2.isGranted) {
        await Permission.storage.request();
      }
    } catch (_) {}
  }

  static void reset() {
    _db?.close();
    _db = null;
    _foundPath = null;
  }

  static Future<bool> isAvailable() async {
    try {
      final db = await database;
      if (db == null) return false;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> search({
    String? name,
    String? citizenId,
    int limit = 50,
  }) async {
    final db = await database;
    if (db == null) return [];

    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name LIMIT 10");
    if (tables.isEmpty) return [];

    String? tableName;
    bool useRaw = false;
    for (final t in tables) {
      final n = t['name'] as String;
      if (n == 'sqlite_sequence') continue;
      final cols = await db.rawQuery('PRAGMA table_info($n)');
      final colNames = cols.map((c) => c['name'] as String).toSet();
      if (colNames.contains('raw_content')) {
        tableName = n; useRaw = true; break;
      }
      if (colNames.contains('first_name') || colNames.contains('citizen_id')) {
        tableName = n; useRaw = false; break;
      }
    }
    if (tableName == null) return [];

    List<Map<String, dynamic>> rows;
    if (useRaw) {
      final pattern = citizenId ?? '%${name ?? ''}%';
      rows = await db.rawQuery(
          'SELECT raw_content FROM $tableName WHERE raw_content LIKE ? LIMIT $limit',
          [pattern]);
      return rows.map((r) => _parseRaw(r['raw_content'] as String? ?? '')).toList();
    } else {
      if (citizenId != null) {
        rows = await db.rawQuery(
            'SELECT * FROM $tableName WHERE citizen_id = ? LIMIT $limit',
            [citizenId]);
      } else {
        final pattern = '%${name ?? ''}%';
        rows = await db.rawQuery(
            'SELECT * FROM $tableName WHERE first_name LIKE ? OR last_name LIKE ? LIMIT $limit',
            [pattern, pattern]);
      }
      return rows.map(_mapRow).toList();
    }
  }

  static Map<String, dynamic> _parseRaw(String raw) {
    final parts = raw.split(',').map((p) => p.trim()).toList();
    final map = <String, dynamic>{};
    for (int i = 0; i < _csvFields.length; i++) {
      map[_csvFields[i]] = i < parts.length ? parts[i] : '';
    }
    return map;
  }

  static Map<String, dynamic> _mapRow(Map<String, dynamic> row) {
    final map = <String, dynamic>{};
    for (final f in _csvFields) {
      map[f] = row[f]?.toString() ?? '';
    }
    return map;
  }

  static Map<String, dynamic> buildOutput(Map<String, dynamic> data) {
    String get(String k) => data[k]?.toString() ?? '';
    final title = get('title');
    final first = get('first_name');
    final last = get('last_name');
    final fullName = '$title$first $last'.trim();
    String gender = get('gender');
    if (gender == 'ชาย') gender = 'ชาย ♂';
    if (gender == 'หญิง') gender = 'หญิง ♀';
    final hospCode = get('dopa_hospital_code');
    final hospName = get('dopa_hospital_name');
    final hospDisplay = hospCode.isNotEmpty && hospName.isNotEmpty
        ? '$hospName ($hospCode)'
        : hospCode.isNotEmpty ? hospCode : hospName;
    String addr = get('address_full');
    if (addr.isEmpty) {
      final parts = <String>[];
      if (get('address_house_no').isNotEmpty) parts.add('บ้านเลขที่ ${get("address_house_no")}');
      if (get('address_moo').isNotEmpty) parts.add('หมู่ ${get("address_moo")}');
      if (get('address_village').isNotEmpty) parts.add('หมู่บ้าน ${get("address_village")}');
      if (get('address_tambon').isNotEmpty) parts.add('ตำบล ${get("address_tambon")}');
      if (get('address_amphoe').isNotEmpty) parts.add('อำเภอ ${get("address_amphoe")}');
      if (get('address_province').isNotEmpty) parts.add('จังหวัด ${get("address_province")}');
      addr = parts.join(' ');
    }
    return {
      'ส่วนที่ ๑: ข้อมูลพื้นฐานบุคคล': {
        'ชื่อ-นามสกุล': fullName,
        'เลขประจำตัวประชาชน': get('citizen_id'),
        'ชื่อจริง': first,
        'นามสกุล': last,
        'เพศ': gender,
        'สัญชาติ': get('nationality'),
        'สถานะ': get('status'),
      },
      'ส่วนที่ ๒: ข้อมูลการเกิด': {
        'วันเกิด': get('birth_day'),
        'เดือนเกิด': get('birth_month'),
        'ปีเกิด (พ.ศ.)': get('birth_year_bs'),
        'ปีเกิด (ค.ศ.)': get('birth_year_ad'),
        'อายุ': get('age_text'),
        'ตำรับหน้า': get('prefix_title'),
      },
      'ส่วนที่ ๓: ที่อยู่ตามทะเบียนบ้าน': {
        'บ้านเลขที่': get('address_house_no'),
        'หมู่ที่': get('address_moo'),
        'หมู่บ้าน': get('address_village'),
        'ตำบล': get('address_tambon'),
        'อำเภอ': get('address_amphoe'),
        'จังหวัด': get('address_province'),
        'ที่อยู่เต็ม': addr,
      },
      'ส่วนที่ ๔: DOPA / สปสช': {
        'สิทธิหลัก': get('dopa_main_right'),
        'สิทธิย่อย': get('dopa_sub_right'),
        'รพ.หลัก': hospDisplay,
      },
    };
  }
}
