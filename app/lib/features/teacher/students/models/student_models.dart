class StudentSummary {
  const StudentSummary({
    required this.id,
    required this.name,
    this.standard,
    this.section,
  });

  final String id;
  final String name;
  final int? standard;
  final String? section;

  String get classLabel {
    if (standard == null || section == null) return '';
    return 'Class $standard$section';
  }

  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    return StudentSummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      standard: json['standard'] as int?,
      section: json['section'] as String?,
    );
  }
}

class StudentMarkRow {
  const StudentMarkRow({
    required this.id,
    required this.subjectName,
    this.marks,
    this.term,
    this.examType,
    this.grade,
    this.maxMarks,
  });

  final int id;
  final String subjectName;
  final dynamic marks;
  final int? term;
  final String? examType;
  final String? grade;
  final dynamic maxMarks;

  factory StudentMarkRow.fromJson(Map<String, dynamic> json) {
    return StudentMarkRow(
      id: json['id'] as int,
      subjectName: json['subject_name'] as String? ?? '',
      marks: json['marks'],
      term: json['term'] as int?,
      examType: json['exam_type'] as String?,
      grade: json['grade'] as String?,
      maxMarks: json['max_marks'],
    );
  }
}

class StudentAttendanceEntry {
  const StudentAttendanceEntry({
    required this.date,
    this.morning,
    this.afternoon,
    this.evening,
  });

  final String date;
  final dynamic morning;
  final dynamic afternoon;
  final dynamic evening;

  factory StudentAttendanceEntry.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceEntry(
      date: json['date'] as String? ?? '',
      morning: json['morning'],
      afternoon: json['afternoon'],
      evening: json['evening'],
    );
  }
}

class StudentHomeworkEntry {
  const StudentHomeworkEntry({
    required this.id,
    required this.subjectName,
    required this.date,
    required this.title,
    required this.description,
    required this.targetType,
    required this.isMine,
    this.studentId,
  });

  final int id;
  final String subjectName;
  final String date;
  final String title;
  final String description;
  final String targetType;
  final bool isMine;
  final String? studentId;

  factory StudentHomeworkEntry.fromJson(Map<String, dynamic> json) {
    return StudentHomeworkEntry(
      id: json['id'] as int,
      subjectName: json['subject_name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetType: json['target_type'] as String? ?? 'class',
      isMine: json['is_mine'] as bool? ?? false,
      studentId: json['student_id'] as String?,
    );
  }
}

class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.name,
    this.standard,
    this.section,
    this.email,
    this.phone,
    this.fatherName,
    this.motherName,
    this.dob,
    this.gender,
    this.bloodGroup,
    this.address,
  });

  final String id;
  final String name;
  final int? standard;
  final String? section;
  final String? email;
  final String? phone;
  final String? fatherName;
  final String? motherName;
  final String? dob;
  final String? gender;
  final String? bloodGroup;
  final String? address;

  String get classLabel {
    if (standard == null || section == null) return '';
    return 'Class $standard$section';
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      standard: json['standard'] as int?,
      section: json['section'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      fatherName: json['father_name'] as String?,
      motherName: json['mother_name'] as String?,
      dob: json['dob'] as String?,
      gender: json['gender'] as String?,
      bloodGroup: json['blood_group'] as String?,
      address: json['address'] as String?,
    );
  }
}

class StudentDossier {
  const StudentDossier({
    required this.profile,
    required this.marks,
    required this.attendance,
    required this.homework,
  });

  final StudentProfile profile;
  final List<StudentMarkRow> marks;
  final List<StudentAttendanceEntry> attendance;
  final List<StudentHomeworkEntry> homework;

  factory StudentDossier.fromJson(Map<String, dynamic> json) {
    return StudentDossier(
      profile: StudentProfile.fromJson(json['profile'] as Map<String, dynamic>),
      marks: (json['marks'] as List<dynamic>? ?? [])
          .map((e) => StudentMarkRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      attendance: (json['attendance'] as List<dynamic>? ?? [])
          .map((e) => StudentAttendanceEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      homework: (json['homework'] as List<dynamic>? ?? [])
          .map((e) => StudentHomeworkEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
