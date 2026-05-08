import 'package:faramas/models/property_model.dart';
import 'package:faramas/models/user_model.dart';

class BookingModel {
  final int id;
  final PropertyModel property;
  final UserModel user;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int? adults;
  final int? children;
  final String? guestName;
  final String? guestPhone;
  final String? guestEmail;
  final String? notes;
  final int? totalNights;
  final double? totalCost;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAirbnb; 
  BookingModel({
    required this.id,
    required this.property,
    required this.user,
    this.checkInDate,
    this.checkOutDate,
    this.adults,
    this.children,
    this.guestName,
    this.guestPhone,
    this.guestEmail,
    this.notes,
    this.totalNights,
    this.totalCost,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isAirbnb = false, 
  });

  /// Factory to safely parse JSON
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? 0,
      property: json['property'] != null
          ? PropertyModel.fromJson(json['property'])
          : PropertyModel(
              id: 0,
              name: 'Unknown',
              type: 'normal',
              address: '',
              price: 0,
              description: '',
              totalPrice: 0,
              maintenance: 0,
              facilities: [],
              isRent: false,
            ),
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : UserModel(email: '', firstName: '', lastName: ''),
      checkInDate: json['check_in_date'] != null
          ? DateTime.tryParse(json['check_in_date'])
          : null,
      checkOutDate: json['check_out_date'] != null
          ? DateTime.tryParse(json['check_out_date'])
          : null,
      adults: json['adults'],
      children: json['children'],
      guestName: json['guest_name'],
      guestPhone: json['guest_phone'],
      guestEmail: json['guest_email'],
      notes: json['notes'],
      totalNights: json['total_nights'],
      totalCost: json['total_cost'] != null
          ? double.tryParse(json['total_cost'].toString())
          : null,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
      isAirbnb: _parseBool(json['is_airbnb']), 
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property': property.toJson(),
      'user': user.toJson(),
      'check_in_date': checkInDate?.toIso8601String(),
      'check_out_date': checkOutDate?.toIso8601String(),
      'adults': adults,
      'children': children,
      'guest_name': guestName,
      'guest_phone': guestPhone,
      'guest_email': guestEmail,
      'notes': notes,
      'total_nights': totalNights,
      'total_cost': totalCost,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_airbnb': isAirbnb,
    };
  }

  /// Create a copy with changes
  BookingModel copyWith({
    int? id,
    PropertyModel? property,
    UserModel? user,
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
    bool? isAirbnb,
  }) {
    return BookingModel(
      id: id ?? this.id,
      property: property ?? this.property,
      user: user ?? this.user,
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
      isAirbnb: isAirbnb ?? this.isAirbnb,
    );
  }

 
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }
}
