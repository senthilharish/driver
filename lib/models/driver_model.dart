class DriverModel {
  final String uid;
  final String drivername;
  final String phone;
  final String email;
  final String password;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  DriverModel({
    required this.uid,
    required this.drivername,
    required this.phone,
    required this.email,
    required this.password,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'drivername': drivername,
      'phone': phone,
      'email': email,
      'password': password,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      uid: json['uid'] ?? '',
      drivername: json['drivername'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      latitude: json['latitude'] != null ? json['latitude'] as double : null,
      longitude: json['longitude'] != null ? json['longitude'] as double : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  // Copy with method
  DriverModel copyWith({
    String? uid,
    String? drivername,
    String? phone,
    String? email,
    String? password,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return DriverModel(
      uid: uid ?? this.uid,
      drivername: drivername ?? this.drivername,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
