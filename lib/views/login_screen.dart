import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver/controllers/auth_controller.dart';
import 'package:driver/utils/app_theme.dart';
import 'package:driver/utils/validators.dart';
import 'package:driver/widgets/custom_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _authController = Get.find();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      bool success = await _authController.login(
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (success) {
        Get.offNamed('/home');
      } else {
        _showErrorDialog('Login Failed', _authController.errorMessage.value);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppPadding.xl),
              // Header
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppPadding.sm),
              Text(
                'Login to your driver account',
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
                      hint: 'Enter your password',
                      controller: _passwordController,
                      icon: Icons.lock,
                      isPassword: true,
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: AppPadding.xl),

                    // Login Button
                    Obx(
                      () => CustomButton(
                        label: 'Login',
                        onPressed: _handleLogin,
                        isLoading: _authController.isLoading.value,
                        isEnabled: !_authController.isLoading.value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppPadding.lg),

              // Sign Up Link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => Get.toNamed('/signup'),
                      child: Text(
                        'Sign Up',
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
