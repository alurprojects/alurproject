class MorningBriefCapacity {
  final double totalHours;
  final double scheduledHours;
  final double remainingHours;

  const MorningBriefCapacity({
    required this.totalHours,
    required this.scheduledHours,
    required this.remainingHours,
  });

  factory MorningBriefCapacity.fromJson(Map<String, dynamic> json) {
    return MorningBriefCapacity(
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 8.0,
      scheduledHours: (json['scheduled_hours'] as num?)?.toDouble() ?? 0.0,
      remainingHours: (json['remaining_hours'] as num?)?.toDouble() ?? 8.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_hours': totalHours,
    'scheduled_hours': scheduledHours,
    'remaining_hours': remainingHours,
  };
}

class MorningBriefTaskItem {
  final String id;
  final String title;
  final int? estimatedMinutes;

  const MorningBriefTaskItem({
    required this.id,
    required this.title,
    this.estimatedMinutes,
  });

  factory MorningBriefTaskItem.fromJson(Map<String, dynamic> json) {
    return MorningBriefTaskItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      estimatedMinutes: json['estimated_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'estimated_minutes': estimatedMinutes,
  };
}

class MorningBriefMissedItem {
  final String id;
  final String title;
  final String followUp;

  const MorningBriefMissedItem({
    required this.id,
    required this.title,
    required this.followUp,
  });

  factory MorningBriefMissedItem.fromJson(Map<String, dynamic> json) {
    return MorningBriefMissedItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      followUp: json['follow_up'] as String? ?? 'PENDING',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'follow_up': followUp,
  };
}

class MorningBriefData {
  final String date;
  final String greeting;
  final List<MorningBriefTaskItem> tasks;
  final List<MorningBriefMissedItem> missedTasks;
  final MorningBriefCapacity capacitySummary;
  final String aiNote;

  const MorningBriefData({
    required this.date,
    required this.greeting,
    required this.tasks,
    required this.missedTasks,
    required this.capacitySummary,
    required this.aiNote,
  });

  factory MorningBriefData.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    final rawMissed = json['missed_tasks'] as List<dynamic>? ?? [];

    return MorningBriefData(
      date: json['date'] as String? ?? '',
      greeting: json['greeting'] as String? ?? 'Selamat pagi!',
      tasks: rawTasks
          .map((t) => MorningBriefTaskItem.fromJson(t as Map<String, dynamic>))
          .toList(),
      missedTasks: rawMissed
          .map((m) => MorningBriefMissedItem.fromJson(m as Map<String, dynamic>))
          .toList(),
      capacitySummary: MorningBriefCapacity.fromJson(
        json['capacity_summary'] as Map<String, dynamic>? ?? {},
      ),
      aiNote: json['ai_note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'greeting': greeting,
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'missed_tasks': missedTasks.map((m) => m.toJson()).toList(),
    'capacity_summary': capacitySummary.toJson(),
    'ai_note': aiNote,
  };
}
