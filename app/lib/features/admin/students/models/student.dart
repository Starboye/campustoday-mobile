class Student {
  const Student({
    required this.id,
    required this.name,
    required this.admissionNo,
    required this.className,
    required this.email,
    required this.phone,
    required this.status,
  });

  final String id;
  final String name;
  final String admissionNo;
  final String className;
  final String email;
  final String phone;
  final String status;

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: '${json['id']}',
      name: json['name']?.toString() ?? '',
      admissionNo: json['admission_no']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'admission_no': admissionNo,
        'class_name': className,
        'email': email,
        'phone': phone,
        'status': status,
      };
}
