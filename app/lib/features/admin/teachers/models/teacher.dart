class Teacher {
  const Teacher({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.subjects,
    required this.email,
    required this.phone,
    required this.status,
  });

  final String id;
  final String name;
  final String employeeId;
  final String subjects;
  final String email;
  final String phone;
  final String status;

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: '${json['id']}',
      name: json['name']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      subjects: json['subjects']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
    );
  }
}
