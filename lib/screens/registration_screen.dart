import 'package:faramas/config/app_routes.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../l10n/app_localizations.dart';
import 'package:faramas/widgets/input_widget.dart';
import 'package:faramas/services/auth_services.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  // final _mobileController = TextEditingController(text: '+255');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // final _locationController = TextEditingController();
  // final _dobController = TextEditingController();
  final _serviceChargeController = TextEditingController();
  // String _selectedGender = 'Male';
  // final List<String> _genders = ['Male', 'Female', 'Other'];

  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final authService = AuthService();
  int _selectedUserType = 0;
  bool _isLoading = false;

  void _toggleAcceptTerms(bool? value) {
    setState(() {
      _acceptTerms = value ?? false;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  // 0: none, 1: Customer, 2: Broker, 3: Property Owner
  void _selectUserType(int type) {
    setState(() {
      _selectedUserType = type;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // String _getGenderTranslation(BuildContext context, String gender) {
  //   final localizations = AppLocalizations.of(context);
  //   switch (gender.toLowerCase()) {
  //     case 'male':
  //       return localizations?.male ?? 'Male';
  //     case 'female':
  //       return localizations?.female ?? 'Female';
  //     case 'other':
  //       return localizations?.other ?? 'Other';
  //     default:
  //       return gender;
  //   }
  // }

  // Future<void> _selectDate(BuildContext context) async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(1900),
  //     lastDate: DateTime.now(),
  //   );
  //   if (picked != null && mounted) {
  //     setState(() {
  //       // Format the date as YYYY-MM-DD
  //       _dobController.text =
  //           "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
  //     });
  //   }
  // }

  void _signUp() async {
    final localizations = AppLocalizations.of(context);

    if (!_acceptTerms) {
      _showSnackBar(
          localizations?.acceptTerms ?? 'Please accept the Terms & Conditions');
      return;
    }

    if (_selectedUserType == 0) {
      _showSnackBar(
          localizations?.pleaseSelectUserType ?? 'Please select a user type');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar(localizations?.passwordMustMatch ?? 'Password must match');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
        .hasMatch(_emailController.text.trim())) {
      _showSnackBar(
          localizations?.invalidEmail ?? 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final role = _mapUserTypeToRole(_selectedUserType);
      final response = await authService.userRegistration(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        // phone: _mobileController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        role: role,
        // location: _locationController.text.trim(),
        // gender: _selectedGender,
        // dateOfBirth: _dobController.text.trim(),
        serviceCharge: (_selectedUserType == 2 || _selectedUserType == 3)
            ? _serviceChargeController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showSnackBar(response['msg'] ??
          (localizations?.accountCreatedSuccess ??
              'Account created successfully!'));
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print(e);
      _showSnackBar('$e');
    }
  }

  String _mapUserTypeToRole(int type) {
    switch (type) {
      case 1:
        return 'customer';
      case 2:
        return 'broker';
      case 3:
        return 'property owner';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(localizations?.createAccountTitle ?? 'Create an Account'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Image.asset(
              "assets/logo/faramas_logo.png",
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _UserTypeCheckbox(
                  label: localizations?.customer ?? 'Customer',
                  selected: _selectedUserType == 1,
                  onTap: () => _selectUserType(1),
                ),
                const SizedBox(width: 10),
                _UserTypeCheckbox(
                  label: localizations?.broker ?? 'Broker',
                  selected: _selectedUserType == 2,
                  onTap: () => _selectUserType(2),
                ),
                const SizedBox(width: 10),
                _UserTypeCheckbox(
                  label: localizations?.propertyOwner ?? 'Property Owner',
                  selected: _selectedUserType == 3,
                  onTap: () => _selectUserType(3),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
                controller: _firstNameController,
                decoration: inputDecoration(
                    localizations?.firstName ?? 'First Name', Icons.person)),
            const SizedBox(height: 15),
            TextField(
              controller: _lastNameController,
              decoration: inputDecoration(
                  localizations?.lastName ?? 'Last Name', Icons.person),
            ),
            const SizedBox(height: 15),
            if (_selectedUserType == 2 || _selectedUserType == 3)
              TextField(
                controller: _serviceChargeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: inputDecoration(
                  localizations?.serviceCharge ?? 'Service Charge',
                  Icons.money,
                  suffix: const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Text('Tsh.'),
                  ),
                ),
              ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              decoration: inputDecoration(
                  localizations?.email ?? 'Email Address', Icons.email),
            ),
            const SizedBox(height: 15),

            const SizedBox(height: 15),
            TextField(
              controller: _usernameController,
              keyboardType: TextInputType.text,
              decoration: inputDecoration(
                  localizations?.username ?? 'Username', Icons.person),
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
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: inputDecoration(
                localizations?.confirmPassword ?? 'Confirm Password',
                Icons.lock,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: _toggleConfirmPasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: _toggleAcceptTerms,
                ),
                Expanded(
                  child: Text(localizations?.acceptTerms ??
                      'Please accept the Terms & Conditions to SignUp'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: Text(
                        localizations?.signUp ?? 'Sign Up',
                        style: const TextStyle(color: AppColors.textLight),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _UserTypeCheckbox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UserTypeCheckbox({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.blueAccent : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
