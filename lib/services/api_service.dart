import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/note.dart';
import 'storage_service.dart';

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

  // Password-based login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final domain = await baseUrl;
      final url = '$domain/api/auth';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'username': username, 'password': password}),
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
        throw ApiException(
          'Invalid username or password.',
          statusCode: 401,
          type: 'auth',
        );
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
  Future<List<Note>> getNotes({String? type}) async {
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
  Future<Map<String, dynamic>> getDashboardStats() async {
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
        return json.decode(response.body);
      } else {
        throw _handleError(null, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _handleError(e);
    }
  }

  // Get notifications
  Future<List<dynamic>> getNotifications() async {
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
        if (data is List) {
          return data;
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
}
