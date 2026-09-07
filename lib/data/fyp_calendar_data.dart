/// OFFICIAL Cohort 11 FYP calendar dataset.
///
/// Single source of truth for every official date, transcribed verbatim from
/// `FYP_Calendar_Cohort11_Context.md` (the transcription of
/// `FYP_Student_Calendar_-_Cohort_11.xlsx`). Do NOT invent dates here and do
/// NOT scatter official dates across UI files — everything flows from this
/// file. User state (completion flags, custom events, milestone progress) is
/// stored separately in [StorageService], leaving these definitions intact.
library;

import '../models/fyp_event.dart';
import '../models/milestone.dart';

// ── Official milestone IDs (used to link portal → deadline) ──────────────────

const kGate1 = 'gate-1-title-submission';
const kGate2 = 'gate-2-proposal';
const kMilestone2 = 'milestone-2-literature-review';
const kMilestone3 = 'milestone-3-artefact-test-plan';
const kMilestone4 = 'milestone-4-professionalism';
const kMilestone5 = 'milestone-5-draft-report';
const kMilestone6 = 'milestone-6-final-report';
const kMilestone7 = 'milestone-7-poster-code';
const kGate3 = 'gate-3-resit';

// ── Official milestones (source sheet Section 3) ─────────────────────────────

/// The 7 formally numbered milestones + 2 earlier gates + conditional resit.
/// All were colored YELLOW ("Deadline for submission") in the source sheet.
final List<Milestone> officialMilestones = [
  Milestone(
    id: kGate1,
    title: 'Gate 1 — Title Submission',
    description:
        'Submit the project title via Google Form. Supervisor is allocated '
        'based on the submitted title and announced the same day.',
    deadline: DateTime(2026, 8, 31),
    status: MilestoneStatus.notStarted,
    priority: FypPriorityLevel.critical,
    notes: 'For supervisor allocation purposes.',
  ),
  Milestone(
    id: kGate2,
    title: 'Gate 2 — Proposal Deadline',
    description:
        'Proposal must first be approved by the supervisor (Proposal '
        'Feedback Sheet) before submission via the PRF portal.',
    deadline: DateTime(2026, 9, 25),
    portalOpenDate: DateTime(2026, 9, 18),
    status: MilestoneStatus.notStarted,
    priority: FypPriorityLevel.critical,
    notes: 'Portal opens 9 working days prior.',
  ),
  Milestone(
    id: kMilestone2,
    title: 'Milestone 2 — Literature Review',
    description:
        'Literature Review submission with plagiarism ("plag") check.',
    deadline: DateTime(2026, 12, 25),
    portalOpenDate: DateTime(2026, 12, 14),
    status: MilestoneStatus.notStarted,
    priority: FypPriorityLevel.critical,
    notes: 'Portal opens 10 days prior — during the December non-teaching weeks.',
  ),
  Milestone(
    id: kMilestone3,
    title: 'Milestone 3 — Artefact Design and Test Plan',
    description: 'Submission of the artefact design document and test plan.',
    deadline: DateTime(2027, 1, 29),
    portalOpenDate: DateTime(2027, 1, 21),
    status: MilestoneStatus.notStarted,
    priority: FypPriorityLevel.critical,
    notes: 'Portal opens 10 days prior.',
  ),
  Milestone(
    id: kMilestone4,
    title: 'Milestone 4 — Professionalism Report Section',
    description: 'Submission of the professionalism section of the report '
        '(25% part of the report).',
    deadline: DateTime(2027, 3, 5),
    portalOpenDate: DateTime(2027, 2, 22),
    status: MilestoneStatus.notStarted,
    priority: FypPriorityLevel.critical,
    notes: 'Portal opens 10 days prior.',
  ),
  Milestone(
    id: kMilestone5,
    title: 'Milestone 5 — Draft Report + Advanced Artefact',
    description:
        'Submission of the draft report and the advanced version of the artefact.',
    deadline: DateTime(2027, 4, 9),
    portalOpenDate: DateTime(2027, 3, 30),
    status: MilestoneStatus.notStarted,
    priority: FypPriorityLevel.critical,
    notes: 'Portal opens 10 days prior.',
  ),
  Milestone(
    id: kMilestone6,
    title: 'Milestone 6 — Final Report Submission',
    description: 'Submission of the complete final report.',
    deadline: DateTime(2027, 5, 18),
    portalOpenDate: DateTime(2027, 5, 3),
    status: MilestoneStatus.notStarted,
    priority: FypPriorityLevel.critical,
    notes: 'Labeled "10 days prior" in the sheet though ~15 calendar days before.',
  ),
  Milestone(
    id: kMilestone7,
    title: 'Milestone 7 — Poster and Code Submission',
    description:
        'Submission of the final poster and project code, immediately after '
        'the Poster Presentation / Viva window begins.',
    deadline: DateTime(2027, 5, 27),
    status: MilestoneStatus.notStarted,
    priority: FypPriorityLevel.critical,
  ),
  Milestone(
    id: kGate3,
    title: 'Gate 3 — Resit Submission',
    description:
        'Resit submission — only applicable to students requiring a resit.',
    deadline: DateTime(2027, 7, 6),
    status: MilestoneStatus.notStarted,
    priority: FypPriorityLevel.high,
    isConditional: true,
    notes: 'Conditional milestone.',
  ),
];

