import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/position.dart';

class BufferService {
  Database? _db;

  Future<void> init() async {
    if (kIsWeb) return; // sqflite not supported on web
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'position_buffer.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE position_buffer (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            altitude INTEGER NOT NULL,
            speed INTEGER NOT NULL,
            heading REAL NOT NULL,
            accuracy REAL NOT NULL,
            timestamp INTEGER NOT NULL,
            pushed INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> insert(PilotPosition pos) async {
    await _db?.insert('position_buffer', {
      'lat': pos.lat,
      'lon': pos.lon,
      'altitude': pos.altitude,
      'speed': pos.speed,
      'heading': pos.heading,
      'accuracy': pos.accuracy,
      'timestamp': pos.timestamp,
      'pushed': 0,
    });

    // Cap at 10,000 unpushed rows.
    final count = (await _db?.rawQuery(
            'SELECT COUNT(*) as c FROM position_buffer WHERE pushed = 0'))
        ?.first['c'] as int? ?? 0;
    if (count > 10000) {
      await _db?.execute('''
        DELETE FROM position_buffer WHERE id IN (
          SELECT id FROM position_buffer WHERE pushed = 0
          ORDER BY timestamp ASC LIMIT ${count - 10000}
        )
      ''');
    }
  }

  Future<List<PilotPosition>> getUnpushed({int limit = 500}) async {
    final rows = await _db?.query(
      'position_buffer',
      where: 'pushed = 0',
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    if (rows == null) return [];
    return rows
        .map((r) => PilotPosition(
              lat: r['lat'] as double,
              lon: r['lon'] as double,
              altitude: r['altitude'] as int,
              speed: r['speed'] as int,
              heading: r['heading'] as double,
              accuracy: r['accuracy'] as double,
              timestamp: r['timestamp'] as int,
            ))
        .toList();
  }

  Future<void> markPushed(List<PilotPosition> positions) async {
    if (positions.isEmpty) return;
    final timestamps = positions.map((p) => p.timestamp).toList();
    final placeholders = timestamps.map((_) => '?').join(',');
    await _db?.execute(
      'UPDATE position_buffer SET pushed = 1 WHERE timestamp IN ($placeholders)',
      timestamps,
    );
  }

  Future<int> unpushedCount() async {
    final result = await _db?.rawQuery(
        'SELECT COUNT(*) as c FROM position_buffer WHERE pushed = 0');
    return result?.first['c'] as int? ?? 0;
  }

  Future<void> cleanup() async {
    // Delete pushed positions older than 1 hour.
    final cutoff =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600;
    await _db?.execute(
      'DELETE FROM position_buffer WHERE pushed = 1 AND timestamp < ?',
      [cutoff],
    );
  }

  Future<void> clearAll() async {
    await _db?.execute('DELETE FROM position_buffer');
  }

  Future<void> close() async {
    await _db?.close();
  }
}
