import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isChecked = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await ref.read(authNotifierProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
      rememberMe: isChecked,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        // Navigate to home on successful login
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

  void _handleGuestSignIn() {
    ref.read(authNotifierProvider.notifier).continueAsGuest();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
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
              'Welcome to SeferET',
              style: TextStyle(
                color: AppColors.textTitleColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: AppTheme.spacingSmall),
        Text(
          'Please Enter Your Details.',
          style: TextStyle(
            color: AppColors.textTitleColor,
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
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.borderRadiusXLarge + AppTheme.borderRadiusSmall + AppTheme.spacingXSmall),
          topRight: Radius.circular(AppTheme.borderRadiusXLarge + AppTheme.borderRadiusSmall + AppTheme.spacingXSmall),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmailField(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildPasswordField(),
            const SizedBox(height: AppTheme.spacingSmall + AppTheme.spacingXSmall),
            _buildRememberMeAndForgotPassword(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildSignInButtons(),
            const SizedBox(height: AppTheme.spacingMedium - AppTheme.spacingXSmall),
            _buildDividerSection(),
            const SizedBox(height: AppTheme.spacingMedium - AppTheme.spacingXSmall),
            _buildGoogleSignInButton(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildSignUpPrompt(),
          ],
        ),
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
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusXSmall),
              borderSide: const BorderSide(color: AppColors.placeholderTextColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusXSmall),
              borderSide: const BorderSide(color: AppColors.placeholderTextColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusXSmall),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusXSmall),
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
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusXSmall),
              borderSide: const BorderSide(color: AppColors.placeholderTextColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppColors.secondaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusXSmall),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusXSmall),
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
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: isChecked,
              checkColor: AppColors.secondaryColor,
              shape: const CircleBorder(),
              side: const BorderSide(
                color: AppColors.fadedTextColor,
                width: 1,
              ),
              onChanged: (bool? value) {
                setState(() {
                  isChecked = value!;
                });
              },
            ),
            Text(
              'Remember Me',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textColor,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/forgot-password');
          },
          child: Text(
            'Forgot password?',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.secondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
              minimumSize: const Size(double.infinity, 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusSmall),
              ),
            ),
            onPressed: _isLoading ? null : _handleSignIn,
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
                    "Sign In",
                    style: AppTheme.buttonText,
                  ),
          ),
          const SizedBox(height: AppTheme.spacingMedium - AppTheme.spacingXSmall),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundColor,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
              minimumSize: const Size(double.infinity, 20),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.secondaryColor),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + AppTheme.borderRadiusXSmall),
              ),
            ),
            onPressed: _isLoading ? null : _handleGuestSignIn,
            child: Text(
              "Sign in as a guest",
              style: AppTheme.buttonTextSecondary,
            ),
          ),
        ],
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

  Widget _buildGoogleSignInButton() {
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

  Widget _buildSignUpPrompt() {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingLarge),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: AppTheme.fadedText,
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/sign-up');
            },
            child: Text(
              "Sign Up",
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
