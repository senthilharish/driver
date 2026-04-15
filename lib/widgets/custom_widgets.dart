import 'package:flutter/material.dart';
import 'package:driver/utils/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType inputType;
  final String? Function(String?)? validator;
  final bool isPassword;
  final int maxLines;
  final void Function(String)? onChanged;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.inputType = TextInputType.text,
    this.validator,
    this.isPassword = false,
    this.maxLines = 1,
    this.onChanged,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppPadding.sm),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.inputType,
          obscureText: _obscureText,
          maxLines: _obscureText ? 1 : widget.maxLines,
          onChanged: widget.onChanged,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(
              widget.icon,
              color: AppColors.primaryYellow,
            ),
            suffixIcon: widget.isPassword
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    child: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.primaryYellow,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double width;
  final double height;

  const CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width = double.infinity,
    this.height = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.primaryBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          disabledBackgroundColor: AppColors.mediumGray,
          disabledForegroundColor: AppColors.white,
          elevation: 4,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlack),
                ),
              )
            : Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryBlack,
                      fontWeight: FontWeight.bold,
                    ),
              ),
      ),
    );
  }
}

class CustomLoadingDialog extends StatelessWidget {
  final String message;

  const CustomLoadingDialog({
    Key? key,
    this.message = 'Loading...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppPadding.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                strokeWidth: 3,
              ),
              const SizedBox(height: AppPadding.lg),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onDismiss;

  const CustomErrorDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.errorRed,
            ),
      ),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text(
            'OK',
            style: TextStyle(
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class CustomSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onDismiss;

  const CustomSuccessDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.successGreen),
          const SizedBox(width: AppPadding.md),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.successGreen,
                  ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text(
            'OK',
            style: TextStyle(
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
