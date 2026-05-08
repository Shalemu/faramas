class TourRequestModel {
  final int id;
  final String propertyName;
  final String customerName;
  final String customerPhone;
  final String date;
  final String time;
  final String type;
  bool isComplete;

  TourRequestModel({
    required this.id,
    required this.propertyName,
    required this.customerName,
    required this.customerPhone,
    required this.date,
    required this.time,
    required this.type,
    required this.isComplete,
  });

  factory TourRequestModel.fromJson(Map<String, dynamic> json) {
    return TourRequestModel(
      id: json['id'],
      propertyName: json['property_name'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      type: json['type'] ?? '',
      isComplete: json['is_complete'] ?? false,
    );
  }
}
