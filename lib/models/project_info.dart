/// Static project metadata the student can edit in Settings (Project
/// section). Stored locally, used for context and the data export.
library;

class ProjectInfo {
  final String title;
  final String description;
  final String studentName;
  final String supervisorName;
  final String readerName;
  final String teamMembers;

  const ProjectInfo({
    this.title = '',
    this.description = '',
    this.studentName = '',
    this.supervisorName = '',
    this.readerName = '',
    this.teamMembers = '',
  });

  ProjectInfo copyWith({
    String? title,
    String? description,
    String? studentName,
    String? supervisorName,
    String? readerName,
    String? teamMembers,
  }) {
    return ProjectInfo(
      title: title ?? this.title,
      description: description ?? this.description,
      studentName: studentName ?? this.studentName,
      supervisorName: supervisorName ?? this.supervisorName,
      readerName: readerName ?? this.readerName,
      teamMembers: teamMembers ?? this.teamMembers,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'studentName': studentName,
        'supervisorName': supervisorName,
        'readerName': readerName,
        'teamMembers': teamMembers,
      };

  factory ProjectInfo.fromJson(Map<String, dynamic> json) => ProjectInfo(
        title: (json['title'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        studentName: (json['studentName'] ?? '') as String,
        supervisorName: (json['supervisorName'] ?? '') as String,
        readerName: (json['readerName'] ?? '') as String,
        teamMembers: (json['teamMembers'] ?? '') as String,
      );
}
