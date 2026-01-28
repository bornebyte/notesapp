class TargetDate {
  final int? id;
  final String message;
  final String date;
  final String? shareId;

  TargetDate({
    this.id,
    required this.message,
    required this.date,
    this.shareId,
  });

  factory TargetDate.fromJson(Map<String, dynamic> json) {
    return TargetDate(
      id: json['id'] as int?,
      message: json['message'] as String? ?? '',
      date: json['date'] as String,
      shareId: json['shareid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'message': message};
  }

  DateTime? get targetDate {
    try {
      // Parse MM/DD/YYYY format
      final parts = date.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool get isOverdue {
    final target = targetDate;
    if (target == null) return false;
    return target.isBefore(DateTime.now());
  }

  // Calculate days difference (positive for future, negative for past)
  int? get daysDifference {
    final target = targetDate;
    if (target == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(target.year, target.month, target.day);
    return targetDay.difference(today).inDays;
  }
}
