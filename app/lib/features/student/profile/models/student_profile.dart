class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.name,
    required this.access,
    this.standard,
    this.section,
    this.displayName,
  });

  final String id;
  final String name;
  final int access;
  final int? standard;
  final String? section;
  final String? displayName;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;

    return StudentProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      access: json['access'] as int,
      standard: profile?['standard'] as int?,
      section: profile?['section'] as String?,
      displayName: profile?['name'] as String?,
    );
  }

  String get classLabel {
    if (standard != null && section != null) {
      return 'Class $standard-$section';
    }
    return '';
  }
}
