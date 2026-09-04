import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/teacher/attendance/models/attendance_models.dart';
import '../../features/teacher/core/teacher_dio_extensions.dart';
import '../network/dio_client.dart';

final attendanceQueueProvider = Provider<AttendanceQueue>((ref) {
  return AttendanceQueue();
});

final attendanceSyncServiceProvider = Provider<AttendanceSyncService>((ref) {
  return AttendanceSyncService(
    ref.watch(dioProvider),
    ref.watch(attendanceQueueProvider),
  );
});

/// Pending PUT /teacher/attendance payload stored while offline.
class AttendanceQueueEntry {
  const AttendanceQueueEntry({
    required this.id,
    required this.standard,
    required this.section,
    required this.date,
    required this.studentId,
    required this.session,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final int standard;
  final String section;
  final String date;
  final String studentId;
  final AttendanceSession session;
  final AttendanceStatus? status;
  final DateTime createdAt;

  Map<String, dynamic> toRequestBody() => {
        'date': date,
        'student_id': studentId,
        'session': session.apiValue,
        'status': status?.apiValue ?? 'absent',
      };
}

class AttendanceQueue {
  static const _dbName = 'attendance_queue.db';
  static const _table = 'pending_attendance';

  Database? _db;

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            standard INTEGER NOT NULL,
            section TEXT NOT NULL,
            date TEXT NOT NULL,
            student_id TEXT NOT NULL,
            session TEXT NOT NULL,
            status TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<int> enqueue({
    required int standard,
    required String section,
    required String date,
    required String studentId,
    required AttendanceSession session,
    required AttendanceStatus? status,
  }) async {
    final db = await _database();
    return db.insert(_table, {
      'standard': standard,
      'section': section,
      'date': date,
      'student_id': studentId,
      'session': session.apiValue,
      'status': status?.apiValue,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<AttendanceQueueEntry>> pending() async {
    final db = await _database();
    final rows = await db.query(_table, orderBy: 'id ASC');
    return rows.map(_rowToEntry).toList();
  }

  Future<int> count() async {
    final db = await _database();
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> remove(int id) async {
    final db = await _database();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await _database();
    await db.delete(_table);
  }

  AttendanceQueueEntry _rowToEntry(Map<String, dynamic> row) {
    return AttendanceQueueEntry(
      id: row['id'] as int,
      standard: row['standard'] as int,
      section: row['section'] as String,
      date: row['date'] as String,
      studentId: row['student_id'] as String,
      session: AttendanceSession.values.firstWhere(
        (s) => s.apiValue == row['session'],
        orElse: () => AttendanceSession.morning,
      ),
      status: attendanceStatusFromApi(row['status'] as String?),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

class AttendanceSyncResult {
  const AttendanceSyncResult({
    required this.synced,
    required this.failed,
    this.lastError,
  });

  final int synced;
  final int failed;
  final String? lastError;

  bool get hasFailures => failed > 0;
}

class AttendanceSyncService {
  AttendanceSyncService(this._dio, this._queue);

  final Dio _dio;
  final AttendanceQueue _queue;

  Future<AttendanceSyncResult> syncPending() async {
    final entries = await _queue.pending();
    var synced = 0;
    var failed = 0;
    String? lastError;

    for (final entry in entries) {
      try {
        await _dio.putJson<Map<String, dynamic>>(
          '/teacher/attendance',
          data: entry.toRequestBody(),
        );
        await _queue.remove(entry.id);
        synced++;
      } catch (e) {
        failed++;
        lastError = e.toString();
        break;
      }
    }

    return AttendanceSyncResult(synced: synced, failed: failed, lastError: lastError);
  }
}

bool isOfflineDioError(Object error) {
  if (error is! DioException) return false;
  return error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.unknown;
}

/// Serializes queue entries for debug logging.
String encodeQueueSnapshot(List<AttendanceQueueEntry> entries) {
  return jsonEncode(entries.map((e) => e.toRequestBody()..['id'] = e.id).toList());
}
