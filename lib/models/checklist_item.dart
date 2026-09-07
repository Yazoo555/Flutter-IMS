/// Personal preparation checklist item attached to a milestone.
///
/// These are the student's own planning items (e.g. "Discuss title with
/// supervisor") — deliberately separate from official calendar events.
library;

class ChecklistItem {
  final String id;
  final String milestoneId;
  final String title;
  final bool done;

  ChecklistItem({
    required this.id,
    required this.milestoneId,
    required this.title,
    this.done = false,
  });

  ChecklistItem copyWith({String? title, bool? done}) => ChecklistItem(
        id: id,
        milestoneId: milestoneId,
        title: title ?? this.title,
        done: done ?? this.done,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'milestoneId': milestoneId,
        'title': title,
        'done': done,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] as String,
        milestoneId: json['milestoneId'] as String,
        title: json['title'] as String,
        done: (json['done'] ?? false) as bool,
      );
}
