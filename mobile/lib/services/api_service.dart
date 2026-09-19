import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  final String baseUrl;
  final String? authToken;

  ApiService({String? baseUrl, this.authToken})
      : baseUrl = baseUrl ?? _defaultBaseUrl;

  static String get _defaultBaseUrl {
    const envUrl = String.fromEnvironment('BACKEND_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // Default production API server:
    return 'https://api.alurproject.web.id';
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-User-Id': '00000000-0000-0000-0000-000000000001',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<WeekData> fetchWeekTasks({String? weekDate}) async {
    final uri = Uri.parse('$baseUrl/tasks').replace(
      queryParameters: weekDate != null ? {'week': weekDate} : null,
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return WeekData.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load tasks: ${response.statusCode} ${response.body}');
    }
  }

  Future<Task> createTask({
    required String title,
    required String assignedDate,
    int? estimatedMinutes,
  }) async {
    final uri = Uri.parse('$baseUrl/tasks');
    final body = jsonEncode({
      'title': title,
      'assigned_date': assignedDate,
      'estimated_minutes': ?estimatedMinutes,
    });

    final response = await http.post(uri, headers: _headers, body: body);

    if (response.statusCode == 201) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return Task.fromJson(jsonMap);
    } else {
      throw Exception('Failed to create task: ${response.statusCode} ${response.body}');
    }
  }

  Future<Task> toggleTaskStatus({
    required String taskId,
    required bool isDone,
  }) async {
    final uri = Uri.parse('$baseUrl/tasks/$taskId');
    final body = jsonEncode({
      'status': isDone ? 'DONE' : 'PENDING',
    });

    final response = await http.patch(uri, headers: _headers, body: body);

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return Task.fromJson(jsonMap);
    } else {
      throw Exception('Failed to update task: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> deleteTask({required String taskId}) async {
    final uri = Uri.parse('$baseUrl/tasks/$taskId');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode != 204) {
      throw Exception('Failed to delete task: ${response.statusCode}');
    }
  }

  Future<List<Task>> brainDump({required String text}) async {
    final uri = Uri.parse('$baseUrl/brain-dump');
    final body = jsonEncode({'text': text});

    final response = await http.post(uri, headers: _headers, body: body);

    if (response.statusCode == 201) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => Task.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Brain-dump failed: ${response.statusCode} ${response.body}');
    }
  }

  Future<Task> clarifyTask({
    required String taskId,
    required int estimatedMinutes,
  }) async {
    final uri = Uri.parse('$baseUrl/tasks/$taskId/clarify');
    final body = jsonEncode({'estimated_minutes': estimatedMinutes});

    final response = await http.patch(uri, headers: _headers, body: body);

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return Task.fromJson(jsonMap);
    } else {
      throw Exception('Failed to clarify task: ${response.statusCode} ${response.body}');
    }
  }

  Future<Task> followUpTask({
    required String taskId,
    required String action, // 'FORGOT' | 'SKIPPED' | 'RESCHEDULED'
  }) async {
    final uri = Uri.parse('$baseUrl/tasks/$taskId/follow-up');
    final body = jsonEncode({'action': action});

    final response = await http.patch(uri, headers: _headers, body: body);

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return Task.fromJson(jsonMap);
    } else {
      throw Exception('Failed to follow up task: ${response.statusCode} ${response.body}');
    }
  }

  Future<Task> respondReschedule({
    required String taskId,
    required String suggestionId,
    required String action, // 'ACCEPT' | 'REJECT'
  }) async {
    final uri = Uri.parse('$baseUrl/tasks/$taskId/reschedule');
    final body = jsonEncode({
      'suggestion_id': suggestionId,
      'action': action,
    });

    final response = await http.patch(uri, headers: _headers, body: body);

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return Task.fromJson(jsonMap);
    } else {
      throw Exception('Failed to respond to reschedule: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<Insight>> fetchInsights() async {
    final uri = Uri.parse('$baseUrl/insights?surfaced=true');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => Insight.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      return [];
    }
  }

  Future<ChatApiResponse> sendChatMessage(String message) async {
    final uri = Uri.parse('$baseUrl/chat/message');
    final body = jsonEncode({'message': message});

    final response = await http
        .post(uri, headers: _headers, body: body)
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatApiResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to send chat message: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<ChatHistoryEntry>> fetchChatHistory({String? date}) async {
    final uri = Uri.parse('$baseUrl/chat/history').replace(
      queryParameters: date != null ? {'date': date} : null,
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => ChatHistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPendingDeletionLogs() async {
    final uri = Uri.parse('$baseUrl/chat/history/pending-deletion');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>> exportChatHistory() async {
    final uri = Uri.parse('$baseUrl/chat/history/export');
    final response = await http.post(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to export chat history: ${response.statusCode}');
    }
  }

  Future<bool> overrideChatRetention({List<String>? logIds}) async {
    final uri = Uri.parse('$baseUrl/chat/history/retention-override');
    final payload = <String, dynamic>{'retention_override': true};
    if (logIds != null) {
      payload['log_ids'] = logIds;
    }
    final body = jsonEncode(payload);

    final response = await http.patch(uri, headers: _headers, body: body);
    return response.statusCode == 200;
  }

  Future<bool> deleteChatHistory() async {
    final uri = Uri.parse('$baseUrl/chat/history');
    final response = await http.delete(uri, headers: _headers);
    return response.statusCode == 200;
  }
}

class ChatApiResponse {
  final String reply;
  final String messageType;
  final String toneUsed;
  final String? moodDetected;
  final List<Task> extractedTasks;

  const ChatApiResponse({
    required this.reply,
    required this.messageType,
    required this.toneUsed,
    this.moodDetected,
    this.extractedTasks = const [],
  });

  factory ChatApiResponse.fromJson(Map<String, dynamic> json) {
    final tasksJson = json['extracted_tasks'] as List<dynamic>? ?? [];
    return ChatApiResponse(
      reply: json['reply'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'CHAT',
      toneUsed: json['tone_used'] as String? ?? 'HONEST',
      moodDetected: json['mood_detected'] as String?,
      extractedTasks: tasksJson
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatHistoryEntry {
  final String id;
  final String role;
  final String content;
  final String messageType;
  final String? toneUsed;
  final String? moodDetected;
  final DateTime createdAt;

  const ChatHistoryEntry({
    required this.id,
    required this.role,
    required this.content,
    required this.messageType,
    this.toneUsed,
    this.moodDetected,
    required this.createdAt,
  });

  factory ChatHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ChatHistoryEntry(
      id: json['id'] as String? ?? '',
      role: (json['role'] as String? ?? 'user').toLowerCase(),
      content: json['content'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'CHAT',
      toneUsed: json['tone_used'] as String?,
      moodDetected: json['mood_detected'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}


