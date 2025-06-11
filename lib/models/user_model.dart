class UserModel {
  final String id;
  final String role; // 'student', 'teacher', or 'parent'
  final Map<String, dynamic> userData;
  final Map<String, dynamic>? additionalData; // For parent's student data, etc.

  UserModel({
    required this.id,
    required this.role,
    required this.userData,
    this.additionalData,
  });

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'userData': userData,
      'additionalData': additionalData,
    };
  }

  // Create from map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      role: map['role'],
      userData: Map<String, dynamic>.from(map['userData']),
      additionalData: map['additionalData'] != null 
          ? Map<String, dynamic>.from(map['additionalData']) 
          : null,
    );
  }
}
