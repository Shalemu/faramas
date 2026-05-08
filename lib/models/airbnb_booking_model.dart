class AirbnbBookingModel {
  final String? id;
  final String propertyId;
  final String userId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int adults;
  final int children;
  final String guestName;
  final String guestPhone;
  final String guestEmail;
  final String? notes;
  final int totalNights;
  final double totalCost;
  final String status; // pending, confirmed, cancelled
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AirbnbBookingModel({
    this.id,
    required this.propertyId,
    required this.userId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.adults,
    required this.children,
    required this.guestName,
    required this.guestPhone,
    required this.guestEmail,
    this.notes,
    required this.totalNights,
    required this.totalCost,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'user_id': userId,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'adults': adults,
      'children': children,
      'guest_name': guestName,
      'guest_phone': guestPhone,
      'guest_email': guestEmail,
      'notes': notes,
      'total_nights': totalNights,
      'total_cost': totalCost,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON response
  factory AirbnbBookingModel.fromJson(Map<String, dynamic> json) {
    return AirbnbBookingModel(
      id: json['id']?.toString(),
      propertyId: json['property_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      checkInDate: DateTime.parse(json['check_in_date']),
      checkOutDate: DateTime.parse(json['check_out_date']),
      adults: json['adults'] ?? 1,
      children: json['children'] ?? 0,
      guestName: json['guest_name'] ?? '',
      guestPhone: json['guest_phone'] ?? '',
      guestEmail: json['guest_email'] ?? '',
      notes: json['notes'],
      totalNights: json['total_nights'] ?? 0,
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Create a copy with updated fields
  AirbnbBookingModel copyWith({
    String? id,
    String? propertyId,
    String? userId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? adults,
    int? children,
    String? guestName,
    String? guestPhone,
    String? guestEmail,
    String? notes,
    int? totalNights,
    double? totalCost,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AirbnbBookingModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      userId: userId ?? this.userId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      guestEmail: guestEmail ?? this.guestEmail,
      notes: notes ?? this.notes,
      totalNights: totalNights ?? this.totalNights,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AirbnbBookingModel(id: $id, propertyId: $propertyId, userId: $userId, checkInDate: $checkInDate, checkOutDate: $checkOutDate, adults: $adults, children: $children, guestName: $guestName, totalCost: $totalCost, status: $status)';
  }
}
