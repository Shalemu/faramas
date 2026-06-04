import 'package:faramas/features/payment/screen/generate_payment.dart';
import 'package:flutter/material.dart';
import '../features/properties/screens/property_screen.dart';
import '../features/booking/screens/booking_screen.dart';
import '../screens/home_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/profile/screens/owner_booking_screen.dart';
import '../features/auth/screens/registration_screen.dart';
import '../features/auth/screens/mobile_signin_screen.dart';
import '../features/auth/screens/password_reset_screen.dart';
import '../screens/splash_screen.dart';
import '../features/payment/screen/subscription_payments_screen.dart';
import '../features/payment/screen/payment_history_screen.dart';
import '../features/profile/screens/about_app_screen.dart';
import '../screens/tour_screen.dart';

class AppRoutes {
  static final pages = {
    '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/registration': (context) => const CreateAccountScreen(),
    '/home': (context) => const HomeScreen(),
    '/mobile-login': (context) => const MobileSignInScreen(),
    '/reset-password': (context) => const ForgotPasswordScreen(),
    '/bookings': (context) => const MyBookingsScreen(),
    '/owner-booking': (context) => const OwnerBookingsScreen(),
    '/properties': (context) => const PropertiesScreen(),
    '/subscriptionPayments': (context) => const SubscriptionPaymentsScreen(),
    '/generatePayment': (context) => const GeneratePaymentScreen(),
    '/paymentHistory': (context) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args == null || args is! Map<String, dynamic>) {
        // You can return an error page or redirect somewhere else
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: const Center(
              child: Text('Missing or invalid arguments for Payment History')),
        );
      }

      return PaymentHistoryScreen(
        orderId: args['orderId'] as String,
        customerId: args['customerId'] as int,
      );
    },
    '/aboutApp': (context) => const AboutAppScreen(),
    '/tour': (context) => const TourScreen(),
  };

  static const String splash = '/';
  static const String login = '/login';
  static const String registration = '/registration';
  static const String home = '/home';
  static const String mobileLogin = '/mobile-login';
  static const String resetPassword = '/reset-password';
  static const String bookings = '/bookings';
  static const String ownerBookings = '/owner-booking';
  static const String properties = '/properties';
}