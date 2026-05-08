import 'package:faramas/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:faramas/services/auth_services.dart'; // Import your AuthService
import 'package:faramas/config/app_routes.dart'; // For navigation
import 'package:provider/provider.dart'; // For AuthProvider
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart'; // Make sure this is imported

class OtpForm extends StatefulWidget {
  final String phoneNumber; // Pass the phone number here

  const OtpForm({super.key, required this.phoneNumber});

  @override
  State<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final _formKey = GlobalKey<FormState>();
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;

  bool _isLoading = false; // To show loading state during OTP verification
  bool _canResendOtp = false; // To control resend button availability
  // Consider adding a timer for countdown for better UX
  // int _resendCountdown = 60; // Example countdown

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(4, (index) => TextEditingController());
    _otpFocusNodes = List.generate(4, (index) => FocusNode());
    // Optionally, start a resend timer here or make resend available after a delay
    _startResendTimer();
  }

  void _startResendTimer() {
    // For simplicity, let's enable resend after 60 seconds
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() {
          _canResendOtp = true;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onOtpFieldChanged(String value, int index) {
    if (value.length == 1) {
      if (index < _otpControllers.length - 1) {
        FocusScope.of(context).nextFocus();
      } else {
        // If it's the last field, unfocus the keyboard
        FocusScope.of(context).unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      // If backspace is pressed and field is empty, move to previous field
      FocusScope.of(context).previousFocus();
    }
  }

  Widget _buildOtpField(BuildContext context, int index) {
    return SizedBox(
      width: 60,
      height: 64,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        onChanged: (value) => _onOtpFieldChanged(value, index),
        decoration: InputDecoration(
          hintText: "0",
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            // Highlight focused field
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
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly
        ],
      ),
    );
  }

  Future<void> _submitOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String enteredOtp = _otpControllers.map((c) => c.text).join();

    if (enteredOtp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a complete 4-digit OTP.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final authData =
          await authService.verifyOtp(widget.phoneNumber, enteredOtp);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (authData['status'] == 'success') {
        final accessToken = authData['access'] as String;
        final refreshToken = authData['refresh'] as String;

        //Save token to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        debugPrint("Access Token Saved: $accessToken");

        // Update AuthProvider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.login(
          authData['user'] as UserModel,
          accessToken,
          refreshToken,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("OTP verified successfully! Logging in...")),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("OTP verification failed. Please try again.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
        ),
      );
      debugPrint("OTP verification error: $e");
    }
  }

  Future<void> _requestNewOtp() async {
    setState(() {
      _isLoading = true;
      _canResendOtp = false;
    });

    try {
      final authService = AuthService();
      final bool success = await authService.requestNewOtp(widget.phoneNumber);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New OTP sent to your phone.")),
        );
        _startResendTimer(); // Restart countdown for resend
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to request new OTP. Try again later.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Error requesting new OTP: ${e.toString().replaceFirst('Exception: ', '')}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OTP Verification"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Verification Code",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                "We have sent a verification code to ${widget.phoneNumber}.", // Display phone number
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                      4, (index) => _buildOtpField(context, index)),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the code?"),
                  TextButton(
                    onPressed: _canResendOtp ? _requestNewOtp : null,
                    child: Text(
                      _canResendOtp ? "Resend OTP" : "Resend in 2 m",
                      style: TextStyle(
                        color: _canResendOtp ? AppColors.primary : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Verify",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
