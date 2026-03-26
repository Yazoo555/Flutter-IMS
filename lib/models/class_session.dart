class ClassSession {
  final String id;
  final String day; // 'Sunday', 'Monday', etc.
  final String startTime; // '09:30 AM'
  final String endTime; // '12:00 PM'
  final String subject;
  final String type; // Lecture, Workshop, Tutorial
  final String room;
  final String lecturer;

  ClassSession({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.type,
    required this.room,
    required this.lecturer,
  });

  ClassSession copyWith({
    String? id,
    String? day,
    String? startTime,
    String? endTime,
    String? subject,
    String? type,
    String? room,
    String? lecturer,
  }) {
    return ClassSession(
      id: id ?? this.id,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      room: room ?? this.room,
      lecturer: lecturer ?? this.lecturer,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'startTime': startTime,
    'endTime': endTime,
    'subject': subject,
    'type': type,
    'room': room,
    'lecturer': lecturer,
  };

  factory ClassSession.fromJson(Map<String, dynamic> json) => ClassSession(
    id: json['id'],
    day: json['day'],
    startTime: json['startTime'],
    endTime: json['endTime'],
    subject: json['subject'],
    type: json['type'],
    room: json['room'],
    lecturer: json['lecturer'],
  );
}

// Pre-loaded routine data from the screenshot
final List<ClassSession> defaultRoutine = [
  ClassSession(
    id: '1',
    day: 'Sunday',
    startTime: '09:30 AM',
    endTime: '12:00 PM',
    subject: 'Cloud Systems',
    type: 'Workshop',
    room: 'Lab-05 (HCK Block)',
    lecturer: 'Ms. Jenny Rajak',
  ),
  ClassSession(
    id: '2',
    day: 'Sunday',
    startTime: '01:00 PM',
    endTime: '03:30 PM',
    subject: 'Collaborative Development',
    type: 'Workshop',
    room: 'TR-03 (WLV Block)',
    lecturer: 'Ms. Nerisha Shrestha',
  ),
  ClassSession(
    id: '3',
    day: 'Monday',
    startTime: '09:00 AM',
    endTime: '11:30 AM',
    subject: 'Algorithms and Concurrency',
    type: 'Workshop',
    room: 'TR-27 (ING Block)',
    lecturer: 'Mr. Amrit Pun',
  ),
  ClassSession(
    id: '4',
    day: 'Tuesday',
    startTime: '07:00 AM',
    endTime: '09:00 AM',
    subject: 'Collaborative Development',
    type: 'Lecture',
    room: 'LT-02 (WLV Block)',
    lecturer: 'Mr. Bhanu Aryal',
  ),
  ClassSession(
    id: '5',
    day: 'Tuesday',
    startTime: '10:00 AM',
    endTime: '12:00 PM',
    subject: 'Algorithms and Concurrency',
    type: 'Lecture',
    room: 'LT-03 (WLV Block)',
    lecturer: 'Mr. Uttam Acharya',
  ),
  ClassSession(
    id: '6',
    day: 'Wednesday',
    startTime: '10:00 AM',
    endTime: '12:00 PM',
    subject: 'Cloud Systems',
    type: 'Lecture',
    room: 'LT-02 (WLV Block)',
    lecturer: 'Ms. Jenny Rajak',
  ),
  ClassSession(
    id: '7',
    day: 'Wednesday',
    startTime: '01:00 PM',
    endTime: '03:00 PM',
    subject: 'Algorithms and Concurrency',
    type: 'Tutorial',
    room: 'TR-20 (ING Block)',
    lecturer: 'Mr. Amrit Pun',
  ),
  ClassSession(
    id: '8',
    day: 'Thursday',
    startTime: '12:30 PM',
    endTime: '02:30 PM',
    subject: 'Collaborative Development',
    type: 'Tutorial',
    room: 'Lab-05 (HCK Block)',
    lecturer: 'Ms. Nerisha Shrestha',
  ),
  ClassSession(
    id: '9',
    day: 'Friday',
    startTime: '09:00 AM',
    endTime: '11:00 AM',
    subject: 'Cloud Systems',
    type: 'Tutorial',
    room: 'TR-29 (ING Block)',
    lecturer: 'Ms. Jenny Rajak',
  ),
];

const List<String> weekDays = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const List<String> subjectOptions = [
  'Cloud Systems',
  'Collaborative Development',
  'Algorithms and Concurrency',
];

const List<String> typeOptions = ['Lecture', 'Workshop', 'Tutorial', 'Lab'];
