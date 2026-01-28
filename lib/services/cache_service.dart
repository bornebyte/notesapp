class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  CacheEntry(this.data, this.timestamp);

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }
}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry> _cache = {};

  void set<T>(
    String key,
    T data, {
    Duration maxAge = const Duration(minutes: 5),
  }) {
    _cache[key] = CacheEntry(data, DateTime.now());
  }

  T? get<T>(String key, {Duration maxAge = const Duration(minutes: 5)}) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired(maxAge)) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  void clearPattern(String pattern) {
    _cache.removeWhere((key, value) => key.contains(pattern));
  }
}
