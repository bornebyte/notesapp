class DashboardStats {
  final int totalNotes;
  final int totalTrashed;
  final int totalFavorites;
  final int totalNotifications;
  final int notesToday;
  final int notesThisWeek;
  final List<RecentNote> recentNotes;
  final List<RecentNotification> recentNotifications;
  final Map<String, int> categoryStats;
  final List<UpcomingTarget> upcomingTargets;

  DashboardStats({
    required this.totalNotes,
    required this.totalTrashed,
    required this.totalFavorites,
    required this.totalNotifications,
    required this.notesToday,
    required this.notesThisWeek,
    required this.recentNotes,
    required this.recentNotifications,
    required this.categoryStats,
    required this.upcomingTargets,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalNotes: json['totalNotes'] ?? 0,
      totalTrashed: json['totalTrashed'] ?? 0,
      totalFavorites: json['totalFavorites'] ?? 0,
      totalNotifications: json['totalNotifications'] ?? 0,
      notesToday: json['notesToday'] ?? 0,
      notesThisWeek: json['notesThisWeek'] ?? 0,
      recentNotes:
          (json['recentNotes'] as List<dynamic>?)
              ?.map((e) => RecentNote.fromJson(e))
              .toList() ??
          [],
      recentNotifications:
          (json['recentNotifications'] as List<dynamic>?)
              ?.map((e) => RecentNotification.fromJson(e))
              .toList() ??
          [],
      categoryStats: Map<String, int>.from(json['categoryStats'] ?? {}),
      upcomingTargets:
          (json['upcomingTargets'] as List<dynamic>?)
              ?.map((e) => UpcomingTarget.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RecentNote {
  final int id;
  final String title;
  final String createdAt;
  final String? lastupdated;
  final bool fav;

  RecentNote({
    required this.id,
    required this.title,
    required this.createdAt,
    this.lastupdated,
    required this.fav,
  });

  factory RecentNote.fromJson(Map<String, dynamic> json) {
    return RecentNote(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      createdAt: json['created_at'] ?? '',
      lastupdated: json['lastupdated'],
      fav: json['fav'] ?? false,
    );
  }
}

class RecentNotification {
  final int id;
  final String title;
  final String createdAt;
  final String category;
  final String label;

  RecentNotification({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.category,
    required this.label,
  });

  factory RecentNotification.fromJson(Map<String, dynamic> json) {
    return RecentNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      createdAt: json['created_at'] ?? '',
      category: json['category'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class UpcomingTarget {
  final int id;
  final String name;
  final String targetdate;
  final int leftdays;

  UpcomingTarget({
    required this.id,
    required this.name,
    required this.targetdate,
    required this.leftdays,
  });

  factory UpcomingTarget.fromJson(Map<String, dynamic> json) {
    return UpcomingTarget(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      targetdate: json['targetdate'] ?? '',
      leftdays: json['leftdays'] ?? 0,
    );
  }
}

class ProductivityData {
  final String date;
  final int count;

  ProductivityData({required this.date, required this.count});

  factory ProductivityData.fromJson(Map<String, dynamic> json) {
    return ProductivityData(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class ActivityItem {
  final String type;
  final int id;
  final String title;
  final String timestamp;

  ActivityItem({
    required this.type,
    required this.id,
    required this.title,
    required this.timestamp,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      type: json['type'] ?? '',
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class MonthlyChartData {
  final String month;
  final int count;

  MonthlyChartData({required this.month, required this.count});

  factory MonthlyChartData.fromJson(Map<String, dynamic> json) {
    return MonthlyChartData(
      month: json['month'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
