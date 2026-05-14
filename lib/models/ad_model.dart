import '../constants/api_constants.dart';

class AdModel {

  final String uuid;

  final String title;

  final bool active;

  final String image;

  AdModel({
    required this.uuid,
    required this.title,
    required this.active,
    required this.image,
  });

  factory AdModel.fromJson(
      Map<String, dynamic> json) {

    return AdModel(

      uuid: json['uuid'] ?? '',

      title: json['title'] ?? '',

      active: json['active'] ?? false,

      image: json['image'] ?? '',
    );
  }

  String get fullImageUrl =>
      '${ApiConstants.baseUrl}$image';
}