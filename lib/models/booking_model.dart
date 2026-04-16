enum BookingStatus {
  pending,
  accepted,
  rejected,
  cancelled
}

class BookingModel {
  final String bookingId;
  final String rideId;
  final String userId; // passenger user ID
  final String driverId;
  final String pickupLocation;
  final String dropoffLocation;
  final int seatsBooked;
  final double pricePerSeat;
  final double totalPrice;
  final String status; // "pending", "approved", etc
  final bool isApproved;
  final DateTime bookedAt;
  final DateTime? approvedAt;

  BookingModel({
    required this.bookingId,
    required this.rideId,
    required this.userId,
    required this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.seatsBooked,
    required this.pricePerSeat,
    required this.totalPrice,
    required this.status,
    required this.isApproved,
    required this.bookedAt,
    this.approvedAt,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'rideId': rideId,
      'userId': userId,
      'driverId': driverId,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'seatsBooked': seatsBooked,
      'pricePerSeat': pricePerSeat,
      'totalPrice': totalPrice,
      'status': status,
      'isApproved': isApproved,
      'bookedAt': bookedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'] ?? '',
      rideId: json['rideId'] ?? '',
      userId: json['userId'] ?? '',
      driverId: json['driverId'] ?? '',
      pickupLocation: json['pickupLocation'] ?? 'Unknown Location',
      dropoffLocation: json['dropoffLocation'] ?? 'Unknown Location',
      seatsBooked: (json['seatsBooked'] ?? 1) as int,
      pricePerSeat: (json['pricePerSeat'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      isApproved: json['isApproved'] ?? false,
      bookedAt: json['bookedAt'] != null
          ? DateTime.parse(json['bookedAt'] as String)
          : DateTime.now(),
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
    );
  }

  // Copy with method
  BookingModel copyWith({
    String? bookingId,
    String? rideId,
    String? userId,
    String? driverId,
    String? pickupLocation,
    String? dropoffLocation,
    int? seatsBooked,
    double? pricePerSeat,
    double? totalPrice,
    String? status,
    bool? isApproved,
    DateTime? bookedAt,
    DateTime? approvedAt,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      rideId: rideId ?? this.rideId,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      isApproved: isApproved ?? this.isApproved,
      bookedAt: bookedAt ?? this.bookedAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}
