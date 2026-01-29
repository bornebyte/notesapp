import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/note.dart';
import '../models/notification.dart';
import '../models/target_date.dart';
import '../models/api_token.dart';
import '../models/dashboard_models.dart';
import 'storage_service.dart';
import 'cache_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? type;

  ApiException(this.message, {this.statusCode, this.type});

  @override
  String toString() => message;
}

class ApiService {
  final StorageService _storage = StorageService();
  final CacheService _cache = CacheService();
  String? _cachedDomain;
  String? _cachedToken;

  Future<String> get baseUrl async {
    _cachedDomain ??= await _storage.getDomain();
    return _cachedDomain!;
  }

  Future<String> get apiToken async {
    _cachedToken ??= await _storage.getApiToken();
    return _cachedToken!;
  }

  Future<Map<String, String>> get _headers async => {
    'Content-Type': 'application/json',
    'X-API-Token': await apiToken,
  };

  void clearCache() {
    _cachedDomain = null;
    _cachedToken = null;
    _cache.clear();
  }

  void clearDataCache() {
    _cache.clear();
  }

  // Handle API errors
  ApiException _handleError(dynamic error, {int? statusCode}) {
    if (error is SocketException) {
      return ApiException(
        'No internet connection. Please check your network.',
        type: 'network',
      );
    } else if (error is HttpException) {
      return ApiException(
        'Server error. Please try again later.',
        type: 'server',
      );
    } else if (error is FormatException) {
      return ApiException('Invalid response from server.', type: 'format');
    }

    if (statusCode != null) {
      switch (statusCode) {
        case 401:
          return ApiException(
            'Invalid credentials or API token. Please check your settings.',
            statusCode: 401,
            type: 'auth',
          );
        case 403:
          return ApiException(
            'Access forbidden. Please check your API token.',
            statusCode: 403,
            type: 'auth',
          );
        case 404:
          return ApiException(
            'API endpoint not found. Please check your domain settings.',
            statusCode: 404,
            type: 'domain',
          );
        case 500:
        case 502:
        case 503:
          return ApiException(
            'Server error. Please try again later.',
            statusCode: statusCode,
            type: 'server',
          );
        default:
          return ApiException(
            'Request failed with status: $statusCode',
            statusCode: statusCode,
          );
      }
    }

    return ApiException('An unexpected error occurred: $error');
  }

