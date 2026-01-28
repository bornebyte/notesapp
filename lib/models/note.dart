import 'package:intl/intl.dart';

class Note {
  final int? id;
  final String title;
  final String body;
  final String? category;
  final bool hidden;
  final String createdAt;
  final bool fav;
  final bool trash;
  final bool archive;
  final String? lastupdated;
  final String? shareid;

  Note({
    this.id,
    required this.title,
    required this.body,
    this.category,
    this.hidden = false,
    required this.createdAt,
    this.fav = false,
    this.trash = false,
    this.archive = false,
    this.lastupdated,
    this.shareid,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      category: json['category'],
      hidden: json['hidden'] ?? false,
      createdAt: json['created_at'] ?? '',
      fav: json['fav'] ?? false,
      trash: json['trash'] ?? false,
      archive: json['archive'] ?? false,
      lastupdated: json['lastupdated'],
      shareid: json['shareid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'body': body,
      if (category != null) 'category': category,
    };
  }

  Note copyWith({
    int? id,
    String? title,
    String? body,
    String? category,
    bool? hidden,
    String? createdAt,
    bool? fav,
    bool? trash,
    bool? archive,
    String? lastupdated,
    String? shareid,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      hidden: hidden ?? this.hidden,
      createdAt: createdAt ?? this.createdAt,
      fav: fav ?? this.fav,
      trash: trash ?? this.trash,
      archive: archive ?? this.archive,
      lastupdated: lastupdated ?? this.lastupdated,
      shareid: shareid ?? this.shareid,
    );
  }

  DateTime? get updatedAtDate {
    if (lastupdated == null || lastupdated!.isEmpty) return null;
    try {
      // Try parsing ISO format first
      return DateTime.parse(lastupdated!);
    } catch (e) {
      // Try parsing custom format "12/28/2025, 6:51:17 PM"
      try {
        return DateFormat('M/d/yyyy, h:mm:ss a').parse(lastupdated!);
      } catch (e2) {
        return null;
      }
    }
  }

  DateTime? get createdAtDate {
    try {
      // Try parsing ISO format first
      return DateTime.parse(createdAt);
    } catch (e) {
      // Try parsing custom format "12/28/2025, 6:51:17 PM"
      try {
        return DateFormat('M/d/yyyy, h:mm:ss a').parse(createdAt);
      } catch (e2) {
        return null;
      }
    }
  }
}
