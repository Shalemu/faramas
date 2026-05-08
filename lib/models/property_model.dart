import 'package:faramas/models/airbnb_property_model.dart';
import 'package:faramas/models/facility_model.dart';
import 'package:flutter/material.dart';

class PropertyModel {
  final int? id;
  final String name;
  bool isFavorite;
  final String? uploaderName;
  final String? uploaderPhone;
  final String? uploaderImage;
  final String? uploaderRole;
  final String type; // normal | airbnb
  bool isBooked;
  final String address;
  final double price;
  final String? imageUrl;
  final List<String> images;
  final String? videoBase64;
  String? get videoUrl => videoBase64;
  final bool isRent;
  final bool isBroker;
  final String? category;
  final String description;
  final double totalPrice;
  final double maintenance;
  final List<Facility> facilities;
  final int? uploader;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? latitude;
  final double? longitude;
  final String? region;
  final String? district;
  final bool secured;
  final AirbnbModel? airbnb;

  PropertyModel({
    this.id,
    required this.name,
    this.uploaderName,
    this.uploaderPhone,
    this.uploaderImage,
    this.uploaderRole,
    required this.type,
    this.isBooked = false,
    required this.address,
    required this.price,
    this.imageUrl,
    this.images = const [],
    this.videoBase64,
    required this.isRent,
    this.isBroker = false,
    this.category,
    required this.description,
    required this.totalPrice,
    required this.maintenance,
    required this.facilities,
    this.secured = false,
    this.uploader,
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.region,
    this.district,
    this.isFavorite = false,
    this.airbnb,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] ?? '',
      uploaderName: json['uploader_name'],
      uploaderPhone: json['uploader_phone'],
      uploaderImage: json['uploader_image_url'],
      uploaderRole: json['uploader_role'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      region: json['region'] ?? "",
      district: json['district'] ?? "",
      type: json['type'] ?? 'normal',
      isBooked: json['is_booked'] == true ||
          (json['is_booked'] is String && json['is_booked'] == 'true'),
      address: json['address'] ?? '',
      category: json['category'],
      createdAt:
          json['created'] != null ? DateTime.tryParse(json['created']) : null,
      updatedAt:
          json['updated'] != null ? DateTime.tryParse(json['updated']) : null,
      price: _parseDouble(json['price']),
      imageUrl: json['image_url'] ?? json['featured_image'] ?? '',
      images: (() {
        final list = <String>[];

        final primary = json['image_url']?.toString().trim();
        if (primary != null && primary.isNotEmpty) {
          list.add(primary);
        }

        final extra = json['images'];

        if (extra is List) {
          for (final x in extra) {
            if (x is String && x.isNotEmpty) {
              list.add(x);
            } else if (x is Map) {
              final url = x['image_url'] ?? x['url'] ?? x['path'];
              if (url != null && url.toString().isNotEmpty) {
                list.add(url.toString());
              }
            }
          }
        }

        return list;
      })(),
      videoBase64: json['video_base64'],
      isRent: json['is_rent'] ?? false,
      isBroker: json['is_broker'] ?? false,
      description: json['description'] ?? '',
      facilities: json['facilities'] != null
          ? (json['facilities'] as List<dynamic>)
              .map((f) => Facility.fromJson(f))
              .toList()
          : [],
      totalPrice: _parseDouble(json['total_price']),
      maintenance: _parseDouble(json['maintenance']),
      uploader: json['uploader'] ?? json['user']?['id'],
      secured: json['secured'] == true,
      airbnb: json['airbnb'] != null
          ? AirbnbModel.fromJson({
              ...json,
              'airbnb': json['airbnb'],
            })
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      if (id != null) 'id': id,
      'name': name,
      'uploader_name': uploaderName,
      'uploader_phone': uploaderPhone,
      'uploader_image_url': uploaderImage,
      'uploader_role': uploaderRole,
      'type': type,
      'is_booked': isBooked,
      'address': address,
      'price': price,
      if (imageUrl != null) 'image_url': imageUrl,
      'images': images.map((image) => {'image_url': image}).toList(),
      if (videoBase64 != null) 'video_base64': videoBase64,
      'is_rent': isRent,
      'is_broker': isBroker,
      'category': category,
      'description': description,
      'total_price': totalPrice,
      'maintenance': maintenance,
      'facilities': facilities.map((f) => f.toJson()).toList(),
      if (uploader != null) 'uploader': uploader,
      'latitude': latitude,
      'longitude': longitude,
      'region': region,
      'district': district,
      'secured': secured,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };

    if (airbnb != null) {
      data['airbnb'] = airbnb!.toJson();
    }

    return data;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    String str = value.toString().trim().replaceAll(',', '');
    if (str.isEmpty) return 0.0;
    final parsed = double.tryParse(str);
    if (parsed == null) {
      debugPrint('Warning: could not parse double from "$str"');
      return 0.0;
    }
    return parsed;
  }

  PropertyModel copyWith({
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
    String? videoBase64,
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
  }) {
    return PropertyModel(
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
      videoBase64: videoBase64 ?? this.videoBase64,
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
      district: district ?? this.district,
      isFavorite: isFavorite ?? this.isFavorite,
      secured: secured ?? this.secured,
      airbnb: airbnb ?? this.airbnb,
    );
  }

  bool get isAirbnb => airbnb != null;

  List<String> get safeImages {
    if (images.isNotEmpty) return images;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return [imageUrl!];
    }

    return [];
  }
}
