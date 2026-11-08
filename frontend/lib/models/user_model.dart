class UserModel {
  final int    id;
  final String username;
  final String firstName;
  final String lastName;
  final String role;        // 'STUDENT' | 'OBSERVER'
  final String schoolGrade;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.schoolGrade,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isStudent  => role == 'STUDENT';
  bool get isObserver => role == 'OBSERVER';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:          json['id']           as int,
      username:    json['username']     as String,
      firstName:   json['first_name']   as String? ?? '',
      lastName:    json['last_name']    as String? ?? '',
      role:        json['role']         as String,
      schoolGrade: json['school_grade'] as String? ?? '',
      createdAt:   json['created_at']   as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id':           id,
    'username':     username,
    'first_name':   firstName,
    'last_name':    lastName,
    'role':         role,
    'school_grade': schoolGrade,
    'created_at':   createdAt,
  };
}
