/// Official process warnings from the FYP context document (Section 6).
/// Surfaced as helpful info cards where contextually relevant — never as
/// decoration.
library;

import 'package:flutter/material.dart';

class FypWarning {
  final String id;
  final String title;
  final String message;
  final IconData icon;

  /// Inclusive date window in which the warning is shown on the dashboard.
  /// null = always shown (e.g. milestone-scoped warnings).
  final DateTime? showFrom;
  final DateTime? showUntil;

  const FypWarning({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    this.showFrom,
    this.showUntil,
  });

  bool isRelevantOn(DateTime day) {
    if (showFrom == null) return true;
    return !day.isBefore(showFrom!) &&
        (showUntil == null || !day.isAfter(showUntil!));
  }
}

/// The official warnings, verbatim in spirit from the source document:
/// 1. Proposal must be supervisor-approved before submission.
/// 2. Internal defense requires ≥75% project completion.
/// 3. Use the portal window — don't wait for the deadline.
/// 4. Dashain Holiday creates a long teaching gap after Proposal Defense.
final List<FypWarning> fypWarnings = [
  FypWarning(
    id: 'proposal-approval',
    title: 'Proposal approval required',
    message:
        'Before the proposal deadline, your proposal must be approved by '
        'your supervisor via the Proposal Feedback Sheet. Keep getting '
        'feedback and revising until it is approved.',
    icon: Icons.fact_check_outlined,
    showFrom: DateTime(2026, 9, 1),
    showUntil: DateTime(2026, 9, 25),
  ),
  FypWarning(
    id: 'portal-window',
    title: 'Use the portal window',
    message:
        'Submission portals open roughly 9–10 days before each deadline. '
        'Use that window — don\'t wait until deadline day.',
    icon: Icons.app_registration_outlined,
  ),
  FypWarning(
    id: 'dashain-gap',
    title: 'Dashain Holiday teaching gap',
    message:
        'A ~5.5-week teaching gap follows the Proposal Defense (11 Oct – '
        '16 Nov). Plan your literature review work during the break — the '
        'next major session is on 23 November.',
    icon: Icons.beach_access_outlined,
    showFrom: DateTime(2026, 10, 4),
    showUntil: DateTime(2026, 11, 23),
  ),
  FypWarning(
    id: 'defense-75',
    title: 'Internal defense readiness',
    message:
        'By the Internal Project Defense (18–23 Apr), your project should '
        'be at least 75% complete.',
    icon: Icons.speed_outlined,
    showFrom: DateTime(2027, 3, 1),
    showUntil: DateTime(2027, 4, 23),
  ),
];

/// Warnings relevant on [day], limited to [max] items for a clean dashboard.
List<FypWarning> relevantWarningsOn(DateTime day, {int max = 2}) =>
    fypWarnings.where((w) => w.isRelevantOn(day)).take(max).toList();

/// Milestone-specific warning key (used inside milestone detail sheets).
String? warningForMilestone(String milestoneId) => switch (milestoneId) {
      'gate-2-proposal' => 'proposal-approval',
      'gate-3-resit' => null,
      _ => 'portal-window',
    };
