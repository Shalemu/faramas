class Facility {
  final int? id;
  final String name;

  Facility({this.id, required this.name});

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {'name': name};
}
