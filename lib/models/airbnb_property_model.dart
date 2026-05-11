import 'package:faramas/models/facility_model.dart';
import 'package:faramas/models/property_model.dart';

class AirbnbModel extends PropertyModel {
  final int maxGuests;
  final int bedrooms;
  final int bathrooms;
  final double cleaningFee;
  final String checkInTime;
  final String checkOutTime;
  final List<String> houseRules;
  final List<String> amenities;
  final String cancellationPolicy;
  final int minimumStay;
  final int maximumStay;
  final bool instantBook;
  final String propertySubType;
  final double securityDeposit;
  final List<String> safetyFeatures;
  final String wifiPassword;
  final String accessInstructions;
  final int beds;

  AirbnbModel({
    // Base property fields
    int? id,
    required String name,
    bool? isFavorite,
    String? uploaderName,
    String? uploaderPhone,
    String? uploaderImage,
    String? uploaderRole,
    required String type,
    bool isBooked = false,
    required String address,
    required double price,
    String? imageUrl,
    List<String>? images,
    required bool isRent,
    bool? isBroker,
    String? category,
    required String description,
    required double totalPrice,
    required double maintenance,
    required List<Facility> facilities,
    int? uploader,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    String? region,
    String? district,
    String? videoUrl,

    // Airbnb-specific fields
    required this.maxGuests,
    required this.bedrooms,
    required this.bathrooms,
    required this.cleaningFee,
    required this.checkInTime,
    required this.checkOutTime,
    required this.houseRules,
    required this.amenities,
    required this.cancellationPolicy,
    required this.minimumStay,
    required this.maximumStay,
    required this.instantBook,
    required this.propertySubType,
    required this.securityDeposit,
    required this.safetyFeatures,
    required this.wifiPassword,
    required this.accessInstructions,
    required this.beds,
  }) : super(
          id: id,
          name: name,
          isFavorite: isFavorite ?? false,
          uploaderName: uploaderName,
          uploaderPhone: uploaderPhone,
          uploaderImage: uploaderImage,
          uploaderRole: uploaderRole,
          type: type,
          isBooked: isBooked,
          address: address,
          price: price,
          imageUrl: imageUrl,
          images: images ?? [],
          isRent: isRent,
          isBroker: isBroker ?? false,
          category: category,
          description: description,
          totalPrice: totalPrice,
          maintenance: maintenance,
          facilities: facilities,
          uploader: uploader,
          createdAt: createdAt,
          updatedAt: updatedAt,
          latitude: latitude,
          longitude: longitude,
          region: region,
          district: district,
        );

 
  @override
AirbnbModel copyWith({
  int? id,
  String? name,
  String? uploaderName,
  String? uploaderPhone,
  String? uploaderImage,
  String? uploaderRole,
  String? type,
  bool? isBooked,
  String? address,
  double? price,
  String? imageUrl,
  List<String>? images,
  bool? isRent,
  bool? isBroker,
  String? description,
  String? category,
  double? totalPrice,
  double? maintenance,
  List<Facility>? facilities,
  int? uploader,
  DateTime? createdAt,
  DateTime? updatedAt,
  double? latitude,
  double? longitude,
  String? region,
  bool? isFavorite,
  String? district,
   bool? secured,  
  AirbnbModel? airbnb,
  String? videoUrl,

  // Airbnb-specific
  int? maxGuests,
  int? bedrooms,
  int? bathrooms,
  double? cleaningFee,
  String? checkInTime,
  String? checkOutTime,
  List<String>? houseRules,
  List<String>? amenities,
  String? cancellationPolicy,
  int? minimumStay,
  int? maximumStay,
  bool? instantBook,
  String? propertySubType,
  double? securityDeposit,
  List<String>? safetyFeatures,
  String? wifiPassword,
  String? accessInstructions,
  int? beds,
}) {
  return AirbnbModel(
    id: id ?? this.id,
    name: name ?? this.name,
    uploaderName: uploaderName ?? this.uploaderName,
    uploaderPhone: uploaderPhone ?? this.uploaderPhone,
    uploaderImage: uploaderImage ?? this.uploaderImage,
    uploaderRole: uploaderRole ?? this.uploaderRole,
    type: type ?? this.type,
    isBooked: isBooked ?? this.isBooked,
    address: address ?? this.address,
    price: price ?? this.price,
    imageUrl: imageUrl ?? this.imageUrl,
    images: images ?? this.images,
    isRent: isRent ?? this.isRent,
    isBroker: isBroker ?? this.isBroker,
    description: description ?? this.description,
    category: category ?? this.category,
    totalPrice: totalPrice ?? this.totalPrice,
    maintenance: maintenance ?? this.maintenance,
    facilities: facilities ?? this.facilities,
    uploader: uploader ?? this.uploader,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    region: region ?? this.region,
    isFavorite: isFavorite ?? this.isFavorite,
    district: district ?? this.district,
    videoUrl: videoUrl ?? this.videoUrl,
   

    // Airbnb-specific
    maxGuests: maxGuests ?? this.maxGuests,
    bedrooms: bedrooms ?? this.bedrooms,
    bathrooms: bathrooms ?? this.bathrooms,
    cleaningFee: cleaningFee ?? this.cleaningFee,
    checkInTime: checkInTime ?? this.checkInTime,
    checkOutTime: checkOutTime ?? this.checkOutTime,
    houseRules: houseRules ?? this.houseRules,
    amenities: amenities ?? this.amenities,
    cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
    minimumStay: minimumStay ?? this.minimumStay,
    maximumStay: maximumStay ?? this.maximumStay,
    instantBook: instantBook ?? this.instantBook,
    propertySubType: propertySubType ?? this.propertySubType,
    securityDeposit: securityDeposit ?? this.securityDeposit,
    safetyFeatures: safetyFeatures ?? this.safetyFeatures,
    wifiPassword: wifiPassword ?? this.wifiPassword,
    accessInstructions: accessInstructions ?? this.accessInstructions,
    beds: beds ?? this.beds,
  );
}

  
  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0.0;
  }

  /// From JSON
  factory AirbnbModel.fromJson(Map<String, dynamic> json) {
    final airbnb = json['airbnb'] ?? {};
    return AirbnbModel(
      id: json['id'],
      name: json['name'] ?? '',
      isFavorite: json['is_favorite'] ?? false,
      uploaderName: json['uploader_name'],
      uploaderPhone: json['uploader_phone'],
      uploaderImage: json['uploader_image_url'],
      uploaderRole: json['uploader_role'],
      type: json['type'] ?? '',
      isBooked: json['is_booked'] == true ||
          (json['is_booked'] is String && json['is_booked'] == 'true'),
      address: json['address'] ?? '',
      price: parseDouble(json['price']),
      imageUrl: json['image_url'] ?? '',
      images: json['images'] != null
          ? List<String>.from(
              json['images'].map((x) => x['image_url'] ?? x['url'] ?? ''))
          : [],
      isRent: json['is_rent'] ?? false,
      isBroker: json['is_broker'] ?? false,
      category: json['category'],
      description: json['description'] ?? '',
      totalPrice: parseDouble(json['total_price']),
      maintenance: parseDouble(json['maintenance']),
      facilities: json['facilities'] != null
          ? (json['facilities'] as List)
              .map((f) => Facility.fromJson(f))
              .toList()
          : [],
      uploader: json['uploader'] ?? json['user']?['id'],
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      // Airbnb-specific
      maxGuests: airbnb['max_guests'] ?? 0,
      bedrooms: airbnb['bedrooms'] ?? 0,
      bathrooms: airbnb['bathrooms'] ?? 0,
      cleaningFee: parseDouble(airbnb['cleaning_fee']),
      checkInTime: airbnb['check_in_time'] ?? '',
      checkOutTime: airbnb['check_out_time'] ?? '',
      houseRules: List<String>.from(airbnb['house_rules'] ?? []),
      amenities: List<String>.from(airbnb['amenities'] ?? []),
      cancellationPolicy: airbnb['cancellation_policy'] ?? '',
      minimumStay: airbnb['minimum_stay'] ?? 0,
      maximumStay: airbnb['maximum_stay'] ?? 0,
      instantBook: airbnb['instant_book'] ?? false,
      propertySubType: airbnb['property_sub_type'] ?? '',
      securityDeposit: parseDouble(airbnb['security_deposit']),
      safetyFeatures: List<String>.from(airbnb['safety_features'] ?? []),
      wifiPassword: airbnb['wifi_password'] ?? '',
      accessInstructions: airbnb['access_instructions'] ?? '',
      beds: airbnb['beds'] ?? 0,
    );
  }

  /// To JSON
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson['airbnb'] = {
      "max_guests": maxGuests,
      "bedrooms": bedrooms,
      "bathrooms": bathrooms,
      "cleaning_fee": cleaningFee,
      "check_in_time": checkInTime,
      "check_out_time": checkOutTime,
      "house_rules": houseRules,
      "amenities": amenities,
      "cancellation_policy": cancellationPolicy,
      "minimum_stay": minimumStay,
      "maximum_stay": maximumStay,
      "instant_book": instantBook,
      "property_sub_type": propertySubType,
      "security_deposit": securityDeposit,
      "safety_features": safetyFeatures,
      "wifi_password": wifiPassword,
      "access_instructions": accessInstructions,
      "beds": beds,
    };
    return baseJson;
  }

  
  double getTotalStayCost(int nights) {
    return (price * nights) + cleaningFee;
  }
}
