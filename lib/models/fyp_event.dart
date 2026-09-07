/// Core FYP domain models: events, phases and the official Cohort 11
/// week-numbering structure.
///
/// Source of truth: `FYP_Calendar_Cohort11_Context.md` — the calendar runs
/// Monday 3 August 2026 → Sunday 12 September 2027 (406 days). Weeks are
/// numbered 1–50, but some weeks carry special labels ("Dashain Holiday",
/// "Non Teaching Week") instead of numbers; [weekLabelOf] resolves the exact
/// label for any date.
library;

/// When the Cohort 11 FYP calendar officially begins (Monday).
final DateTime fypTimelineStart = DateTime(2026, 8, 3);

/// When the Cohort 11 FYP calendar officially ends (Sunday).
final DateTime fypTimelineEnd = DateTime(2027, 9, 12);

/// Number of officially numbered weeks (Week 1–50). Holiday and
/// non-teaching weeks carry labels instead of numbers and are not counted.
const int fypTotalWeeks = 50;

/// Monday of the week containing [date].
DateTime mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// Weeks that carry a special label in the source sheet instead of a number,
/// keyed by their Monday. Derived verbatim from the official calendar:
/// 5 Dashain weeks + 3 December non-teaching weeks.
final Map<DateTime, String> _specialWeekLabels = {
  DateTime(2026, 10, 12): 'Dashain Holiday',
  DateTime(2026, 10, 19): 'Dashain Holiday',
  DateTime(2026, 10, 26): 'Dashain Holiday',
  DateTime(2026, 11, 2): 'Dashain Holiday',
  DateTime(2026, 11, 9): 'Dashain Holiday',
  DateTime(2026, 12, 7): 'Non Teaching Week',
  DateTime(2026, 12, 14): 'Non Teaching Week',
  DateTime(2026, 12, 21): 'Non Teaching Week',
};

/// 0-based raw week index since the timeline start (special weeks included).
int rawWeekIndexOf(DateTime date) =>
    mondayOf(date).difference(mondayOf(fypTimelineStart)).inDays ~/ 7;

/// Official week number (1–50) for [date], or null when its week carries a
/// special label or lies outside the official range.
int? officialWeekNumber(DateTime date) {
  final raw = rawWeekIndexOf(date);
  if (raw < 0 || raw > 57) return null; // 58 raw weeks in the 406-day range
  if (_specialWeekLabels.containsKey(mondayOf(date))) return null;
  var numbered = 0;
  for (var i = 0; i < raw; i++) {
    final monday = mondayOf(fypTimelineStart).add(Duration(days: 7 * i));
    if (!_specialWeekLabels.containsKey(monday)) numbered++;
  }
  return numbered + 1;
}

/// Week label exactly as printed in the source sheet: "Week N",
/// "Dashain Holiday" or "Non Teaching Week".
String weekLabelOf(DateTime date) {
  final special = _specialWeekLabels[mondayOf(date)];
  if (special != null) return special;
  final n = officialWeekNumber(date);
  if (n == null) {
    return date.isBefore(fypTimelineStart) ? 'Pre-FYP' : 'Post-FYP';
  }
  return 'Week $n';
}

/// The five development stages of the FYP journey (informational).
enum FypPhase {
  phase1('Phase 1', 'Proposal & Foundation'),
  phase2('Phase 2', 'Core Development'),
  phase3('Phase 3', 'Mid Evaluation'),
  phase4('Phase 4', 'Final Development'),
  phase5('Phase 5', 'Defense & Submission');

  final String label;
  final String description;
  const FypPhase(this.label, this.description);
}

/// Categories of events on the FYP calendar, mirroring the source sheet's
/// color taxonomy. Each maps to a semantic color in
/// [AppColors.categoryColor] and an icon in `event_visuals.dart`.
enum FypEventCategory {
  deadline,
  assessment,
  portalOpening,
  googleForm,
  session,
  supervisor,
  board,
  holiday,
  milestone,
  other,
}

/// Human-readable labels for event categories.
extension FypEventCategoryLabel on FypEventCategory {
  String get label {
    switch (this) {
      case FypEventCategory.deadline:
        return 'Deadline';
      case FypEventCategory.assessment:
        return 'Assessment';
      case FypEventCategory.portalOpening:
        return 'Portal';
      case FypEventCategory.googleForm:
        return 'Google Form';
      case FypEventCategory.session:
        return 'Session';
      case FypEventCategory.supervisor:
        return 'Supervisor';
      case FypEventCategory.board:
        return 'Board';
      case FypEventCategory.holiday:
        return 'Holiday';
      case FypEventCategory.milestone:
        return 'Milestone';
      case FypEventCategory.other:
        return 'Other';
    }
  }
}

/// Shared priority levels used across events and milestones.
enum FypPriority { low, medium, high, critical }

