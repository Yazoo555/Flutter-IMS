import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/data/fyp_calendar_data.dart';
import 'package:flutter_application_1/data/fyp_phase_logic.dart';
import 'package:flutter_application_1/data/fyp_warnings.dart';
import 'package:flutter_application_1/data/deadline_health.dart';
import 'package:flutter_application_1/models/fyp_event.dart';
import 'package:flutter_application_1/models/fyp_task.dart';
import 'package:flutter_application_1/models/meeting.dart' as m;
import 'package:flutter_application_1/models/milestone.dart';
import 'package:flutter_application_1/services/fyp_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App renders without crash', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FypCalendarApp());
    await tester.pumpAndSettle();
    // Smoke test - the FYP Calendar shell should render without errors.
    expect(find.text('FYP Calendar'), findsWidgets);
  });

  test('FYP timeline constants are consistent', () {
    // The Cohort 11 timeline runs 3 Aug 2026 → 12 Sep 2027 (406 days).
    expect(fypTotalWeeks, 50);
    expect(fypTimelineStart, DateTime(2026, 8, 3));
    expect(fypTimelineEnd, DateTime(2027, 9, 12));
  });

  group('Official week structure', () {
    test('Week 1 is the first week of August 2026', () {
      expect(officialWeekNumber(DateTime(2026, 8, 3)), 1);
      expect(weekLabelOf(DateTime(2026, 8, 5)), 'Week 1');
    });

    test('Dashain weeks carry special labels, not numbers', () {
      expect(weekLabelOf(DateTime(2026, 10, 14)), 'Dashain Holiday');
      expect(officialWeekNumber(DateTime(2026, 10, 14)), isNull);
    });

    test('December non-teaching weeks carry special labels', () {
      expect(weekLabelOf(DateTime(2026, 12, 16)), 'Non Teaching Week');
      expect(weekLabelOf(DateTime(2026, 12, 21)), 'Non Teaching Week');
    });

    test('Teaching resumes with Week 12 on 23 Nov 2026', () {
      expect(weekLabelOf(DateTime(2026, 11, 23)), 'Week 12');
    });

    test('Last numbered week is Week 50', () {
      expect(weekLabelOf(DateTime(2027, 9, 6)), 'Week 50');
      expect(weekLabelOf(fypTimelineEnd), 'Week 50');
    });
  });

  group('Official Cohort 11 dataset', () {
    test('contains the official gates and milestones', () {
      expect(officialMilestones.length, 9);
      expect(
        officialMilestones.map((m) => m.deadline),
        containsAll([
          DateTime(2026, 8, 31), // Gate 1 — Title Submission
          DateTime(2026, 9, 25), // Gate 2 — Proposal
          DateTime(2026, 12, 25), // Milestone 2 — Literature Review
          DateTime(2027, 5, 18), // Milestone 6 — Final Report
          DateTime(2027, 7, 6), // Gate 3 — Resit
        ]),
      );
    });

    test('milestones with portals open ~10 days before deadline', () {
      for (final m in officialMilestones) {
        if (m.portalOpenDate != null) {
          final gap = m.deadline.difference(m.portalOpenDate!).inDays;
          // Gate 2 is stated as "9 working days" (7 calendar days);
          // the rest are explicitly ~10 calendar days.
          expect(gap, inInclusiveRange(7, 15),
              reason: '${m.title} portal gap should be ~10 days');
        }
      }
    });

    test('every deadline event has a real date within the timeline', () {
      for (final e in officialEvents) {
        expect(e.date.isBefore(fypTimelineStart), isFalse,
            reason: '${e.title} starts before the timeline');
        expect(e.date.isAfter(fypTimelineEnd), isFalse,
            reason: '${e.title} ends after the timeline');
      }
    });

    test('Dashain holiday spans 11 Oct – 16 Nov 2026', () {
      final dashain = officialEvents
          .where((e) => e.title.contains('Dashain'))
          .toList();
      expect(dashain, hasLength(1));
      expect(dashain.first.date, DateTime(2026, 10, 11));
      expect(dashain.first.endDate, DateTime(2026, 11, 16));
    });

    test('portal events link to their milestone', () {
      final m2 = FypCalendarData.milestoneById(kMilestone2);
      expect(m2, isNotNull);
      final portal = FypCalendarData.portalEventFor(kMilestone2);
      expect(portal, isNotNull);
      expect(portal!.date, DateTime(2026, 12, 14));
    });
  });

  group('FYP phase logic', () {
    test('derives phase from official windows', () {
      expect(currentPhaseFor(DateTime(2026, 8, 5))!.title,
          'Orientation & Title Selection');
      expect(currentPhaseFor(DateTime(2026, 9, 10))!.title,
          'Supervisor Allocation & Proposal Writing');
      expect(currentPhaseFor(DateTime(2026, 10, 5))!.title,
          'Proposal Defense');
      expect(currentPhaseFor(DateTime(2026, 10, 20))!.title,
          'Dashain Holiday Break');
      expect(currentPhaseFor(DateTime(2026, 12, 10))!.title,
          'Literature Review');
      expect(currentPhaseFor(DateTime(2027, 4, 20))!.title,
          'Internal Project Defense');
      expect(currentPhaseFor(DateTime(2027, 5, 20))!.title,
          'Poster Presentation / Viva');
    });

    test('returns first phase before the timeline', () {
      expect(currentPhaseFor(DateTime(2026, 1, 1))!.title,
          'Orientation & Title Selection');
    });

    test('returns null after the resit window', () {
      expect(currentPhaseFor(DateTime(2027, 12, 1)), isNull);
    });

    test('journey node mapping is stable', () {
      expect(journeyNodeIndexFor('Literature Review'), 3);
      expect(journeyNodeIndexFor('Proposal Defense'), 2);
      expect(journeyNodeIndexFor('Results'), 11);
    });
  });

  group('FYP warnings', () {
    test('proposal approval warning shows during proposal window', () {
      final ids = relevantWarningsOn(DateTime(2026, 9, 10))
          .map((w) => w.id)
          .toList();
      expect(ids, contains('proposal-approval'));
    });

    test('Dashain gap warning shows after proposal defense', () {
      final ids = relevantWarningsOn(DateTime(2026, 10, 20))
          .map((w) => w.id)
          .toList();
      expect(ids, contains('dashain-gap'));
    });

    test('defense readiness warning shows near internal defense', () {
      final ids = relevantWarningsOn(DateTime(2027, 4, 1))
          .map((w) => w.id)
          .toList();
      expect(ids, contains('defense-75'));
    });

    test('dashboard warnings are capped for a clean UI', () {
      expect(relevantWarningsOn(DateTime(2026, 9, 10)).length, lessThanOrEqualTo(2));
    });
  });

  group('Checklist + milestone persistence', () {
    test('checklist items can be added, toggled and deleted', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = FypRepository();

      await repo.addChecklistItem(kGate2, 'Discuss title with supervisor');
      await repo.addChecklistItem(kGate2, 'Draft proposal');

      var items = await repo.loadChecklistItems();
      expect(items.where((i) => i.milestoneId == kGate2).length, 2);

      await repo.toggleChecklistItem(items.first);
      items = await repo.loadChecklistItems();
      expect(items.first.done, isTrue);

      await repo.deleteChecklistItem(items.first);
      items = await repo.loadChecklistItems();
      expect(items.length, 1);
    });

    test('milestone status persists and feeds stats', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = FypRepository();

      var (done, total, pct) = await repo.milestoneStats();
      expect(total, 9);
      expect(done, 0);
      expect(pct, 0);

      await repo.saveMilestoneProgress(
        kGate1,
        status: MilestoneStatus.submitted,
        percentageComplete: 1.0,
      );

      (done, total, pct) = await repo.milestoneStats();
      expect(done, 1);
      expect(pct, closeTo(1 / 9, 0.001));

      final milestones = await repo.loadMilestones();
      expect(
        milestones.firstWhere((m) => m.id == kGate1).status,
        MilestoneStatus.submitted,
      );
    });
  });

  group('Tasks + meetings + progress', () {
    test('tasks persist and open-task counts link to milestones', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = FypRepository();

      await repo.addTask(FypTask(
        id: 't1',
        title: 'Complete literature review draft',
        relatedMilestoneId: kMilestone2,
        category: TaskCategory.literatureReview,
        priority: TaskPriority.critical,
      ));
      await repo.addTask(FypTask(
        id: 't2',
        title: 'Run plag check',
        relatedMilestoneId: kMilestone2,
        status: TaskStatus.done,
        completed: true,
      ));

      expect(await repo.openTaskCountForMilestone(kMilestone2), 1);

      final tasks = await repo.loadTasks();
      expect(tasks.length, 2);
      expect(tasks.first.category, TaskCategory.literatureReview);
    });

    test('meetings persist with types', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = FypRepository();

      await repo.addMeeting(m.Meeting(
        id: 'meet1',
        title: 'Proposal feedback round 1',
        date: DateTime(2026, 9, 10),
        timeMinutes: 14 * 60 + 30,
        type: m.MeetingType.supervisor,
      ));

      final meetings = await repo.loadMeetings();
      expect(meetings.length, 1);
      expect(meetings.first.type.label, 'Supervisor Meeting');
      expect(meetings.first.timeLabel, '14:30');
    });

    test('self-reported progress persists with defense status', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = FypRepository();

      var p = await repo.loadProjectProgress();
      expect(p.overallPercent, 0);
      expect(p.defenseStatus().label, 'Below target');

      p = p.copyWith(overallPercent: 75);
      await repo.saveProjectProgress(p);

      final loaded = await repo.loadProjectProgress();
      expect(loaded.overallPercent, 75);
      expect(loaded.defenseStatus().label, 'On target');

      final above = loaded.copyWith(overallPercent: 80);
      expect(above.defenseStatus().label, 'Above target');
    });

    test('taskStats counts done and overdue tasks', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = FypRepository();

      await repo.addTask(FypTask(
        id: 's1',
        title: 'Overdue item',
        dueDate: DateTime(2020, 1, 1),
      ));
      await repo.addTask(FypTask(
        id: 's2',
        title: 'Finished item',
        status: TaskStatus.done,
        completed: true,
      ));

      final (done, total, overdue) = await repo.taskStats();
      expect(done, 1);
      expect(total, 2);
      expect(overdue, 1);
    });
  });

  group('Deadline health', () {
    FypEvent ev(DateTime d, FypEventCategory c) => FypEvent(
          id: 'h-${d.millisecondsSinceEpoch}-$c',
          date: d,
          title: 'health test event',
          category: c,
        );

    test('overdue critical deadline → Overdue', () {
      final health = computeDeadlineHealth([
        ev(DateTime(2020, 1, 1), FypEventCategory.deadline),
      ]);
      expect(health.status, DeadlineHealthStatus.overdue);
      expect(health.overdueCount, 1);
    });

    test('overdue non-critical event → Needs Attention', () {
      final health = computeDeadlineHealth([
        ev(DateTime(2020, 1, 1), FypEventCategory.assessment),
      ]);
      expect(health.status, DeadlineHealthStatus.needsAttention);
    });

    test('everything ahead and done → On Track', () {
      final doneSession =
          ev(DateTime(2020, 1, 1), FypEventCategory.session)
              .copyWith(isCompleted: true);
      final health = computeDeadlineHealth([
        ev(DateTime(2030, 1, 1), FypEventCategory.deadline),
        doneSession,
      ]);
      expect(health.status, DeadlineHealthStatus.onTrack);
      expect(health.upcomingCount, 1);
      expect(health.completedCount, 1);
    });
  });

  group('Official data integrity audit', () {
    FypEvent? on(DateTime d, FypEventCategory c) => officialEvents
        .where((e) => e.date == d && e.category == c)
        .firstOrNull;

    test('all headline dates match the Cohort 11 source', () {
      // Gates and milestone deadlines.
      expect(on(DateTime(2026, 8, 31), FypEventCategory.deadline), isNotNull,
          reason: 'Gate 1 — Title Submission');
      expect(on(DateTime(2026, 9, 25), FypEventCategory.deadline), isNotNull,
          reason: 'Gate 2 — Proposal deadline');
      expect(on(DateTime(2026, 12, 25), FypEventCategory.deadline), isNotNull,
          reason: 'Milestone 2 — Literature Review');
      expect(on(DateTime(2027, 1, 29), FypEventCategory.deadline), isNotNull,
          reason: 'Milestone 3 — Artefact Design and Test Plan');
      expect(on(DateTime(2027, 3, 5), FypEventCategory.deadline), isNotNull,
          reason: 'Milestone 4 — Professionalism section');
      expect(on(DateTime(2027, 4, 9), FypEventCategory.deadline), isNotNull,
          reason: 'Milestone 5 — Draft report');
      expect(on(DateTime(2027, 5, 18), FypEventCategory.deadline), isNotNull,
          reason: 'Milestone 6 — Final Report');
      expect(on(DateTime(2027, 5, 27), FypEventCategory.deadline), isNotNull,
          reason: 'Milestone 7 — Poster and Code');
      expect(on(DateTime(2027, 7, 6), FypEventCategory.deadline), isNotNull,
          reason: 'Gate 3 — Resit Submission');
    });

    test('assessment and board windows match the source', () {
      final defense = on(DateTime(2027, 4, 18), FypEventCategory.assessment);
      expect(defense, isNotNull, reason: 'Internal Project Defense start');
      expect(defense!.endDate, DateTime(2027, 4, 23));

      final viva = on(DateTime(2027, 5, 19), FypEventCategory.assessment);
      expect(viva, isNotNull, reason: 'Poster Presentation / Viva start');
      expect(viva!.endDate, DateTime(2027, 5, 26));

      final resitViva = on(DateTime(2027, 7, 7), FypEventCategory.assessment);
      expect(resitViva, isNotNull, reason: 'Resit viva start');
      expect(resitViva!.endDate, DateTime(2027, 7, 9));

      expect(on(DateTime(2027, 6, 22), FypEventCategory.board), isNotNull,
          reason: 'Board — approximate results');
      expect(on(DateTime(2027, 8, 3), FypEventCategory.board), isNotNull,
          reason: 'Resit results');
    });

    test('resit gate is flagged conditional', () {
      final resit = on(DateTime(2027, 7, 6), FypEventCategory.deadline);
      expect(resit, isNotNull);
      expect(resit!.isConditional, isTrue);
    });
  });
}
