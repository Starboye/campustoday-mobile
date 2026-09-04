import 'dart:convert';

/// Simple read-through cache for student homework, timetable, and fees payloads.
class StudentReadCache {
  StudentReadCache._();

  static final StudentReadCache instance = StudentReadCache._();

  final Map<String, _CacheEntry> _store = {};

  static const ttl = Duration(hours: 24);

  String? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.storedAt) > ttl) {
      _store.remove(key);
      return null;
    }
    return entry.payload;
  }

  void put(String key, Map<String, dynamic> data) {
    _store[key] = _CacheEntry(
      payload: jsonEncode(data),
      storedAt: DateTime.now(),
    );
  }

  Map<String, dynamic>? getJson(String key) {
    final raw = get(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  void invalidatePrefix(String prefix) {
    _store.removeWhere((key, _) => key.startsWith(prefix));
  }
}

class _CacheEntry {
  const _CacheEntry({required this.payload, required this.storedAt});

  final String payload;
  final DateTime storedAt;
}
