// lib/data/events/events_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/event.dart';
import '../core/api_client.dart';

class EventsRepository {
  final ApiClient _apiClient;

  EventsRepository(this._apiClient);

  /// GET /api/events
  Future<List<Event>> getEvents() async {
    final response = await _apiClient.get('/api/events');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => Event.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/events/{id}
  Future<Event> getEventDetail(int id) async {
    final response = await _apiClient.get('/api/events/$id');
    return Event.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/events
  Future<Event> createEvent({
    required String name,
    String? description,
    DateTime? scheduledAt,
    int? durationMinutes,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
    };

    final response = await _apiClient.post('/api/events', data: body);
    return Event.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /api/events/{id}
  Future<Event> updateEvent({
    required int id,
    String? name,
    String? description,
    DateTime? scheduledAt,
    int? durationMinutes,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
    };

    final response = await _apiClient.put('/api/events/$id', data: body);
    return Event.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /api/events/{id}
  Future<void> deleteEvent(int id) async {
    await _apiClient.delete('/api/events/$id');
  }
}

/// Repo provider
final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return EventsRepository(apiClient);
});

/// Event listesi için FutureProvider
final eventsListProvider = FutureProvider<List<Event>>((ref) async {
  final repo = ref.read(eventsRepositoryProvider);
  return repo.getEvents();
});
