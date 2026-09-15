class TaskSuggestion {
  final String id;
  final String taskId;
  final String userId;
  final String suggestedDate;
  final String? reason;
  final String status;
  final String? respondedAt;

  const TaskSuggestion({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.suggestedDate,
    this.reason,
    required this.status,
    this.respondedAt,
  });

  bool get isPending => status == 'PENDING';

  factory TaskSuggestion.fromJson(Map<String, dynamic> json) {
    return TaskSuggestion(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      suggestedDate: json['suggested_date'] as String,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      respondedAt: json['responded_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'suggested_date': suggestedDate,
      'reason': reason,
      'status': status,
      'responded_at': respondedAt,
    };
  }
}

class Task {
  final String id;
  final String userId;
  final String? goalId;
  final String title;
  final int? estimatedMinutes;
  final String? recurrenceRule;
  final String? recurrenceGroupId;
  final String assignedDate;
  final String status;
  final String source;
  final bool isAmbiguous;
  final bool aiGenerated;
  final String missedFollowUp;
  final TaskSuggestion? suggestion;

  const Task({
    required this.id,
    required this.userId,
    this.goalId,
    required this.title,
    this.estimatedMinutes,
    this.recurrenceRule,
    this.recurrenceGroupId,
    required this.assignedDate,
    required this.status,
    required this.source,
    required this.isAmbiguous,
    required this.aiGenerated,
    required this.missedFollowUp,
    this.suggestion,
  });

  bool get isDone => status == 'DONE';
  bool get isMissed => status == 'MISSED';
  bool get hasPendingFollowUp => missedFollowUp == 'PENDING';
  bool get hasPendingSuggestion => suggestion != null && suggestion!.isPending;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalId: json['goal_id'] as String?,
      title: json['title'] as String,
      estimatedMinutes: json['estimated_minutes'] as int?,
      recurrenceRule: json['recurrence_rule'] as String?,
      recurrenceGroupId: json['recurrence_group_id'] as String?,
      assignedDate: json['assigned_date'] as String,
      status: json['status'] as String? ?? 'PENDING',
      source: json['source'] as String? ?? 'MANUAL',
      isAmbiguous: json['is_ambiguous'] as bool? ?? false,
      aiGenerated: json['ai_generated'] as bool? ?? false,
      missedFollowUp: json['missed_follow_up'] as String? ?? 'NONE',
      suggestion: json['suggestion'] != null
          ? TaskSuggestion.fromJson(json['suggestion'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal_id': goalId,
      'title': title,
      'estimated_minutes': estimatedMinutes,
      'recurrence_rule': recurrenceRule,
      'recurrence_group_id': recurrenceGroupId,
      'assigned_date': assignedDate,
      'status': status,
      'source': source,
      'is_ambiguous': isAmbiguous,
      'ai_generated': aiGenerated,
      'missed_follow_up': missedFollowUp,
      'suggestion': suggestion?.toJson(),
    };
  }

  Task copyWith({
    String? status,
    String? title,
    String? assignedDate,
    int? estimatedMinutes,
    bool? isAmbiguous,
    String? missedFollowUp,
    TaskSuggestion? suggestion,
    bool clearSuggestion = false,
  }) {
    return Task(
      id: id,
      userId: userId,
      goalId: goalId,
      title: title ?? this.title,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      recurrenceRule: recurrenceRule,
      recurrenceGroupId: recurrenceGroupId,
      assignedDate: assignedDate ?? this.assignedDate,
      status: status ?? this.status,
      source: source,
      isAmbiguous: isAmbiguous ?? this.isAmbiguous,
      aiGenerated: aiGenerated,
      missedFollowUp: missedFollowUp ?? this.missedFollowUp,
      suggestion: clearSuggestion ? null : (suggestion ?? this.suggestion),
    );
  }
}

class DayData {
  final String date;
  final String dayName;
  final bool isToday;
  final List<Task> tasks;

  const DayData({
    required this.date,
    required this.dayName,
    required this.isToday,
    required this.tasks,
  });

  factory DayData.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    return DayData(
      date: json['date'] as String,
      dayName: json['day_name'] as String,
      isToday: json['is_today'] as bool? ?? false,
      tasks: rawTasks.map((t) => Task.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }

  DayData copyWith({List<Task>? tasks}) {
    return DayData(
      date: date,
      dayName: dayName,
      isToday: isToday,
      tasks: tasks ?? this.tasks,
    );
  }
}

class WeekData {
  final String weekStart;
  final String weekEnd;
  final List<DayData> days;

  const WeekData({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
  });

  factory WeekData.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? [];
    return WeekData(
      weekStart: json['week_start'] as String,
      weekEnd: json['week_end'] as String,
      days: rawDays.map((d) => DayData.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}

class Insight {
  final String id;
  final String userId;
  final String content;
  final String weekOf;
  final bool surfaced;

  const Insight({
    required this.id,
    required this.userId,
    required this.content,
    required this.weekOf,
    required this.surfaced,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      weekOf: json['week_of'] as String,
      surfaced: json['surfaced'] as bool? ?? true,
    );
  }
}
