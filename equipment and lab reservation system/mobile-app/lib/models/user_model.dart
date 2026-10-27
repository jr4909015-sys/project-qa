class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.role = 'student',
    this.studentEmployeeId = '',
    this.department = '',
    this.contactNumber = '',
    this.photo,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String studentEmployeeId;
  final String department;
  final String contactNumber;
  final String? photo;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as int,
    username: json['username'] as String? ?? '',
    email: json['email'] as String? ?? '',
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    role: json['role'] as String? ?? json['role_name'] as String? ?? 'student',
    studentEmployeeId: json['student_employee_id'] as String? ?? '',
    department: json['department'] as String? ?? '',
    contactNumber: json['contact_number'] as String? ?? '',
    photo: json['photo'] as String?,
  );
}
