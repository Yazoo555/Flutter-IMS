/// Milestone model — the major checkpoints of the FYP journey
/// (proposal submission, mid evaluation, final defense, …).
library;

enum MilestoneStatus { notStarted, inProgress, submitted }

/// Human-readable labels for milestone statuses.
extension MilestoneStatusLabel on MilestoneStatus {
  String get label {
    switch (this) {
      case MilestoneStatus.notStarted:
        return 'NOT STARTED';
      case MilestoneStatus.inProgress:
        return 'IN PROGRESS';
      case MilestoneStatus.submitted:
        return 'SUBMITTED';
    }
  }
}

class Milestone {
  final String id;
  final String title;
  final String description;

  /// When the milestone work is due.
  final DateTime deadline;

  /// When the related portal window opens (optional).
  final DateTime? portalOpenDate;
  final MilestoneStatus status;
  final FypPriorityLevel priority;

  /// True when the milestone depends on something outside the student's
  /// control (e.g. supervisor approval, board result).
  final bool isConditional;

  /// 0.0 → 1.0 completion estimate.
  final double percentageComplete;
  final String notes;

  Milestone({
    required this.id,
    required this.title,
    this.description = '',
    required this.deadline,
    this.portalOpenDate,
    this.status = MilestoneStatus.notStarted,
    this.priority = FypPriorityLevel.medium,
    this.isConditional = false,
    this.percentageComplete = 0,
    this.notes = '',
  }) : assert(
          percentageComplete >= 0 && percentageComplete <= 1,
          'percentageComplete must be between 0 and 1',
        );

  Milestone copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    DateTime? portalOpenDate,
    MilestoneStatus? status,
    FypPriorityLevel? priority,
    bool? isConditional,
    double? percentageComplete,
    String? notes,
    bool clearPortalOpenDate = false,
  }) {
    return Milestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      portalOpenDate:
          clearPortalOpenDate ? null : (portalOpenDate ?? this.portalOpenDate),
      status: status ?? this.status,
      priority: priority ?? this.priority,
      isConditional: isConditional ?? this.isConditional,
      percentageComplete: percentageComplete ?? this.percentageComplete,
      notes: notes ?? this.notes,
    );
  }

  bool get isComplete => status == MilestoneStatus.submitted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'deadline': deadline.toIso8601String(),
        'portalOpenDate': portalOpenDate?.toIso8601String(),
        'status': status.name,
        'priority': priority.name,
        'isConditional': isConditional,
        'percentageComplete': percentageComplete,
        'notes': notes,
      };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'] as String,
        title: json['title'] as String,
        description: (json['description'] ?? '') as String,
        deadline: DateTime.parse(json['deadline'] as String),
        portalOpenDate: json['portalOpenDate'] != null
            ? DateTime.parse(json['portalOpenDate'] as String)
            : null,
        status: MilestoneStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => MilestoneStatus.notStarted,
        ),
        priority: FypPriorityLevel.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => FypPriorityLevel.medium,
        ),
        isConditional: (json['isConditional'] ?? false) as bool,
        percentageComplete:
            ((json['percentageComplete'] ?? 0) as num).toDouble(),
        notes: (json['notes'] ?? '') as String,
      );
}

/// Local alias to avoid importing the event model just for the priority enum.
enum FypPriorityLevel { low, medium, high, critical }
