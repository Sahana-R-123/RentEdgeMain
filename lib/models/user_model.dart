import 'dart:io';

class AppUser {
  final String registeredId;
  final String department;
  final String college;
  final String firstName;
  final String lastName;
  final String email;
  final File? profileImage;


  AppUser({
    required this.registeredId,
    required this.department,
    required this.college,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImage,
  });

  // Add a copyWith method for immutability
  AppUser copyWith({
    String? registeredId,
    String? department,
    String? college,
    String? firstName,
    String? lastName,
    String? email,
    File? profileImage,
  }) {
    return AppUser(
      registeredId: registeredId ?? this.registeredId,
      department: department ?? this.department,
      college: college ?? this.college,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  // Convert Firestore data into AppUser
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      registeredId: map['registeredId'] ?? '',
      department: map['department'] ?? '',
      college: map['college'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      // profileImage is not stored as a File in Firestore, so this stays null
      profileImage: null,
    );
  }

  // Optional: Convert AppUser to Map (for storing in Firestore)
  Map<String, dynamic> toMap() {
    return {
      'registeredId': registeredId,
      'department': department,
      'college': college,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      // You can store the profileImage URL here instead of the File object
    };
  }
}