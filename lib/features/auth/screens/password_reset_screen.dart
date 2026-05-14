import 'package:faramas/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/app_colors.dart';
import '../../../config/app_routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;

  int _currentStep = 0;
  bool _loading = false;
  bool _otpExpired = false;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(4, (_) => TextEditingController());
    _otpFocusNodes = List.generate(4, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // === Utils ===
  String _formatPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '+255' + cleaned.substring(1);
    } else if (cleaned.startsWith('7')) {
      cleaned = '+255' + cleaned;
    } else if (!cleaned.startsWith('+255')) {
      cleaned = '+255' + cleaned;
    }
    return cleaned;
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
                  fontWeight: FontWeight.w600),
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

  // === API Calls ===
  Future<void> _requestResetToken() async {
    if (_phoneController.text.isEmpty) {
      _showPopupNotification("Please enter phone number", Colors.red.shade700);
      return;
    }

    setState(() => _loading = true);

    final formattedPhone = _formatPhone(_phoneController.text);
    print("Step 1: Sending phone: $formattedPhone");

   final url = Uri.parse(ApiConstants.requestResetToken);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"phone": formattedPhone}),
      );

      setState(() => _loading = false);

      if (response.statusCode == 200) {
        print("Step 1 Success: OTP sent successfully");
        setState(() {
          _currentStep = 1;
          _otpExpired = false;
        });
        _showPopupNotification("OTP sent to your phone", Colors.blue.shade700);
      } else {
        print("Step 1 Failed: ${response.body}");
        _showPopupNotification(response.body, Colors.red.shade700);
      }
    } catch (e) {
      setState(() => _loading = false);
      _showPopupNotification(e.toString(), Colors.red.shade700);
    }
  }

  Future<void> _resetPassword() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 4 ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showPopupNotification("Please fill all fields", Colors.red.shade700);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showPopupNotification("Passwords do not match", Colors.red.shade700);
      return;
    }

    setState(() => _loading = true);

    final formattedPhone = _formatPhone(_phoneController.text);
   final url = Uri.parse(ApiConstants.resetPassword);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone": formattedPhone,
          "otp": otp,
          "password": _passwordController.text,
          "confirm_password": _confirmPasswordController.text,
        }),
      );

      setState(() => _loading = false);

      if (response.statusCode == 200) {
        _showPopupNotification(
            "Password reset successfully", Colors.blue.shade700);
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      } else {
        print("Step 2 Failed: ${response.body}");
        if (response.body.contains("expired")) {
          setState(() => _otpExpired = true);
          _showPopupNotification("OTP expired, please resend",
              Colors.orange.shade700);
        } else {
          _showPopupNotification(response.body, Colors.red.shade700);
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      _showPopupNotification(e.toString(), Colors.red.shade700);
    }
  }

  // === OTP Field ===
  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 60,
      height: 64,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        onChanged: (value) {
          if (value.length == 1 && index < _otpControllers.length - 1) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
        decoration: InputDecoration(
          hintText: "0",
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // background circles (decoration)
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo/faramas_logo.png',
                      width: 140, height: 140),
                  const SizedBox(height: 20),
                  const Text(
                    'Reset Your Password',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 30),

                  if (_currentStep == 0) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon:
                            const Icon(Icons.phone, color: AppColors.primary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _requestResetToken,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Send OTP',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],

                  if (_currentStep == 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (i) => _buildOtpField(i)),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon:
                            const Icon(Icons.key, color: AppColors.primary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon:
                            const Icon(Icons.key, color: AppColors.primary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_otpExpired)
                      TextButton(
                        onPressed: _requestResetToken,
                        child: const Text("Resend OTP",
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Reset Password',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
