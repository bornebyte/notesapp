import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note.dart';

class ApiService {
  static const String baseUrl = 'https://notes.shubham-shah.com.np';
  static const String apiToken =
      '0a8b8ed7914bb429b1109383e5e370d77a589b9062d07da8770c5def53fb06cc';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-API-Token': apiToken,
  };

  // Get all notes
  Future<List<Note>> getNotes({String? type}) async {
    try {
      String url = '$baseUrl/api/notes';
      if (type != null) {
        url += '?type=$type';
      }

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => Note.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load notes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notes: $e');
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
      final response = await http.get(
        Uri.parse('$baseUrl/api/notes?query=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => Note.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to search notes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching notes: $e');
    }
  }

  // Create a new note
  Future<Map<String, dynamic>> createNote(Note note) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notes'),
        headers: _headers,
        body: json.encode(note.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create note');
      }
    } catch (e) {
      throw Exception('Error creating note: $e');
    }
  }

  // Update a note
  Future<Map<String, dynamic>> updateNote(int id, Note note) async {
    try {
      final noteData = note.toJson();
      noteData['id'] = id;

      final response = await http.put(
        Uri.parse('$baseUrl/api/notes'),
        headers: _headers,
        body: json.encode(noteData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update note');
      }
    } catch (e) {
      throw Exception('Error updating note: $e');
    }
  }

  // Delete a note permanently
  Future<void> deleteNote(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notes?id=$id&permanent=true'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete note: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting note: $e');
    }
  }

  // Toggle favorite status
  Future<Map<String, dynamic>> toggleFavorite(int id, bool favorite) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notes/favorite'),
        headers: _headers,
        body: json.encode({'id': id, 'favorite': favorite}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to toggle favorite: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error toggling favorite: $e');
    }
  }

  // Toggle trash status
  Future<Map<String, dynamic>> toggleTrash(int id, bool trash) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/notes/trash'),
        headers: _headers,
        body: json.encode({'id': id, 'trash': trash}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to toggle trash: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error toggling trash: $e');
    }
  }

  // Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard/stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }

  // Get notifications
  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data;
        }
        return [];
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }
}
