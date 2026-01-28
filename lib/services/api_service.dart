import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/note.dart';
import '../models/notification.dart';
import '../models/target_date.dart';
import '../models/api_token.dart';
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
  Future<Map<String, dynamic>> getNotifications({
    String filter = '*',
    bool useCache = true,
  }) async {
    final cacheKey = 'notifications_$filter';

    if (useCache) {
      final cached = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .get(
            Uri.parse(
              '$domain/api/notifications?filter=${Uri.encodeComponent(filter)}',
            ),
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // API returns [notifications, filters]
        final result = {
          'notifications': (data[0] as List)
              .map((json) => Notification.fromJson(json))
              .toList(),
          'filters': (data[1] as List)
              .map((json) => FilterOption.fromJson(json))
              .toList(),
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

  // Targets/Goals methods (backend uses /api/targetdate)
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
          .get(Uri.parse('$domain/api/targetdate'), headers: headers)
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

  Future<TargetDate> createTargetDate(TargetDate target) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .post(
            Uri.parse('$domain/api/targetdate'),
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
        return TargetDate.fromJson(json.decode(response.body));
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  Future<TargetDate> updateTargetDate(int id, TargetDate target) async {
    try {
      final domain = await baseUrl;
      final headers = await _headers;

      final response = await http
          .put(
            Uri.parse('$domain/api/targetdate/$id'),
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
        return TargetDate.fromJson(json.decode(response.body));
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
          .delete(Uri.parse('$domain/api/targetdate/$id'), headers: headers)
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
}