// ── Official calendar events (source sheet Section 4) ────────────────────────

/// Every dated event in the official sheet, in chronological order.
/// Days not present here are free/unscheduled days in the official timeline.
final List<FypEvent> officialEvents = [
  // ── August 2026 ──────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2026-08-05-fyp-intro',
    date: DateTime(2026, 8, 5),
    title: 'FYP Intro',
    description: 'Introductory session for the Final Year Project.',
    category: FypEventCategory.session,
  ),
  FypEvent(
    id: 'ev-2026-08-06-form-session-select',
    date: DateTime(2026, 8, 6),
    title: 'Google Form Opens — Project-Specific Session Selection',
    description:
        'Google Form becomes available for selecting a project-specific session.',
    category: FypEventCategory.googleForm,
  ),
  FypEvent(
    id: 'ev-2026-08-10-workshop-lecture',
    date: DateTime(2026, 8, 10),
    title: 'Workshop / Lecture',
    category: FypEventCategory.session,
  ),
  FypEvent(
    id: 'ev-2026-08-10-form-closes',
    date: DateTime(2026, 8, 10),
    title: 'Google Form Closes — Project-Specific Session',
    description:
        'The Google Form for project-specific session selection closes on this day.',
    category: FypEventCategory.googleForm,
  ),
  FypEvent(
    id: 'ev-2026-08-12-workshop-lecture',
    date: DateTime(2026, 8, 12),
    title: 'Workshop / Lecture',
    category: FypEventCategory.session,
  ),
  FypEvent(
    id: 'ev-2026-08-17-lecture-workshop',
    date: DateTime(2026, 8, 17),
    title: 'Lecture / Workshop',
    category: FypEventCategory.session,
  ),
  FypEvent(
    id: 'ev-2026-08-19-showcase-workshop',
    date: DateTime(2026, 8, 19),
    title: 'FYP Showcase + Workshop / Lecture',
    category: FypEventCategory.session,
  ),
  FypEvent(
    id: 'ev-2026-08-24-proposal-prf-session',
    date: DateTime(2026, 8, 24),
    title: 'Session on Project Proposal + PRF / Workshop',
    category: FypEventCategory.session,
  ),
  FypEvent(
    id: 'ev-2026-08-24-form-title-open',
    date: DateTime(2026, 8, 24),
    title: 'Google Form Opens — Title Submission',
    description:
        'Google Form becomes available for submitting the project title.',
    category: FypEventCategory.googleForm,
    relatedMilestoneId: kGate1,
  ),
  FypEvent(
    id: 'ev-2026-08-25-proposal-prf-session',
    date: DateTime(2026, 8, 25),
    title: 'Session on Project Proposal + PRF / Workshop',
    category: FypEventCategory.session,
  ),
  FypEvent(
    id: 'ev-2026-08-31-title-submission',
    date: DateTime(2026, 8, 31),
    title: 'Title Submission (Google Form)',
    description:
        'DEADLINE — submit the project title via Google Form. Supervisor is '
        'allocated based on the submitted title; allocation is announced the '
        'same day.',
    category: FypEventCategory.deadline,
    priority: FypPriority.critical,
    deadlineDate: DateTime(2026, 8, 31),
    isImportant: true,
    relatedMilestoneId: kGate1,
  ),

  // ── September 2026 ───────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2026-09-01-supervisor-allocation',
    date: DateTime(2026, 9, 1),
    title: 'Supervisor Allocation + MST Creation',
    description:
        'Talk to the supervisor before writing the proposal. Before the '
        'proposal deadline the proposal must be approved by the supervisor '
        'via the Proposal Feedback Sheet — get feedback repeatedly until '
        'approved. Then fill the PRF (Project Registration Form) and submit '
        'it in the designated portal.',
    category: FypEventCategory.supervisor,
    isImportant: true,
  ),
  FypEvent(
    id: 'ev-2026-09-02-supervisor-allocation',
    date: DateTime(2026, 9, 2),
    title: 'Supervisor Allocation + MST Creation',
    category: FypEventCategory.supervisor,
  ),
  FypEvent(
    id: 'ev-2026-09-03-supervisor-allocation',
    date: DateTime(2026, 9, 3),
    title: 'Supervisor Allocation + MST Creation',
    category: FypEventCategory.supervisor,
  ),
  FypEvent(
    id: 'ev-2026-09-04-supervisor-reader',
    date: DateTime(2026, 9, 4),
    title: 'Session With Supervisor and Reader',
    category: FypEventCategory.supervisor,
  ),
  FypEvent(
    id: 'ev-2026-09-07-supervisor-session',
    date: DateTime(2026, 9, 7),
    title: 'Start of Supervisor Session',
    category: FypEventCategory.supervisor,
  ),
  FypEvent(
    id: 'ev-2026-09-14-supervisor-session',
    date: DateTime(2026, 9, 14),
    title: 'Start of Supervisor Session',
    category: FypEventCategory.supervisor,
  ),
  FypEvent(
    id: 'ev-2026-09-18-proposal-prf-portal',
    date: DateTime(2026, 9, 18),
    title: 'Portal Opens — Approved Proposal + PRF',
    description:
        'Portal for submission of the approved Proposal and PRF becomes '
        'available (9 working days prior to the proposal deadline).',
    category: FypEventCategory.portalOpening,
    portalOpenDate: DateTime(2026, 9, 18),
    relatedMilestoneId: kGate2,
  ),
  FypEvent(
    id: 'ev-2026-09-21-supervisor-session',
    date: DateTime(2026, 9, 21),
    title: 'Start of Supervisor Session',
    category: FypEventCategory.supervisor,
  ),
  FypEvent(
    id: 'ev-2026-09-25-proposal-deadline',
    date: DateTime(2026, 9, 25),
    title: 'Proposal Deadline',
    description:
        'DEADLINE — proposal submission. Must already be approved by the '
        'supervisor via the Proposal Feedback Sheet.',
    category: FypEventCategory.deadline,
    priority: FypPriority.critical,
    deadlineDate: DateTime(2026, 9, 25),
    isImportant: true,
    relatedMilestoneId: kGate2,
  ),
  FypEvent(
    id: 'ev-2026-09-27-level6-resumes',
    date: DateTime(2026, 9, 27),
    title: 'Rest of Level 6 Starts',
    description: 'Informational note: the rest of Level 6 also starts.',
    category: FypEventCategory.holiday,
  ),
  FypEvent(
    id: 'ev-2026-09-28-supervisor-session',
    date: DateTime(2026, 9, 28),
    title: 'Start of Supervisor Session',
    category: FypEventCategory.supervisor,
  ),

  // ── October 2026 ─────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2026-10-04-proposal-defense',
    date: DateTime(2026, 10, 4),
    title: 'Proposal Defense',
    description: 'Proposal Defense assessment (first day).',
    category: FypEventCategory.assessment,
    priority: FypPriority.high,
    isImportant: true,
  ),
  FypEvent(
    id: 'ev-2026-10-07-proposal-defense',
    date: DateTime(2026, 10, 7),
    title: 'Proposal Defense',
    description: 'Proposal Defense assessment (second day).',
    category: FypEventCategory.assessment,
    priority: FypPriority.high,
    isImportant: true,
  ),
  FypEvent(
    id: 'ev-2026-10-11-dashain-holiday',
    date: DateTime(2026, 10, 11),
    endDate: DateTime(2026, 11, 16),
    title: 'Dashain Holiday',
    description:
        'Continuous holiday / no-teaching period (~5.5 weeks) covering the '
        'Dashain–Tihar festival season. No sessions or deadlines inside the '
        'window — plan literature review work accordingly; the next major '
        'session is on 23 November.',
    category: FypEventCategory.holiday,
  ),

  // ── November 2026 ────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2026-11-23-lit-review-session',
    date: DateTime(2026, 11, 23),
    title: 'Session on Literature Review (Final Report Template)',
    category: FypEventCategory.session,
    relatedMilestoneId: kMilestone2,
  ),
  FypEvent(
    id: 'ev-2026-11-24-lit-review-session',
    date: DateTime(2026, 11, 24),
    title: 'Session on Literature Review (Final Report Template)',
    category: FypEventCategory.session,
    relatedMilestoneId: kMilestone2,
  ),

  // ── December 2026 ────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2026-12-14-milestone2-portal',
    date: DateTime(2026, 12, 14),
    title: 'Portal Opens — Literature Review (Milestone 2)',
    description:
        'Portal for the Literature Review submission becomes available '
        '(10 days prior to the deadline). Falls inside the December '
        'non-teaching weeks — the deadline still applies.',
    category: FypEventCategory.portalOpening,
    portalOpenDate: DateTime(2026, 12, 14),
    relatedMilestoneId: kMilestone2,
  ),
  FypEvent(
    id: 'ev-2026-12-25-milestone2-deadline',
    date: DateTime(2026, 12, 25),
    title: 'Milestone 2 — Literature Review (Plag Check)',
    description:
        'DEADLINE — Literature Review submission including the plagiarism check.',
    category: FypEventCategory.deadline,
    priority: FypPriority.critical,
    deadlineDate: DateTime(2026, 12, 25),
    isImportant: true,
    relatedMilestoneId: kMilestone2,
  ),
  FypEvent(
    id: 'ev-2026-12-28-artefact-session',
    date: DateTime(2026, 12, 28),
    title: 'Session on Artefact Design',
    category: FypEventCategory.session,
    relatedMilestoneId: kMilestone3,
  ),
  FypEvent(
    id: 'ev-2026-12-29-artefact-session',
    date: DateTime(2026, 12, 29),
    title: 'Session on Artefact Design',
    category: FypEventCategory.session,
    relatedMilestoneId: kMilestone3,
  ),

  // ── January 2027 ─────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2027-01-21-milestone3-portal',
    date: DateTime(2027, 1, 21),
    title: 'Portal Opens — Artefact Design and Test Plan (Milestone 3)',
    description:
        'Portal for the Artefact Design and Test Plan submission becomes '
        'available (10 days prior to the deadline).',
    category: FypEventCategory.portalOpening,
    portalOpenDate: DateTime(2027, 1, 21),
    relatedMilestoneId: kMilestone3,
  ),
  FypEvent(
    id: 'ev-2027-01-29-milestone3-deadline',
    date: DateTime(2027, 1, 29),
    title: 'Milestone 3 — Artefact Design and Test Plan',
    description:
        'DEADLINE — submission of the Artefact Design and Test Plan.',
    category: FypEventCategory.deadline,
    priority: FypPriority.critical,
    deadlineDate: DateTime(2027, 1, 29),
    isImportant: true,
    relatedMilestoneId: kMilestone3,
  ),

  // ── February 2027 ────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2027-02-01-professionalism-session',
    date: DateTime(2027, 2, 1),
    title: 'Session on Professionalism Report (25% Part)',
    category: FypEventCategory.session,
    relatedMilestoneId: kMilestone4,
  ),
  FypEvent(
    id: 'ev-2027-02-22-milestone4-portal',
    date: DateTime(2027, 2, 22),
    title: 'Portal Opens — Professionalism Report (Milestone 4)',
    description:
        'Portal for the Professionalism report submission becomes available '
        '(10 days prior to the deadline).',
    category: FypEventCategory.portalOpening,
    portalOpenDate: DateTime(2027, 2, 22),
    relatedMilestoneId: kMilestone4,
  ),

  // ── March 2027 ───────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2027-03-05-milestone4-deadline',
    date: DateTime(2027, 3, 5),
    title: 'Milestone 4 — Professionalism Section of the Report',
    description:
        'DEADLINE — submission of the professionalism section of the report.',
    category: FypEventCategory.deadline,
    priority: FypPriority.critical,
    deadlineDate: DateTime(2027, 3, 5),
    isImportant: true,
    relatedMilestoneId: kMilestone4,
  ),
  FypEvent(
    id: 'ev-2027-03-08-final-report-session',
    date: DateTime(2027, 3, 8),
    title: 'Session on Final Report',
    category: FypEventCategory.session,
    relatedMilestoneId: kMilestone6,
  ),
  FypEvent(
    id: 'ev-2027-03-30-milestone5-portal',
    date: DateTime(2027, 3, 30),
    title: 'Portal Opens — Draft Report (Milestone 5)',
    description:
        'Portal for the draft report submission becomes available '
        '(10 days prior to the deadline).',
    category: FypEventCategory.portalOpening,
    portalOpenDate: DateTime(2027, 3, 30),
    relatedMilestoneId: kMilestone5,
  ),

  // ── April 2027 ───────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2027-04-09-milestone5-deadline',
    date: DateTime(2027, 4, 9),
    title: 'Milestone 5 — Draft Report + Advanced Artefact',
    description:
        'DEADLINE — submission of the draft report and the advanced version '
        'of the artefact.',
    category: FypEventCategory.deadline,
    priority: FypPriority.critical,
    deadlineDate: DateTime(2027, 4, 9),
    isImportant: true,
    relatedMilestoneId: kMilestone5,
  ),
  FypEvent(
    id: 'ev-2027-04-11-poster-session',
    date: DateTime(2027, 4, 11),
    title: 'Session on Poster Presentation',
    category: FypEventCategory.session,
  ),
  FypEvent(
    id: 'ev-2027-04-12-poster-session',
    date: DateTime(2027, 4, 12),
    title: 'Session on Poster Presentation',
    category: FypEventCategory.session,
  ),
  FypEvent(
    id: 'ev-2027-04-18-internal-defense',
    date: DateTime(2027, 4, 18),
    endDate: DateTime(2027, 4, 23),
    title: 'Internal Project Defense',
    description:
        'Assessment period (6 days). Requirement: the project should be at '
        'least 75% complete by this point.',
    category: FypEventCategory.assessment,
    priority: FypPriority.high,
    isImportant: true,
  ),

  // ── May 2027 ─────────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2027-05-03-milestone6-portal',
    date: DateTime(2027, 5, 3),
    title: 'Portal Opens — Final Report (Milestone 6)',
    description:
        'Portal for the final report submission becomes available '
        '(labeled "10 days prior" in the sheet).',
    category: FypEventCategory.portalOpening,
    portalOpenDate: DateTime(2027, 5, 3),
    relatedMilestoneId: kMilestone6,
  ),
  FypEvent(
    id: 'ev-2027-05-18-milestone6-deadline',
    date: DateTime(2027, 5, 18),
    title: 'Milestone 6 — Final Report Submission',
    description: 'DEADLINE — final report submission.',
    category: FypEventCategory.deadline,
    priority: FypPriority.critical,
    deadlineDate: DateTime(2027, 5, 18),
    isImportant: true,
    relatedMilestoneId: kMilestone6,
  ),
  FypEvent(
    id: 'ev-2027-05-19-poster-viva',
    date: DateTime(2027, 5, 19),
    endDate: DateTime(2027, 5, 26),
    title: 'Poster Presentation / Viva',
    description:
        'Assessment period (8 days, Wed–Wed). Present the poster and defend '
        'the project in the viva.',
    category: FypEventCategory.assessment,
    priority: FypPriority.high,
    isImportant: true,
  ),
  FypEvent(
    id: 'ev-2027-05-27-milestone7-deadline',
    date: DateTime(2027, 5, 27),
    title: 'Milestone 7 — Poster and Code Submission',
    description:
        'DEADLINE — poster and code submission, immediately after the viva '
        'window begins.',
    category: FypEventCategory.deadline,
    priority: FypPriority.critical,
    deadlineDate: DateTime(2027, 5, 27),
    isImportant: true,
    relatedMilestoneId: kMilestone7,
  ),

  // ── June 2027 ────────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2027-06-22-board-result',
    date: DateTime(2027, 6, 22),
    title: 'Board — Approximate Result Publication',
    description: 'Approximate date of the FYP board result publication.',
    category: FypEventCategory.board,
    priority: FypPriority.high,
    isImportant: true,
  ),

  // ── July 2027 ────────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2027-07-06-resit-submission',
    date: DateTime(2027, 7, 6),
    title: 'Resit Submission',
    description:
        'DEADLINE — resit submission. Only applicable to students who '
        'require a resit.',
    category: FypEventCategory.deadline,
    priority: FypPriority.critical,
    deadlineDate: DateTime(2027, 7, 6),
    isImportant: true,
    isConditional: true,
    relatedMilestoneId: kGate3,
  ),
  FypEvent(
    id: 'ev-2027-07-07-resit-poster-viva',
    date: DateTime(2027, 7, 7),
    endDate: DateTime(2027, 7, 9),
    title: 'Poster Presentation / Viva (Resit)',
    description:
        'Resit assessment period (3 days). Only applicable to students '
        'taking the resit.',
    category: FypEventCategory.assessment,
    priority: FypPriority.high,
    isConditional: true,
  ),

  // ── August 2027 ──────────────────────────────────────────────────────────
  FypEvent(
    id: 'ev-2027-08-03-resit-result',
    date: DateTime(2027, 8, 3),
    title: 'Board — Approximate Result Publication (Resit)',
    description: 'Approximate date of the resit board result publication.',
    category: FypEventCategory.board,
    priority: FypPriority.high,
  ),

  // No further events are recorded through 2027-09-12 (timeline tail).
];

/// Convenience accessors over the official dataset.
class FypCalendarData {
  FypCalendarData._();

  /// All official events (already chronological).
  static List<FypEvent> get events => officialEvents;

  /// All official milestones.
  static List<Milestone> get milestones => officialMilestones;

  /// Milestone by id, or null.
  static Milestone? milestoneById(String id) =>
      officialMilestones.where((m) => m.id == id).firstOrNull;

  /// Portal-opening event linked to [milestoneId], or null.
  static FypEvent? portalEventFor(String milestoneId) => officialEvents
      .where((e) =>
          e.category == FypEventCategory.portalOpening &&
          e.relatedMilestoneId == milestoneId)
      .firstOrNull;
}
