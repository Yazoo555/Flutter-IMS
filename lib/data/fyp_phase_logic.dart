/// FYP Phase Tracker — derives the current phase automatically from the
/// official Cohort 11 timeline. Phase boundaries are anchored to official
/// events (gates, milestones, defense windows) from
/// `FYP_Calendar_Cohort11_Context.md`; nothing is hardcoded to "today".
library;

/// One stage of the FYP journey with its official date window.
class FypJourneyPhase {
  final String title;
  final DateTime start; // inclusive
  final DateTime end; // inclusive

  const FypJourneyPhase(this.title, this.start, this.end);

  bool contains(DateTime day) =>
      !day.isBefore(start) && !day.isAfter(end);
}

/// The 13 official phases, in chronological order. Windows span from the
/// previous phase's natural end to the phase's defining event.
final List<FypJourneyPhase> fypJourneyPhases = [
  FypJourneyPhase('Orientation & Title Selection', DateTime(2026, 8, 3), DateTime(2026, 8, 31)),
  FypJourneyPhase('Supervisor Allocation & Proposal Writing', DateTime(2026, 9, 1), DateTime(2026, 10, 3)),
  FypJourneyPhase('Proposal Defense', DateTime(2026, 10, 4), DateTime(2026, 10, 10)),
  FypJourneyPhase('Dashain Holiday Break', DateTime(2026, 10, 11), DateTime(2026, 11, 16)),
  FypJourneyPhase('Literature Review', DateTime(2026, 11, 17), DateTime(2026, 12, 25)),
  FypJourneyPhase('Artefact Design & Test Plan', DateTime(2026, 12, 26), DateTime(2027, 1, 29)),
  FypJourneyPhase('Professionalism Report', DateTime(2027, 1, 30), DateTime(2027, 3, 5)),
  FypJourneyPhase('Draft Report & Advanced Artefact', DateTime(2027, 3, 6), DateTime(2027, 4, 9)),
  FypJourneyPhase('Internal Project Defense', DateTime(2027, 4, 10), DateTime(2027, 4, 23)),
  FypJourneyPhase('Final Report', DateTime(2027, 4, 24), DateTime(2027, 5, 18)),
  FypJourneyPhase('Poster Presentation / Viva', DateTime(2027, 5, 19), DateTime(2027, 5, 26)),
  FypJourneyPhase('Poster & Code', DateTime(2027, 5, 27), DateTime(2027, 5, 31)),
  FypJourneyPhase('Results', DateTime(2027, 6, 1), DateTime(2027, 6, 22)),
  FypJourneyPhase('Resit', DateTime(2027, 7, 1), DateTime(2027, 8, 3)),
];

/// Ordered journey nodes for the visualization (deduplicated timeline flow).
const List<String> fypJourneyNodes = [
  'Title',
  'Proposal',
  'Defense',
  'Literature Review',
  'Artefact',
  'Professionalism',
  'Draft Report',
  'Internal Defense',
  'Final Report',
  'Poster & Code',
  'Viva',
  'Results',
];

/// Result of a phase lookup.
class CurrentPhase {
  final String title;
  final DateTime start;
  final DateTime end;

  const CurrentPhase(this.title, this.start, this.end);

  /// 0.0 → 1.0 progress through this phase's window.
  double progressOn(DateTime now) {
    if (now.isBefore(start)) return 0;
    if (now.isAfter(end)) return 1;
    final total = end.difference(start).inMinutes;
    if (total <= 0) return 1;
    return now.difference(start).inMinutes / total;
  }

  /// Whole days from today until this phase ends.
  int get daysLeft {
    final n = DateTime.now();
    return DateTime(end.year, end.month, end.day)
        .difference(DateTime(n.year, n.month, n.day))
        .inDays;
  }
}

/// Returns the phase containing [date], or the nearest upcoming phase
/// (before the timeline / between windows), or null after the resit.
CurrentPhase? currentPhaseFor(DateTime date) {
  for (final p in fypJourneyPhases) {
    if (p.contains(date)) {
      return CurrentPhase(p.title, p.start, p.end);
    }
  }
  // Between windows or outside the timeline: next phase that hasn't started.
  for (final p in fypJourneyPhases) {
    if (date.isBefore(p.start)) {
      return CurrentPhase(p.title, p.start, p.end);
    }
  }
  return null; // after the resit window
}

/// Index of the current phase within [fypJourneyNodes] for the journey
/// visualization (best-effort mapping by title keywords).
int journeyNodeIndexFor(String phaseTitle) {
  final t = phaseTitle.toLowerCase();
  if (t.contains('orientation') || t.contains('title')) return 0;
  if (t.contains('supervisor') || t.contains('proposal writing')) return 1;
  if (t.contains('proposal defense')) return 2;
  if (t.contains('dashain')) return -1; // holiday: no journey node highlighted
  if (t.contains('literature')) return 3;
  if (t.contains('artefact')) return 4;
  if (t.contains('professionalism')) return 5;
  if (t.contains('draft')) return 6;
  if (t.contains('internal')) return 7;
  if (t.contains('final report')) return 8;
  if (t.contains('viva')) return 10;
  if (t.contains('poster & code')) return 9;
  if (t.contains('results')) return 11;
  if (t.contains('resit')) return 11;
  return 0;
}
