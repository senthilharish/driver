import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/controllers/auth_controller.dart';
import 'package:driver/utils/app_theme.dart';
import 'package:driver/utils/validators.dart';
import 'package:driver/widgets/custom_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _authController = Get.find();

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      bool success = await _authController.signUp(
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (success) {
        _showSuccessDialog(
          'Signup Successful',
          'Your driver account has been created successfully!',
          () {
            Navigator.pop(context);
            Get.offNamed('/home');
          },
        );
      } else {
        _showErrorDialog('Signup Failed', _authController.errorMessage.value);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => CustomErrorDialog(
        title: title,
        message: message,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  void _showSuccessDialog(String title, String message, VoidCallback onDismiss) {
    showDialog(
      context: context,
      builder: (context) => CustomSuccessDialog(
        title: title,
        message: message,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppPadding.lg),
              // Header
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppPadding.sm),
              Text(
                'Join us as a professional driver',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.mediumGray,
                    ),
              ),
              const SizedBox(height: AppPadding.xl),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Username Field
                    CustomTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: _usernameController,
                      icon: Icons.person,
                      inputType: TextInputType.name,
                      validator: Validators.validateUsername,
                    ),
                    const SizedBox(height: AppPadding.lg),

                    // Phone Number Field
                    CustomTextField(
                      label: 'Phone Number',
                      hint: 'Enter 10-digit phone number',
                      controller: _phoneController,
                      icon: Icons.phone,
                      inputType: TextInputType.number,
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: AppPadding.lg),

                    // Password Field
                    CustomTextField(
                      label: 'Password',
                      hint: 'Create a strong password',
                      controller: _passwordController,
                      icon: Icons.lock,
                      isPassword: true,
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: AppPadding.lg),

                    // Info Text
                    Container(
                      padding: const EdgeInsets.all(AppPadding.md),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: AppColors.infoBlue),
                          const SizedBox(width: AppPadding.md),
                          Expanded(
                            child: Text(
                              'Your phone number will be used as your login ID',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.darkGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppPadding.xl),

                    // Sign Up Button
                    Obx(
                      () => CustomButton(
                        label: 'Create Account',
                        onPressed: _handleSignUp,
                        isLoading: _authController.isLoading.value,
                        isEnabled: !_authController.isLoading.value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppPadding.lg),

              // Login Link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        'Login',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primaryYellow,
                              fontWeight: FontWeight.bold,
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
    );
  }
}
