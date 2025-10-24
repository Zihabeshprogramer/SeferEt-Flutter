import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SizedBox(
          height: screenHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppTheme.spacingXLarge),
              _buildHeader(screenWidth),
              const SizedBox(height: AppTheme.spacingLarge),
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight - keyboardHeight - 160,
                    ),
                    child: IntrinsicHeight(
                      child: _buildFormContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildBackButton(),
          const SizedBox(width: AppTheme.spacingLarge),
          _buildHeaderText(screenWidth),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Builder(
      builder: (context) => ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(AppTheme.spacingSmall + AppTheme.spacingXSmall),
          backgroundColor: AppColors.backgroundColor,
          foregroundColor: AppColors.errorColor,
        ),
        child: const Icon(
          Icons.arrow_back,
          color: AppColors.textColor,
        ),
      ),
    );
  }

  Widget _buildHeaderText(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 250,
          height: 50,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Forget password',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Container(
          alignment: Alignment.center,
          width: screenWidth * 0.67,
          child: Text(
            'Enter your Email account to reset your password',
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              color: AppColors.textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmailField(),
          const SizedBox(height: AppTheme.spacingLarge),
          _buildSendOTPButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email",
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        TextFormField(
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.textColor,
          ),
          decoration: InputDecoration(
            labelText: "Enter your email",
            labelStyle: AppTheme.placeholderText,
            filled: true,
            fillColor: AppColors.backgroundColor,
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.placeholderTextColor),
            ),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.placeholderTextColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendOTPButton() {
    return Builder(
      builder: (context) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
          minimumSize: const Size(double.infinity, 20),
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
          ),
        ),
        onPressed: () {},
        child: Text(
          "Send OTP",
          style: AppTheme.buttonText,
        ),
      ),
    );
  }
}
