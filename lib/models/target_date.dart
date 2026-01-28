class TargetDate {
  final int? id;
  final String title;
  final String? description;
  final String date;
  final String? shareId;
  final String? createdAt;

  // Calculated fields
  final int? months;
  final int? days;
  final int? hours;
  final int? minutes;
  final int? progressPercentage;

  TargetDate({
    this.id,
    required this.title,
    this.description,
    required this.date,
    this.shareId,
    this.createdAt,
    this.months,
    this.days,
    this.hours,
    this.minutes,
    this.progressPercentage,
  });

  factory TargetDate.fromJson(Map<String, dynamic> json) {
    return TargetDate(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      date: json['date'] as String,
      shareId: json['shareid'] as String?,
      createdAt: json['created_at'] as String?,
      months: json['months'] as int?,
      days: json['days'] as int?,
      hours: json['hours'] as int?,
      minutes: json['minutes'] as int?,
      progressPercentage: json['progressPercentage'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      'date': date,
      if (shareId != null) 'shareid': shareId,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  DateTime? get targetDate {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return null;
    }
  }

  DateTime? get createdAtDate {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!);
    } catch (e) {
      return null;
    }
  }

  bool get isOverdue {
    final target = targetDate;
    if (target == null) return false;
    return target.isBefore(DateTime.now());
  }
}
