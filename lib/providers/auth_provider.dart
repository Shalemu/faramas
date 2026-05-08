import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:faramas/constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _accessToken;
  String? _refreshToken;

  // Keys for SharedPreferences
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _userDataKey = 'userData';

  // Getters
  UserModel? get user => _user;

  String? get accessToken => _accessToken;

  void login(UserModel user, String access, String refresh) {
    _user = user;
    _accessToken = access;
    _refreshToken = refresh;
    notifyListeners();
  }

  Future<String?> getAccessToken() async {
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    return _refreshToken;
  }

  bool get isAuthenticated {
    return _user != null && _accessToken != null && !isAccessTokenExpired();
  }

  bool isPhoneMissing() {
  return user?.phone == null || user!.phone!.isEmpty;
}


  // Check if the access token has expired (client-side using JWT_Decoder)
  bool isAccessTokenExpired() {
    if (_accessToken == null) return true;
    try {
      return JwtDecoder.isExpired(_accessToken!);
    } catch (e) {
      // Handle cases where token is malformed or invalid JWT
      debugPrint('Error decoding access token: $e');
      return true;
    }
  }

  // Attempts to load authentication state from storage on app startup
  Future<void> loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final storedAccessToken = prefs.getString(_accessTokenKey);
    final storedRefreshToken = prefs.getString(_refreshTokenKey);
    final storedUserData = prefs.getString(_userDataKey);

    if (storedAccessToken != null &&
        storedRefreshToken != null &&
        storedUserData != null) {
      _accessToken = storedAccessToken;
      _refreshToken = storedRefreshToken;
      try {
        _user = UserModel.fromJson(json.decode(storedUserData));
      } catch (e) {
        debugPrint('Error decoding stored user data: $e');
        _clearAuthData(); // Clear corrupted data
        return;
      }

      // Check if access token is expired; if so, try to refresh
      if (isAccessTokenExpired()) {
        debugPrint('Access token expired. Attempting refresh...');
        final refreshed = await refreshToken();
        if (!refreshed) {
          debugPrint('Failed to refresh token. User needs to re-login.');
          _clearAuthData();
        }
      } else {
        debugPrint('Access token is valid.');
      }
    } else {
      debugPrint('No stored auth data found.');
      _clearAuthData();
    }
    notifyListeners();
  }

  Future<bool> refreshToken() async {
    print('Starting token refresh...');
    final refresh = await getRefreshToken();
    if (refresh == null) {
      debugPrint('No refresh token found');
      return false;
    }

    try {
      debugPrint('Sending refresh token request...');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/token/refresh/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'refresh': refresh}),
      );

      debugPrint('Refresh response status: ${response.statusCode}');
      debugPrint('Refresh response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newAccessToken = responseData['access'];

        if (newAccessToken == null || newAccessToken.toString().isEmpty) {
          debugPrint(
              'Invalid new access token received from refresh endpoint.');
          _clearAuthData();
          return false;
        }

        debugPrint('New access token received, saving...');
        _accessToken = newAccessToken;
        _refreshToken = refresh;

        // Verify token was saved
        _accessToken = newAccessToken;
        await _saveTokensAndUser(); // Save the new access token
        debugPrint('Token refresh successful. New access token obtained.');
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        // Unauthorized - refresh token is invalid/expired
        debugPrint(
            'Refresh token invalid or expired (401). User needs to re-login.');
        _clearAuthData(); // Force re-login
        notifyListeners();
        return false;
      } else {
        debugPrint('Token refresh failed with status ${response.statusCode}.');
        // Do not clear data immediately for other errors, let subsequent API calls handle it or retry
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      _clearAuthData(); // Network/other error, assume tokens are problematic
      notifyListeners();
      return false;
    }
  }

  // Updates user data, usually after profile edits
  Future<void> updateUser(UserModel updatedUser) async {
    _user = updatedUser;
    await _saveTokensAndUser();
    notifyListeners();
  }


  Future<void> logout() async {
    debugPrint('Logging out user...');
    await _clearAuthData();
    notifyListeners();
  }

  // --- Helper Methods for SharedPreferences ---
  Future<void> _saveTokensAndUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(_accessTokenKey, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(_refreshTokenKey, _refreshToken!);
    }
    if (_user != null) {
      await prefs.setString(_userDataKey, json.encode(_user!.toJson()));
    }
    debugPrint('Tokens and user data saved.');
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    debugPrint('Auth data cleared from storage and state.');
  }
}
