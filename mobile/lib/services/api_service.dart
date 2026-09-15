import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
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

    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {
      // Platform check may fail on some environments
    }
    return 'http://127.0.0.1:8000';
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
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
}


