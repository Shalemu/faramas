class UserModel {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String email;
  final String? role;
  final String? username;
  final String? userImage;
  // final String? location;
  // final String? gender;
  // final String? dateOfBirth;
  final String? serviceCharge;

  UserModel({
    this.id,
    this.firstName,
    this.lastName,
    this.phone,
    required this.email,
    this.role,
    this.username,
    this.userImage,
    // this.location,
    // this.gender,
    // this.dateOfBirth,
    this.serviceCharge,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      // email: json['email'],
      email: json['email'] ?? '',
      role: json['role'],
      username: json['username'],
      userImage: json['profile_picture_url'],
      // location: json['location'],
      // gender: json['gender'],
      // dateOfBirth: json['date_of_birth'],
      serviceCharge: json['service_charge'],
    );
  }

  // Add a toJson method for sending updates to the backend
  // This will be used by your AuthProvider's updateUser method
  Map<String, dynamic> toJson() {
    return {
      // 'id' is typically not sent in an update payload
       'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      // 'location': location,
      'service_charge': serviceCharge,
    };
  }
}