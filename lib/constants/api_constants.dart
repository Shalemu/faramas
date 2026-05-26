import 'package:http/http.dart' as http;

class ApiConstants {
  // 161.97.65.175:9098
  // 192.168.31.228:8000
  static const String baseUrl = 'http://161.97.65.175:9098';
  // static const String baseUrl = 'https://demo.faramas.co.tz';
  // static const String baseUrl = 'https://b6c5-154-74-176-4.ngrok-free.app';

  //auth
  static const String appVersionConfig = '$baseUrl/app-version-config/';
  static const String login = '$baseUrl/auth/login/';
  static const String user = '$baseUrl/auth/user';
  static const String otpVerify = '$baseUrl/auth/otp/verify/';
  static const String updatephone = '$baseUrl/auth/update-phone';
  static const String otpRequest = '$baseUrl/auth/otp/request/';
  static const String register = '$baseUrl/api/user-registration/';
  static const String resetPassword = '$baseUrl/auth/reset/user-password';
  static const String requestResetToken = '$baseUrl/auth/request/reset-token';
  static const String changePassword = '$baseUrl/auth/user-change-password';

  static const String getProperties = '$baseUrl/api/properties/';
  static const String postProperties = '$baseUrl/api/properties/';
  static const String propertyDetail = '$baseUrl/api/properties/detail/';
  static const String booking = '$baseUrl/api/book/property/';
  static const String airbnbBooking = '$baseUrl/api/airbnb-bookings/';
  static const String ads = '$baseUrl/api/ads';
  static const String uploader = '$baseUrl/api/uploader/properties/';

  // Airbnb-specific endpoints (using same base endpoints but with category filter)
  static const String getAirbnbProperties =
      '$baseUrl/api/properties/?category=Airbnb';
  static const String postAirbnbProperties =
      '$baseUrl/api/properties/'; // Same endpoint, differentiated by category field
  // static const String airbnbBooking = '$baseUrl/api/book/property/'; // Same endpoint, with additional Airbnb-specific fields

  //payment
  static const String customerOrders = '$baseUrl/api/customer-orders';
  static const String requestPaymentUrl = '$baseUrl/api/request-payment-url';
  static const String pushToPay = '$baseUrl/api/push-to-pay';
  static const String myPayments = '$baseUrl/api/payments/my-payments/';

  //tour
  static const String tourRequests = '$baseUrl/api/tour-requests/';
  static const String confirmTourRequest = '$baseUrl/api/confirm-tour-request/';

  //booking
  static const String bookingConfirmation = '$baseUrl/api/confirmation/';
  static const String secureProperties = '$baseUrl/api/secure-properties/';
}

class MyHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Bypass SSL verification (DANGEROUS for production!)
    request.headers['Accept'] = 'application/json';
    return _inner.send(request);
  }
}
