class RideModel {
  final String rideId;
  final String driverId;
  final double startLatitude;
  final double startLongitude;
  final String startAddress;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? destinationAddress;
  final int numberOfPassengers;
  final int numberOfPassengersAllocated;
  final double basePrice;
  final double? additionalPrice;
  final double? totalPrice;
  final RideStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double? rideDistance;
  final int? rideDuration; // in seconds

  RideModel({
    required this.rideId,
    required this.driverId,
    required this.startLatitude,
    required this.startLongitude,
    required this.startAddress,
    this.destinationLatitude,
    this.destinationLongitude,
    this.destinationAddress,
    required this.numberOfPassengers,
    this.numberOfPassengersAllocated = 0,
    required this.basePrice,
    this.additionalPrice,
    this.totalPrice,
    this.status = RideStatus.started,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.rideDistance,
    this.rideDuration,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'driverId': driverId,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'startAddress': startAddress,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'destinationAddress': destinationAddress,
      'numberOfPassengers': numberOfPassengers,
      'numberOfPassengersAllocated': numberOfPassengersAllocated,
      'basePrice': basePrice,
      'additionalPrice': additionalPrice,
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rideDistance': rideDistance,
      'rideDuration': rideDuration,
    };
  }

  // Create from Firestore document
  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      rideId: json['rideId'] ?? '',
      driverId: json['driverId'] ?? '',
      startLatitude: json['startLatitude'] ?? 0.0,
      startLongitude: json['startLongitude'] ?? 0.0,
      startAddress: json['startAddress'] ?? '',
      destinationLatitude:
          json['destinationLatitude'] != null ? json['destinationLatitude'] as double : null,
      destinationLongitude:
          json['destinationLongitude'] != null ? json['destinationLongitude'] as double : null,
      destinationAddress: json['destinationAddress'] as String?,
      numberOfPassengers: json['numberOfPassengers'] ?? 1,
      numberOfPassengersAllocated: json['numberOfPassengersAllocated'] ?? 0,
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      additionalPrice:
          json['additionalPrice'] != null ? (json['additionalPrice'] as num).toDouble() : null,
      totalPrice:
          json['totalPrice'] != null ? (json['totalPrice'] as num).toDouble() : null,
      status: _parseRideStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      completedAt:
          json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      rideDistance:
          json['rideDistance'] != null ? (json['rideDistance'] as num).toDouble() : null,
      rideDuration: json['rideDuration'] as int?,
    );
  }

  // Copy with method
  RideModel copyWith({
    String? rideId,
    String? driverId,
    double? startLatitude,
    double? startLongitude,
    String? startAddress,
    double? destinationLatitude,
    double? destinationLongitude,
    String? destinationAddress,
    int? numberOfPassengers,
    int? numberOfPassengersAllocated,
    double? basePrice,
    double? additionalPrice,
    double? totalPrice,
    RideStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    double? rideDistance,
    int? rideDuration,
  }) {
    return RideModel(
      rideId: rideId ?? this.rideId,
      driverId: driverId ?? this.driverId,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      startAddress: startAddress ?? this.startAddress,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      numberOfPassengers: numberOfPassengers ?? this.numberOfPassengers,
      numberOfPassengersAllocated: numberOfPassengersAllocated ?? this.numberOfPassengersAllocated,
      basePrice: basePrice ?? this.basePrice,
      additionalPrice: additionalPrice ?? this.additionalPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rideDistance: rideDistance ?? this.rideDistance,
      rideDuration: rideDuration ?? this.rideDuration,
    );
  }

  static RideStatus _parseRideStatus(String? status) {
    switch (status) {
      case 'started':
        return RideStatus.started;
      case 'inProgress':
        return RideStatus.inProgress;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.started;
    }
  }
}

enum RideStatus {
  started,
  inProgress,
  completed,
  cancelled,
}
