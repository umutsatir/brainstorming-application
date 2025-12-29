import 'package:flutter/material.dart';

/// Şimdilik sadece UI için kullanılan basit event modeli.
/// İleride backend Event modeline bağlarız.
class UiEvent {
  final int id;
  final String title;
  final String description;
  final DateTime dateTime;
  final int durationMinutes;
  final String status; // 'Planned', 'In Progress', 'Completed' gibi

  UiEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.durationMinutes,
    required this.status,
  });
}

/// Dummy veriler – şimdilik backend yerine bunları gösteriyoruz.
final List<UiEvent> dummyEvents = [
  UiEvent(
    id: 1,
    title: 'New Product Launch 6-3-5',
    description:
        'Brainstorm ideas for the next product launch campaign with the 6-3-5 method.',
    dateTime: DateTime(2025, 1, 10, 14, 30),
    durationMinutes: 90,
    status: 'Planned',
  ),
  UiEvent(
    id: 2,
    title: 'UX Improvement Session',
    description: 'Improve onboarding experience for new users.',
    dateTime: DateTime(2025, 1, 12, 10, 0),
    durationMinutes: 60,
    status: 'In Progress',
  ),
  UiEvent(
    id: 3,
    title: 'Quarterly Strategy Workshop',
    description: 'Align roadmap and OKRs for next quarter.',
    dateTime: DateTime(2025, 1, 15, 16, 0),
    durationMinutes: 120,
    status: 'Completed',
  ),
];

/// Event tarihini basitçe formatlayan helper.
/// Örn: 2025-01-10  14:30
String formatEventDateTime(DateTime dt) {
  final year = dt.year.toString().padLeft(4, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');

  return '$year-$month-$day  $hour:$minute';
}

Color statusChipColor(String status, BuildContext context) {
  final theme = Theme.of(context);
  switch (status.toLowerCase()) {
    case 'planned':
      return theme.colorScheme.primary.withOpacity(0.15);
    case 'in progress':
      return Colors.orange.withOpacity(0.15);
    case 'completed':
      return Colors.green.withOpacity(0.15);
    default:
      return theme.colorScheme.surfaceVariant.withOpacity(0.5);
  }
}

Color statusTextColor(String status, BuildContext context) {
  switch (status.toLowerCase()) {
    case 'planned':
      return Theme.of(context).colorScheme.primary;
    case 'in progress':
      return Colors.orange;
    case 'completed':
      return Colors.green;
    default:
      return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
