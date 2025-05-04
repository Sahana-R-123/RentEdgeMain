class AppUser {
  final String id;
  final String registeredId;
  final String department;
  final String college;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImage;

  AppUser({
    required this.id,
    required this.registeredId,
    required this.department,
    required this.college,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImage,
  });

  // copyWith method
  AppUser copyWith({
    String? id,
    String? registeredId,
    String? department,
    String? college,
    String? firstName,
    String? lastName,
    String? email,
    String? profileImage,
  }) {
    return AppUser(
      id: id ?? this.id,
      registeredId: registeredId ?? this.registeredId,
      department: department ?? this.department,
      college: college ?? this.college,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  // fromMap factory constructor
  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      registeredId: map['registeredId'] ?? '',
      department: map['department'] ?? '',
      college: map['college'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImageUrl'],
    );
  }

  // toMap method
  Map<String, dynamic> toMap() {
    return {
      'registeredId': registeredId,
      'department': department,
      'college': college,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'profileImageUrl': profileImage,
    };
  }
}
