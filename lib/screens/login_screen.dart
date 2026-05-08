import 'package:faramas/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:faramas/config/app_colors.dart';
import '../config/app_routes.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/input_widget.dart';
import '../widgets/language_selector.dart';
import '../l10n/app_localizations.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _goToSignUp() {
    Navigator.of(context).pushNamed(AppRoutes.registration);
  }

  // ignore: unused_element
  void _goToMobileSignIn() {
    Navigator.of(context).pushNamed(AppRoutes.mobileLogin);
  }

  void _goToForgotPassword() {
    Navigator.of(context).pushNamed(AppRoutes.resetPassword);
  }

  void _showPopupNotification(String message, Color backgroundColor) {
    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showPopupNotification("Please enter both username and password.", Colors.blue.shade700);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final authData = await authService.login(username, password);

      if (!mounted) return;

      if (authData['status'] == 'success') {
        // User successfully logged in and is verified
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.login(
          authData['user'] as UserModel,
          authData['access'] as String,
          authData['refresh'] as String,
        );
        _showPopupNotification("You have successfully logged in to Faramas!!", Colors.blue.shade700);
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else if (authData['status'] == 'otp_required') {
        // Backend indicated OTP is required
        _showPopupNotification(authData['message'] ?? 'OTP sent to your phone. Please verify.', Colors.blue.shade700);
        // Navigate to OTP verification screen, passing the phone number
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OtpForm(
                phoneNumber: authData['phone_number']), // Pass phone number
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showPopupNotification(e.toString().replaceFirst('Exception: ', ''), Colors.red.shade700);
      debugPrint("Login error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final size = MediaQuery.of(context).size;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background curved shapes
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Language Selector in top right corner
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const LanguageSelector(iconSize: 28),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    child: Image.asset(
                      'assets/logo/faramas_logo.png',
                      width: 140,
                      height: 140,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 500),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    child: Text(localizations?.welcomeBack ?? 'Welcome back!'),
                  ),
                  const SizedBox(height: 30),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 700),
                    opacity: 1,
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: inputDecoration(
                            localizations?.username ?? 'Username',
                            Icons.email,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: inputDecoration(
                            localizations?.password ?? 'Password',
                            Icons.lock,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _goToForgotPassword,
                            child: Text(
                              localizations?.forgotPassword ?? 'Forgot Password?',
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                  onPressed: _login,
                                  icon: const Icon(
                                    Icons.login,
                                    color: AppColors.textLight,
                                  ),
                                  label: Text(
                                    localizations?.login ?? 'Login',
                                    style:
                                        const TextStyle(color: AppColors.textLight),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    textStyle: const TextStyle(fontSize: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 6,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 25),
                        GestureDetector(
                          onTap: _goToSignUp,
                          child: Text.rich(
                            TextSpan(
                              text: localizations?.dontHaveAccount ?? "Don't have an account? ",
                              children: [
                                TextSpan(
                                  text: localizations?.signUp ?? 'Sign Up',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
