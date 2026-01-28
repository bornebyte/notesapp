import 'package:intl/intl.dart';

class Notification {
  final int? id;
  final String title;
  final String? category;
  final String? label;
  final String? createdAt;

  Notification({
    this.id,
    required this.title,
    this.category,
    this.label,
    this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      category: json['category'] as String?,
      label: json['label'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (category != null) 'category': category,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  DateTime? get createdAtDate {
    if (createdAt == null) return null;
    try {
      // Parse format like "9/4/2025, 1:51:31 PM"
      final format = DateFormat('M/d/yyyy, h:mm:ss a');
      return format.parse(createdAt!);
    } catch (e) {
      // Fallback to ISO format if parsing fails
      try {
        return DateTime.parse(createdAt!);
      } catch (e) {
        return null;
      }
    }
  }
}

class FilterOption {
  final String category;
  final String label;

  FilterOption({required this.category, required this.label});

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      category: json['category'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}