/// Default priority per category, following the source sheet's taxonomy
/// (deadline = highest, holiday = informational).
FypPriority categoryDefaultPriority(FypEventCategory category) =>
    switch (category) {
      FypEventCategory.deadline => FypPriority.critical,
      FypEventCategory.assessment => FypPriority.high,
      FypEventCategory.board => FypPriority.high,
      FypEventCategory.milestone => FypPriority.high,
      FypEventCategory.portalOpening => FypPriority.medium,
      FypEventCategory.googleForm => FypPriority.medium,
      FypEventCategory.supervisor => FypPriority.medium,
      FypEventCategory.session => FypPriority.low,
      FypEventCategory.holiday => FypPriority.low,
      FypEventCategory.other => FypPriority.low,
    };

class FypEvent {
  final String id;
  final DateTime date;

  /// Optional end date for multi-day periods (holidays, defense windows).
  final DateTime? endDate;
  final String title;
  final String description;
  final FypEventCategory category;
  final FypPriority priority;

  /// 1-based official week number (null for special-label weeks).
  final int? weekNumber;
  final bool isCompleted;
  final bool isImportant;

  /// For portal events: the date the portal actually opens.
  final DateTime? portalOpenDate;

  /// For deadline events: the hard deadline.
  final DateTime? deadlineDate;
  final String notes;

  /// Id of the official milestone this event belongs to, used to model the
  /// Portal Opening → Preparation Window → Deadline relationship.
  final String? relatedMilestoneId;

  /// True when the event only applies to some students (e.g. resit gate).
  final bool isConditional;

  FypEvent({
    required this.id,
    required this.date,
    this.endDate,
    required this.title,
    this.description = '',
    required this.category,
    this.priority = FypPriority.medium,
    int? weekNumber,
    this.isCompleted = false,
    this.isImportant = false,
    this.portalOpenDate,
    this.deadlineDate,
    this.notes = '',
    this.relatedMilestoneId,
    this.isConditional = false,
  }) : weekNumber = weekNumber ?? officialWeekNumber(date);

  /// 1-based official week label for this event's date.
  String get weekLabel => weekLabelOf(date);

  FypEvent copyWith({
    String? id,
    DateTime? date,
    DateTime? endDate,
    String? title,
    String? description,
    FypEventCategory? category,
    FypPriority? priority,
    int? weekNumber,
    bool? isCompleted,
    bool? isImportant,
    DateTime? portalOpenDate,
    DateTime? deadlineDate,
    String? notes,
    String? relatedMilestoneId,
    bool? isConditional,
    bool clearEndDate = false,
    bool clearPortalOpenDate = false,
    bool clearDeadlineDate = false,
  }) {
    return FypEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      weekNumber: weekNumber ?? this.weekNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      portalOpenDate:
          clearPortalOpenDate ? null : (portalOpenDate ?? this.portalOpenDate),
      deadlineDate:
          clearDeadlineDate ? null : (deadlineDate ?? this.deadlineDate),
      notes: notes ?? this.notes,
      relatedMilestoneId: relatedMilestoneId ?? this.relatedMilestoneId,
      isConditional: isConditional ?? this.isConditional,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'weekNumber': weekNumber,
        'isCompleted': isCompleted,
        'isImportant': isImportant,
        'portalOpenDate': portalOpenDate?.toIso8601String(),
        'deadlineDate': deadlineDate?.toIso8601String(),
        'notes': notes,
        'relatedMilestoneId': relatedMilestoneId,
        'isConditional': isConditional,
      };

  factory FypEvent.fromJson(Map<String, dynamic> json) => FypEvent(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        title: json['title'] as String,
        description: (json['description'] ?? '') as String,
        category: FypEventCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => FypEventCategory.other,
        ),
        priority: FypPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => FypPriority.medium,
        ),
        weekNumber: json['weekNumber'] as int?,
        isCompleted: (json['isCompleted'] ?? false) as bool,
        isImportant: (json['isImportant'] ?? false) as bool,
        portalOpenDate: json['portalOpenDate'] != null
            ? DateTime.parse(json['portalOpenDate'] as String)
            : null,
        deadlineDate: json['deadlineDate'] != null
            ? DateTime.parse(json['deadlineDate'] as String)
            : null,
        notes: (json['notes'] ?? '') as String,
        relatedMilestoneId: json['relatedMilestoneId'] as String?,
        isConditional: (json['isConditional'] ?? false) as bool,
      );
}

/// Timing helpers computed from the real clock — never a hardcoded "today".
extension FypEventTiming on FypEvent {
  /// Midnight of the event's first day.
  DateTime get startDay => DateTime(date.year, date.month, date.day);

  /// Midnight of the event's last day (same as start for single-day events).
  DateTime get endDay => endDate == null
      ? startDay
      : DateTime(endDate!.year, endDate!.month, endDate!.day);

  bool get isSingleDay => endDate == null;

  /// Whether [day] (any time of day) falls within the event's span.
  bool isOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(startDay) && !d.isAfter(endDay);
  }

  bool get isToday => isOn(DateTime.now());

  /// The event's span has completely passed (today is after the end day).
  bool get hasEnded {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(endDay);
  }

  /// Whole days from today until the event's first day
  /// (0 = today, negative = in the past).
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return startDay.difference(today).inDays;
  }
}
