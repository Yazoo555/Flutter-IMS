/// Supervisor / project meeting model.
library;

enum MeetingType { supervisor, reader, team, other }

extension MeetingTypeLabel on MeetingType {
  String get label => switch (this) {
        MeetingType.supervisor => 'Supervisor Meeting',
        MeetingType.reader => 'Reader Meeting',
        MeetingType.team => 'Team Meeting',
        MeetingType.other => 'Other Meeting',
      };
}

class Meeting {
  final String id;
  final String title;
  final DateTime date;

  /// Stored as minutes since midnight (e.g. 14:30 → 870) to keep JSON simple.
  final int? timeMinutes;
  final MeetingType type;
  final String location;
  final String supervisor;
  final String notes;

  /// Optional milestone this meeting relates to.
  final String? relatedMilestoneId;
  final bool completed;

  Meeting({
    required this.id,
    required this.title,
    required this.date,
    this.timeMinutes,
    this.type = MeetingType.supervisor,
    this.location = '',
    this.supervisor = '',
    this.notes = '',
    this.relatedMilestoneId,
    this.completed = false,
  });

  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    return day.isBefore(today);
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Whole days from today until the meeting (negative if past).
  int get daysFromNow {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    return day.difference(today).inDays;
  }

  /// "14:30" or null when no time is set.
  String? get timeLabel {
    if (timeMinutes == null) return null;
    final h = (timeMinutes! ~/ 60).toString().padLeft(2, '0');
    final m = (timeMinutes! % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Meeting copyWith({
    String? id,
    String? title,
    DateTime? date,
    int? timeMinutes,
    MeetingType? type,
    String? location,
    String? supervisor,
    String? notes,
    String? relatedMilestoneId,
    bool? completed,
    bool clearTimeMinutes = false,
    bool clearRelatedMilestoneId = false,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      timeMinutes: clearTimeMinutes ? null : (timeMinutes ?? this.timeMinutes),
      type: type ?? this.type,
      location: location ?? this.location,
      supervisor: supervisor ?? this.supervisor,
      notes: notes ?? this.notes,
      relatedMilestoneId:
          clearRelatedMilestoneId ? null : (relatedMilestoneId ?? this.relatedMilestoneId),
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'timeMinutes': timeMinutes,
        'type': type.name,
        'location': location,
        'supervisor': supervisor,
        'notes': notes,
        'relatedMilestoneId': relatedMilestoneId,
        'completed': completed,
      };

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
        id: json['id'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        timeMinutes: json['timeMinutes'] as int?,
        type: MeetingType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MeetingType.supervisor,
        ),
        location: (json['location'] ?? '') as String,
        supervisor: (json['supervisor'] ?? '') as String,
        notes: (json['notes'] ?? '') as String,
        relatedMilestoneId: json['relatedMilestoneId'] as String?,
        completed: (json['completed'] ?? false) as bool,
      );
}
