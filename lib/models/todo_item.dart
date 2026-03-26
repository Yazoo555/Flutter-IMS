import 'package:flutter/material.dart';

enum TodoCategory { assignment, tutorial, workshop, other }

enum TodoPriority { low, medium, high }

class TodoItem {
  final String id;
  final String title;
  final String? description;
  final TodoCategory category;
  final TodoPriority priority;
  final String? subject; // links to a subject name
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    this.subject,
    this.dueDate,
    required this.isCompleted,
    required this.createdAt,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    TodoCategory? category,
    TodoPriority? priority,
    String? subject,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    bool clearDueDate = false,
    bool clearSubject = false,
    bool clearDescription = false,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      category: category ?? this.category,
      priority: priority ?? this.priority,
      subject: clearSubject ? null : (subject ?? this.subject),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.index,
    'priority': priority.index,
    'subject': subject,
    'dueDate': dueDate?.toIso8601String(),
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    category: TodoCategory.values[json['category'] as int],
    priority: TodoPriority.values[json['priority'] as int],
    subject: json['subject'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    isCompleted: json['isCompleted'] as bool,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

// ── Display helpers ───────────────────────────────────────────────────────────

extension TodoCategoryX on TodoCategory {
  String get label {
    switch (this) {
      case TodoCategory.assignment:
        return 'Assignment';
      case TodoCategory.tutorial:
        return 'Tutorial';
      case TodoCategory.workshop:
        return 'Workshop';
      case TodoCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case TodoCategory.assignment:
        return Icons.assignment_outlined;
      case TodoCategory.tutorial:
        return Icons.menu_book_outlined;
      case TodoCategory.workshop:
        return Icons.build_circle_outlined;
      case TodoCategory.other:
        return Icons.checklist_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TodoCategory.assignment:
        return const Color(0xFF6C63FF);
      case TodoCategory.tutorial:
        return const Color(0xFF00BFA5);
      case TodoCategory.workshop:
        return const Color(0xFFFF6D6D);
      case TodoCategory.other:
        return const Color(0xFFFFB347);
    }
  }
}

extension TodoPriorityX on TodoPriority {
  String get label {
    switch (this) {
      case TodoPriority.low:
        return 'Low';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case TodoPriority.low:
        return const Color(0xFF22C55E);
      case TodoPriority.medium:
        return const Color(0xFFFFB347);
      case TodoPriority.high:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case TodoPriority.low:
        return Icons.arrow_downward_rounded;
      case TodoPriority.medium:
        return Icons.remove_rounded;
      case TodoPriority.high:
        return Icons.arrow_upward_rounded;
    }
  }
}
