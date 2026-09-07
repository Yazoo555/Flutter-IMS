/// Student-controlled project progress. Deliberately NOT derived from tasks
/// or milestones — the student self-reports the overall percentage and the
/// per-area breakdown estimates.
library;

/// The official Internal Project Defense readiness target, from the FYP
/// context document ("project should be at least 75% complete").
const int kDefenseTargetPercent = 75;

/// Keys allowed in the progress breakdown.
const List<String> kProgressBreakdownKeys = [
  'research',
  'design',
  'development',
  'testing',
  'documentation',
  'presentation',
];

extension ProgressBreakdownLabel on String {
  String get breakdownLabel => switch (this) {
        'research' => 'Research',
        'design' => 'Design',
        'development' => 'Development',
        'testing' => 'Testing',
        'documentation' => 'Documentation',
        'presentation' => 'Presentation',
        _ => this,
      };
}

class ProjectProgress {
  /// Self-reported overall project completion, clamped to 0–100.
  final int overallPercent;

  /// Self-reported per-area estimates, 0–100 each.
  final Map<String, int> breakdown;
  final DateTime updatedAt;

  ProjectProgress({
    int? overallPercent,
    Map<String, int>? breakdown,
    DateTime? updatedAt,
  })  : overallPercent = overallPercent == null
            ? 0
            : overallPercent.clamp(0, 100),
        breakdown = _clampedBreakdown(breakdown),
        updatedAt = updatedAt ?? DateTime.now();

  /// All breakdown values are clamped to 0–100.
  static Map<String, int> _clampedBreakdown(Map<String, int>? input) {
    if (input == null) return {};
    return input.map((k, v) => MapEntry(k, v.clamp(0, 100)));
  }

  /// Defense target status: below / on / above the official 75% target.
  ({String label, bool onTrack}) defenseStatus() {
    if (overallPercent < kDefenseTargetPercent) {
      return (label: 'Below target', onTrack: false);
    }
    if (overallPercent == kDefenseTargetPercent) {
      return (label: 'On target', onTrack: true);
    }
    return (label: 'Above target', onTrack: true);
  }

  ProjectProgress copyWith({
    int? overallPercent,
    Map<String, int>? breakdown,
    DateTime? updatedAt,
  }) {
    return ProjectProgress(
      overallPercent: overallPercent ?? this.overallPercent,
      breakdown: breakdown ?? this.breakdown,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'overallPercent': overallPercent,
        'breakdown': breakdown,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ProjectProgress.fromJson(Map<String, dynamic> json) =>
      ProjectProgress(
        overallPercent: ((json['overallPercent'] ?? 0) as num).toInt(),
        breakdown: ((json['breakdown'] ?? {}) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, ((v ?? 0) as num).toInt())),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}
