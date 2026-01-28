class Notification {
  final int? id;
  final String title;
  final String message;
  final String? category;
  final String? label;
  final bool? read;
  final String? createdAt;

  Notification({
    this.id,
    required this.title,
    required this.message,
    this.category,
    this.label,
    this.read,
    this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      category: json['category'] as String?,
      label: json['label'] as String?,
      read: json['read'] as bool?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'message': message,
      if (category != null) 'category': category,
      if (label != null) 'label': label,
      if (read != null) 'read': read,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  DateTime? get createdAtDate {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!);
    } catch (e) {
      return null;
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
