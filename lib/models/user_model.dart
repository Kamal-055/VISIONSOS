class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
  });

  factory UserModel.fromJson(String uid, Map<dynamic, dynamic> json) {
    return UserModel(
      uid: uid,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      createdAt: (json['createdAt'] ?? json['registeredAt'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'createdAt': createdAt,
      'registeredAt': createdAt,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? createdAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
