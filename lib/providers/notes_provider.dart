import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum SortOrder {
  updatedDesc,
  updatedAsc,
  createdDesc,
  createdAsc,
  titleAsc,
  titleDesc,
}

class NotesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  SortOrder _sortOrder = SortOrder.updatedDesc;
  String _viewMode = 'grid';
  String? _selectedCategory;

  List<Note> get notes => _filteredNotes;
  List<Note> get allNotes => _notes; // Access to all notes including trashed
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  SortOrder get sortOrder => _sortOrder;
  String get viewMode => _viewMode;
  String? get selectedCategory => _selectedCategory;

  List<String> get allCategories {
    final categories = <String>{};
    for (var note in _notes) {
      if (note.category != null && note.category!.isNotEmpty) {
        categories.add(note.category!);
      }
    }
    return categories.toList()..sort();
  }

  NotesProvider() {
    _loadPreferences();
    fetchNotes();
  }

  Future<void> _loadPreferences() async {
    _viewMode = await _storageService.getViewMode();
    final sortOrderString = await _storageService.getSortOrder();
    _sortOrder = _parseSortOrder(sortOrderString);
    notifyListeners();
  }

  SortOrder _parseSortOrder(String value) {
    switch (value) {
      case 'updated_asc':
        return SortOrder.updatedAsc;
      case 'created_desc':
        return SortOrder.createdDesc;
      case 'created_asc':
        return SortOrder.createdAsc;
      case 'title_asc':
        return SortOrder.titleAsc;
      case 'title_desc':
        return SortOrder.titleDesc;
      default:
        return SortOrder.updatedDesc;
    }
  }

  String _sortOrderToString(SortOrder order) {
    switch (order) {
      case SortOrder.updatedAsc:
        return 'updated_asc';
      case SortOrder.createdDesc:
        return 'created_desc';
      case SortOrder.createdAsc:
        return 'created_asc';
      case SortOrder.titleAsc:
        return 'title_asc';
      case SortOrder.titleDesc:
        return 'title_desc';
      default:
        return 'updated_desc';
    }
  }

  Future<void> fetchNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _apiService.getNotes();
      // Sort notes by created date, newest first
      _notes.sort((a, b) {
        final aDate = a.createdAtDate ?? DateTime(0);
        final bDate = b.createdAtDate ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
      _applyFiltersAndSort();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _notes = [];
      _filteredNotes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createNote(Note note) async {
    try {
      await _apiService.createNote(note);
      await fetchNotes(); // Reload notes to get the created one with ID
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNote(int id, Note note) async {
    try {
      await _apiService.updateNote(id, note);
      await fetchNotes(); // Reload notes to get updated data
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNote(int id) async {
    try {
      await _apiService.deleteNote(id);
      _notes.removeWhere((note) => note.id == id);
      _applyFiltersAndSort();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleFavorite(int id, bool favorite) async {
    try {
      await _apiService.toggleFavorite(id, favorite);
      await fetchNotes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleTrash(int id, bool trash) async {
    try {
      await _apiService.toggleTrash(id, trash);
      await fetchNotes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    _sortOrder = order;
    _storageService.setSortOrder(_sortOrderToString(order));
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setViewMode(String mode) {
    _viewMode = mode;
    _storageService.setViewMode(mode);
    notifyListeners();
  }

  void toggleCategory(String? category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearCategoryFilter() {
    _selectedCategory = null;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    // Start with all notes, excluding trashed ones
    var filtered = List<Note>.from(_notes.where((note) => !note.trash));

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) {
        final query = _searchQuery.toLowerCase();
        return note.title.toLowerCase().contains(query) ||
            note.body.toLowerCase().contains(query) ||
            (note.category?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((note) {
        return note.category == _selectedCategory;
      }).toList();
    }

    // Sort based on selected order
    switch (_sortOrder) {
      case SortOrder.updatedDesc:
        filtered.sort((a, b) {
          final aDate = a.updatedAtDate ?? a.createdAtDate ?? DateTime(0);
          final bDate = b.updatedAtDate ?? b.createdAtDate ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
        break;
      case SortOrder.updatedAsc:
        filtered.sort((a, b) {
          final aDate = a.updatedAtDate ?? a.createdAtDate ?? DateTime(0);
          final bDate = b.updatedAtDate ?? b.createdAtDate ?? DateTime(0);
          return aDate.compareTo(bDate);
        });
        break;
      case SortOrder.createdDesc:
        filtered.sort((a, b) {
          final aDate = a.createdAtDate ?? DateTime(0);
          final bDate = b.createdAtDate ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
        break;
      case SortOrder.createdAsc:
        filtered.sort((a, b) {
          final aDate = a.createdAtDate ?? DateTime(0);
          final bDate = b.createdAtDate ?? DateTime(0);
          return aDate.compareTo(bDate);
        });
        break;
      case SortOrder.titleAsc:
        filtered.sort((a, b) {
          return a.title.compareTo(b.title);
        });
        break;
      case SortOrder.titleDesc:
        filtered.sort((a, b) {
          return b.title.compareTo(a.title);
        });
        break;
    }

    _filteredNotes = filtered;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