  // Password-based login (password only, no username)
  Future<Map<String, dynamic>> login(String password) async {
    try {
      final domain = await baseUrl;
      final url = '$domain/api/auth/login';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'password': password}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw ApiException('Invalid password.', statusCode: 401, type: 'auth');
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Test connection and token
  Future<bool> testConnection() async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;
      final url = '$domain/api/notes';

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Connection timeout. Please check your domain.',
                type: 'timeout',
              );
            },
          );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get all notes
  Future<List<Note>> getNotes({String? type, bool useCache = true}) async {
    final cacheKey = 'notes_${type ?? 'all'}';

    if (useCache) {
      final cached = _cache.get<List<Note>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final domain = await baseUrl;
      final headers = await _headers;
      String url = '$domain/api/notes';
      if (type != null) {
        url += '?type=$type';
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final notes = data.map((json) => Note.fromJson(json)).toList();
          _cache.set(cacheKey, notes);
          return notes;
        }
        return [];
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Get favorite notes
  Future<List<Note>> getFavoriteNotes() async {
    return getNotes(type: 'favorites');
  }

  // Get trashed notes
  Future<List<Note>> getTrashedNotes() async {
    return getNotes(type: 'trashed');
  }

  // Search notes
  Future<List<Note>> searchNotes(String query) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .get(Uri.parse('$domain/api/notes?query=$query'), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => Note.fromJson(json)).toList();
        }
        return [];
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Create a new note
  Future<Map<String, dynamic>> createNote(Note note) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .post(
            Uri.parse('$domain/api/notes'),
            headers: headers,
            body: json.encode(note.toJson()),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _cache.clearPattern('notes_');
        _cache.remove('dashboard_stats');
        return json.decode(response.body);
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Update a note
  Future<Map<String, dynamic>> updateNote(int id, Note note) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;
      final noteData = note.toJson();
      noteData['id'] = id;

      final response = await http
          .put(
            Uri.parse('$domain/api/notes'),
            headers: headers,
            body: json.encode(noteData),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        _cache.clearPattern('notes_');
        _cache.remove('dashboard_stats');
        return json.decode(response.body);
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Delete a note permanently
  Future<void> deleteNote(int id) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .delete(
            Uri.parse('$domain/api/notes?id=$id&permanent=true'),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleError(null, statusCode: response.statusCode);
      }
      _cache.clearPattern('notes_');
      _cache.remove('dashboard_stats');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Toggle favorite status
  Future<Map<String, dynamic>> toggleFavorite(int id, bool favorite) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .put(
            Uri.parse('$domain/api/notes/favorite'),
            headers: headers,
            body: json.encode({'id': id, 'favorite': favorite}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        _cache.clearPattern('notes_');
        _cache.remove('dashboard_stats');
        return json.decode(response.body);
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Toggle trash status
  Future<Map<String, dynamic>> toggleTrash(int id, bool trash) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .put(
            Uri.parse('$domain/api/notes/trash'),
            headers: headers,
            body: json.encode({'id': id, 'trash': trash}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        _cache.clearPattern('notes_');
        _cache.remove('dashboard_stats');
        return json.decode(response.body);
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Create share ID for note
  Future<String> createNoteShareId(int id) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .post(
            Uri.parse('$domain/api/notes/share'),
            headers: headers,
            body: json.encode({'id': id}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final shareId = data['shareid'];
        if (shareId == null) {
          throw ApiException('Share ID not returned from server');
        }
        _cache.clearPattern('notes_');
        return shareId as String;
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats({bool useCache = true}) async {
    const cacheKey = 'dashboard_stats';

    if (useCache) {
      final cached = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .get(Uri.parse('$domain/api/dashboard/stats'), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        final stats = json.decode(response.body);
        _cache.set(cacheKey, stats);
        return stats;
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Inbox/Notifications methods (backend uses /api/notifications)
  Future<Map<String, dynamic>> getNotifications({bool useCache = true}) async {
    const cacheKey = 'notifications_all';

    if (useCache) {
      final cached = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .get(Uri.parse('$domain/api/notifications'), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // API returns [[notifications]]
        final notificationsList = (data[0] as List)
            .map((json) => Notification.fromJson(json))
            .toList();

        // Generate filters dynamically from notifications
        final categoryMap = <String, String>{};
        for (final notif in notificationsList) {
          if (notif.category != null && notif.label != null) {
            categoryMap[notif.category!] = notif.label!;
          }
        }

        final filtersList = [
          FilterOption(category: '*', label: 'All'),
          ...categoryMap.entries.map(
            (e) => FilterOption(category: e.key, label: e.value),
          ),
        ];

        final result = {
          'notifications': notificationsList,
          'filters': filtersList,
        };

        _cache.set(cacheKey, result);
        return result;
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Targets/Goals methods (backend uses /api/targets)
  Future<List<TargetDate>> getTargetDates({bool useCache = true}) async {
    const cacheKey = 'target_dates';

    if (useCache) {
      final cached = _cache.get<List<TargetDate>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .get(Uri.parse('$domain/api/targets'), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final targets = (data as List)
            .map((json) => TargetDate.fromJson(json))
            .toList();
        _cache.set(cacheKey, targets);
        return targets;
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  Future<void> createTargetDate(TargetDate target) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .post(
            Uri.parse('$domain/api/targets'),
            headers: headers,
            body: json.encode(target.toJson()),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _cache.remove('target_dates');
        // API returns {"success": true, "id": 20}, not the full target
        return;
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  Future<void> updateTargetDate(int id, TargetDate target) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .put(
            Uri.parse('$domain/api/targets?id=$id'),
            headers: headers,
            body: json.encode(target.toJson()),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        _cache.remove('target_dates');
        // API returns success response, not the full target
        return;
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  Future<void> deleteTargetDate(int id) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .delete(Uri.parse('$domain/api/targets?id=$id'), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleError(null, statusCode: response.statusCode);
      }
      _cache.remove('target_dates');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  Future<String> generateShareId(int id) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .post(
            Uri.parse('$domain/api/targets/share'),
            headers: headers,
            body: json.encode({'id': id}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cache.remove('target_dates');
        final shareId = data['shareid'];
        if (shareId == null) {
          throw ApiException('Share ID not returned from server');
        }
        return shareId as String;
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Settings API methods
  Future<void> changePassword(String newPassword) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .put(
            Uri.parse('$domain/api/settings/password'),
            headers: headers,
            body: json.encode({'newPassword': newPassword}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode != 200) {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // API Token management
  Future<List<ApiToken>> getApiTokens() async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .get(Uri.parse('$domain/api/auth/token'), headers: headers)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final tokens = (data['tokens'] as List)
              .map((json) => ApiToken.fromJson(json))
              .toList();
          return tokens;
        }
        return [];
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  Future<String> createApiToken(String name) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .post(
            Uri.parse('$domain/api/auth/token'),
            headers: headers,
            body: json.encode({'name': name}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['token'] as String;
        }
        throw ApiException(data['message'] ?? 'Failed to create token');
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  Future<void> deleteApiToken(int tokenId) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .delete(
            Uri.parse('$domain/api/auth/token?id=$tokenId'),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw ApiException(
                'Request timeout. Please check your connection.',
                type: 'timeout',
              );
            },
          );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw ApiException(data['message'] ?? 'Failed to delete token');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Dashboard productivity data (7 days)
  Future<List<ProductivityData>> getProductivityData({
    bool useCache = true,
  }) async {
    const cacheKey = 'dashboard_productivity';

    if (useCache) {
      final cached = _cache.get<List<ProductivityData>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .get(
            Uri.parse('$domain/api/dashboard/productivity'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final productivity = data
            .map((e) => ProductivityData.fromJson(e))
            .toList();
        _cache.set(cacheKey, productivity);
        return productivity;
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Dashboard activity feed
  Future<List<ActivityItem>> getActivityFeed({bool useCache = true}) async {
    const cacheKey = 'dashboard_activity';

    if (useCache) {
      final cached = _cache.get<List<ActivityItem>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .get(Uri.parse('$domain/api/dashboard/activity'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final activity = data.map((e) => ActivityItem.fromJson(e)).toList();
        _cache.set(cacheKey, activity);
        return activity;
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Notes chart data (monthly)
  Future<List<MonthlyChartData>> getNotesChartData({
    bool useCache = true,
  }) async {
    const cacheKey = 'notes_chart';

    if (useCache) {
      final cached = _cache.get<List<MonthlyChartData>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .get(Uri.parse('$domain/api/notes/chart'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final chartData = data
            .map((e) => MonthlyChartData.fromJson(e))
            .toList();
        _cache.set(cacheKey, chartData);
        return chartData;
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Updated dashboard stats method to return typed data
  Future<DashboardStats> getDashboardStatsTyped({bool useCache = true}) async {
    const cacheKey = 'dashboard_stats_typed';

    if (useCache) {
      final cached = _cache.get<DashboardStats>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .get(Uri.parse('$domain/api/dashboard/stats'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stats = DashboardStats.fromJson(data);
        _cache.set(cacheKey, stats);
        return stats;
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }
}
