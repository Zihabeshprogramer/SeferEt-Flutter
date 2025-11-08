import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_theme.dart';
import '../../../providers/auth_provider.dart';

class SignUpView extends ConsumerStatefulWidget {
  const SignUpView({super.key});

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isChecked = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await ref.read(authNotifierProvider.notifier).register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        // Navigate to home on successful registration
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      } else {
        // Show error message
        final error = ref.read(authNotifierProvider.notifier).getAndClearError();
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

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
              _buildHeader(context),
              const SizedBox(height: AppTheme.spacingLarge),
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight - keyboardHeight - 160,
                    ),
                    child: IntrinsicHeight(
                      child: _buildAuthForm(context),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildBackButton(),
          const SizedBox(width: AppTheme.spacingLarge),
          _buildWelcomeText(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return ElevatedButton(
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
    );
  }

  Widget _buildWelcomeText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 250,
          height: 50,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Create Account',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: AppTheme.spacingSmall),
        Text(
          'Let\'s create your account',
          style: TextStyle(
            color: AppColors.textColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFullNameField(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildEmailField(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildPasswordField(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildConfirmPasswordField(),
            const SizedBox(height: AppTheme.spacingSmall + AppTheme.spacingXSmall),
            _buildSignUpButton(),
            const SizedBox(height: AppTheme.spacingSmall + AppTheme.spacingXSmall),
            _buildDividerSection(),
            const SizedBox(height: AppTheme.spacingMedium - AppTheme.spacingXSmall),
            _buildGoogleSignUpButton(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildSignInPrompt(),
          ],
        ),
      ),
    );
  }

  Widget _buildFullNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Full name",
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        TextFormField(
          controller: _nameController,
          enabled: !_isLoading,
          textCapitalization: TextCapitalization.words,
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.textColor,
          ),
          decoration: InputDecoration(
            labelText: "Enter your full name",
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
      ],
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
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Password",
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          enabled: !_isLoading,
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.textColor,
          ),
          decoration: InputDecoration(
            labelText: "Enter your password",
            labelStyle: AppTheme.placeholderText,
            filled: true,
            fillColor: AppColors.backgroundColor,
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.placeholderTextColor),
            ),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.secondaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.secondaryColor,
              ),
              onPressed: _isLoading ? null : () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Confirm Password",
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isPasswordVisible,
          enabled: !_isLoading,
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.textColor,
          ),
          decoration: InputDecoration(
            labelText: "Confirm your password",
            labelStyle: AppTheme.placeholderText,
            filled: true,
            fillColor: AppColors.backgroundColor,
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.placeholderTextColor),
            ),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.secondaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.secondaryColor,
              ),
              onPressed: _isLoading ? null : () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingLarge),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
          minimumSize: const Size(double.infinity, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusXSmall),
          ),
        ),
        onPressed: _isLoading ? null : _handleSignUp,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textTitleColor),
                ),
              )
            : Text(
                "Sign Up",
                style: AppTheme.buttonText,
              ),
      ),
    );
  }

  Widget _buildDividerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLarge),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.greyDividerColor,
              thickness: 1,
              endIndent: AppTheme.spacingSmall + AppTheme.spacingXSmall,
            ),
          ),
          Text(
            "or",
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.fadedTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.greyDividerColor,
              thickness: 1,
              indent: AppTheme.spacingSmall + AppTheme.spacingXSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignUpButton() {
    return OutlinedButton.icon(
      icon: Image.asset('assets/images/google_icon.png', width: AppTheme.iconSizeMedium),
      label: Text(
        "Continue with Google",
        style: AppTheme.bodyLarge.copyWith(
          color: AppColors.textColor,
        ),
      ),
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
        side: const BorderSide(color: AppColors.fadedTextColor),
        minimumSize: const Size(double.infinity, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
        ),
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Do you have an account? ",
            style: AppTheme.fadedText,
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/sign-in');
            },
            child: Text(
              "Sign In",
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
