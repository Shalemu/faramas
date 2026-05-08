import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:faramas/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

extension StringCasingExtension on String {
  String get capitalizeFirst =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class AuthService {
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      body: {
        'username': username,
        'password': password,
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final accessToken = responseData['access'];
      final refreshToken = responseData['refresh'];

      final user = UserModel.fromJson(responseData['user']);

      // Save tokens and customer_id
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', accessToken ?? '');
      await prefs.setString('refresh_token', refreshToken ?? '');
      await prefs.setInt('customer_id', user.id!); // <-- save customer id
      await prefs.setString('user', jsonEncode(user.toJson())); // <--- save user
      

      debugPrint("Access Token: $accessToken");
      debugPrint("Refresh Token: $refreshToken");
      debugPrint("Customer ID: ${user.id}");

      return {
        'status': 'success',
        'access': accessToken,
        'refresh': refreshToken,
        'user': user,
      };
    } else if (response.statusCode == 202) {
      // Backend sent OTP, user needs to verify
      return {
        'status': 'otp_required',
        'phone_number': responseData['phone'],
        'message':
            responseData['detail'] ?? 'OTP sent to your phone. Please verify.',
      };
    } else {
      // Handle different error status codes and parse error messages
      final errorData = jsonDecode(response.body);
      String errorMessage = 'Failed to login. Please try again.';

      if (response.statusCode == 400) {
        if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        } else if (errorData.containsKey('non_field_errors') &&
            errorData['non_field_errors'] is List) {
          errorMessage = errorData['non_field_errors'][0];
        } else if (errorData.containsKey('username') &&
            errorData['username'] is List) {
          errorMessage = 'Username: ${errorData['username'][0]}';
        } else if (errorData.containsKey('password') &&
            errorData['password'] is List) {
          errorMessage = 'Password: ${errorData['password'][0]}';
        } else {
          errorMessage = 'Invalid input. Please check your credentials.';
        }
      } else if (response.statusCode == 401) {
        errorMessage = 'Unauthorized: Invalid credentials provided.';
      } else {
        errorMessage =
            'Server error (${response.statusCode}). Please try again later.';
      }
      throw Exception(errorMessage);
    }
  }

  // Method to verify OTP and get tokens
  Future<Map<String, dynamic>> verifyOtp(String phone, String otpCode) async {
    const String url = '${ApiConstants.baseUrl}/auth/otp/verify/';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
          'otp': otpCode,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final accessToken = responseData['access'];
        final refreshToken = responseData['refresh'];

        debugPrint("OTP Verified!");
        debugPrint("Access Token: $accessToken");
        debugPrint("Refresh Token: $refreshToken");

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', accessToken ?? '');
        await prefs.setString('refresh_token', refreshToken ?? '');

        return {
          'status': 'success',
          'access': accessToken,
          'refresh': refreshToken,
          'user': UserModel.fromJson(responseData['user']),
        };
      } else {
        String errorMessage =
            responseData['detail'] ?? 'OTP verification failed.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error during OTP verification: $e');
    }
  }

  Future<bool> requestNewOtp(String phone) async {
    const String url = '${ApiConstants.baseUrl}/auth/otp/request/';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print(
            'Request new OTP failed: ${response.statusCode} - ${responseData['detail']}');
        return false;
      }
    } catch (e) {
      print('Error during new OTP request: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> userRegistration({
    required String firstName,
    required String lastName,
    required String email,
    // required String phone,
    required String username,
    required String password,
    required String role,
    // String? location,
    // String? gender,
    // String? dateOfBirth,
    String? serviceCharge,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.register),
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        // 'phone': phone,
        'password': password,
        'role': role,
        'username': username,
        // 'location': location,
        // 'gender': gender,
        // 'date_of_birth': dateOfBirth,
        if (serviceCharge != null) 'service_charge': serviceCharge,
      },
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'msg': data['msg'] ?? 'Account created successfully',
        'data': data
      };
    } else {
      final errorData = jsonDecode(response.body);
      String errorMessage =
          errorData['msg'] ?? 'Registration failed. Please check your details';
      if (response.statusCode == 400) {
        if (errorData.containsKey('non_field_errors') &&
            errorData['non_field_errors'] is List &&
            errorData['non_field_errors'].isNotEmpty) {
          errorMessage = errorData['non_field_errors'][0];
        } else {
          List<String> fieldErrors = [];
          errorData.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              String fieldName = key.replaceAll('_', ' ').capitalizeFirst;
              fieldErrors.add('$fieldName: ${value[0]}');
            }
          });
          if (fieldErrors.isNotEmpty) {
            errorMessage = 'Validation Errors:\n${fieldErrors.join('\n')}';
          }
        }
      } else if (response.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      }

      throw Exception(errorMessage);
    }
  }

  Future<UserModel> updateUserProfile({
    required int userId,
    required String accessToken,
    required UserModel data,
    File? imageFile,
  }) async {
    const String url = ApiConstants.user;

    var request = http.MultipartRequest('PATCH', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $accessToken';

    if (data.firstName != null) request.fields['first_name'] = data.firstName!;
    if (data.lastName != null) request.fields['last_name'] = data.lastName!;
    request.fields['email'] = data.email;
    if (data.phone != null) request.fields['phone'] = data.phone!;
    // if (data.location != null) request.fields['location'] = data.location!;
    // if (data.gender != null) request.fields['gender'] = data.gender!;
    // if (data.dateOfBirth != null) {
    //   request.fields['date_of_birth'] = data.dateOfBirth!;
    // }

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile',
        imageFile.path,
      ));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UserModel.fromJson(responseData);
      } else {
        String errorMessage =
            responseData['detail'] ?? 'Failed to update profile.';
        if (responseData is Map && responseData.isNotEmpty) {
          errorMessage =
              'Validation Error: ${responseData.values.expand((e) => e is List ? e : [
                  e
                ]).join(', ')}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error during profile update request: $e');
    }
  }

  Future<bool> updatePhoneNumber({
  required String accessToken,
  required String phoneNumber,
}) async {
  final url = Uri.parse(ApiConstants.updatephone);

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode({'phone': phoneNumber}),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    throw Exception(responseData['detail'] ?? 'Failed to update phone number.');
  }
}


  Future<UserModel> getUserDetails({required String accessToken}) async {
    const String url = ApiConstants.user;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UserModel.fromJson(responseData);
      } else {
        String errorMessage =
            responseData['detail'] ?? 'Failed to fetch user details.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error fetching user details: $e');
    }
  }
}
