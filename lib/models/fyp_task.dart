/// Personal FYP task model — smaller to-dos that can link to a milestone.
library;

enum TaskStatus { todo, inProgress, done }

enum TaskPriority { low, medium, high, critical }

/// FYP-specific task categories.
enum TaskCategory {
  proposal,
  research,
  literatureReview,
  development,
  testing,
  documentation,
  presentation,
  meeting,
  other,
}

extension TaskCategoryLabel on TaskCategory {
  String get label => switch (this) {
        TaskCategory.proposal => 'Proposal',
        TaskCategory.research => 'Research',
        TaskCategory.literatureReview => 'Literature Review',
        TaskCategory.development => 'Development',
        TaskCategory.testing => 'Testing',
        TaskCategory.documentation => 'Documentation',
        TaskCategory.presentation => 'Presentation',
        TaskCategory.meeting => 'Meeting',
        TaskCategory.other => 'Other',
      };
}

class FypTask {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskStatus status;

  /// Optional milestone this task contributes to.
  final String? relatedMilestoneId;
  final TaskCategory category;
  final bool completed;

  /// When the task was created.
  final DateTime? createdAt;

  /// When the task was marked done (null while open).
  final DateTime? completedAt;

  FypTask({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.relatedMilestoneId,
    this.category = TaskCategory.other,
    this.completed = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isComplete => completed || status == TaskStatus.done;

  FypTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    String? relatedMilestoneId,
    TaskCategory? category,
    bool? completed,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearDueDate = false,
    bool clearRelatedMilestoneId = false,
    bool clearCompletedAt = false,
  }) {
    return FypTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      relatedMilestoneId: clearRelatedMilestoneId
          ? null
          : (relatedMilestoneId ?? this.relatedMilestoneId),
      category: category ?? this.category,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority.name,
        'status': status.name,
        'relatedMilestoneId': relatedMilestoneId,
        'category': category.name,
        'completed': completed,
        'createdAt': createdAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory FypTask.fromJson(Map<String, dynamic> json) => FypTask(
        id: json['id'] as String,
        title: json['title'] as String,
        description: (json['description'] ?? '') as String,
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        priority: TaskPriority.values.firstWhere(
          (e) => e.name == json['priority'] || (e.name == 'urgent' && json['priority'] == 'urgent'),
          orElse: () => TaskPriority.medium,
        ),
        status: TaskStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TaskStatus.todo,
        ),
        relatedMilestoneId: json['relatedMilestoneId'] as String?,
        category: TaskCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => TaskCategory.other,
        ),
        completed: (json['completed'] ?? false) as bool,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}
