import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import '../providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  bool _isLoggingOut = false;

  final List<Map<String, dynamic>> _recentBookings = [
    {
      'id': 'TK001',
      'type': 'Flight',
      'title': 'Turkish Airlines - JFK to IST',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'status': 'Completed',
      'amount': 299,
    },
    {
      'id': 'HT002',
      'type': 'Hotel',
      'title': 'Grand Hotel Istanbul',
      'date': DateTime.now().subtract(const Duration(days: 12)),
      'status': 'Completed',
      'amount': 150,
    },
    {
      'id': 'FL003',
      'type': 'Flight',
      'title': 'Emirates - IST to DXB',
      'date': DateTime.now().subtract(const Duration(days: 20)),
      'status': 'Cancelled',
      'amount': 599,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(authState),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (authState.isAuthenticated) ...[
                      _buildProfileStats(authState.user!),
                      const SizedBox(height: AppTheme.spacingLarge),
                      _buildQuickActions(),
                      const SizedBox(height: AppTheme.spacingLarge),
                      _buildRecentBookingsSection(),
                      const SizedBox(height: AppTheme.spacingLarge),
                    ] else if (authState.isGuest) ...[
                      _buildGuestModeContent(),
                      const SizedBox(height: AppTheme.spacingLarge),
                    ],
                    _buildSettingsSection(authState),
                    const SizedBox(height: AppTheme.spacingLarge),
                    // Additional padding to account for custom bottom navigation bar (100px height)
                    const SizedBox(height: 120), // 100px nav bar + 20px extra spacing
                  ],
                ),
              ),
            ],
          ),
          if (_isLoggingOut)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingLarge),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: AppTheme.spacingMedium),
                        Text('Signing out...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(AuthState authState) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      actions: [
        if (authState.isAuthenticated)
          IconButton(
            onPressed: () {
              _showEditProfileDialog(authState.user!);
            },
            icon: const Icon(
              Icons.edit,
              color: AppColors.textTitleColor,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppTheme.spacingLarge),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.backgroundColor,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.dividerColor,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  authState.isAuthenticated 
                      ? authState.user!.name
                      : 'Guest User',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppColors.textTitleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXSmall),
                if (authState.isAuthenticated && authState.user!.country != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.textTitleColor,
                        size: 16,
                      ),
                      const SizedBox(width: AppTheme.spacingXSmall),
                      Text(
                        authState.user!.country!,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.textTitleColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStats(User user) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Member Since',
            _getMemberSinceText(user.createdAt),
            Icons.calendar_today,
            AppColors.primaryColor,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Email Verified',
            user.isEmailVerified ? 'Yes' : 'No',
            user.isEmailVerified ? Icons.verified : Icons.pending,
            user.isEmailVerified ? AppColors.successColor : AppColors.warningColor,
          ),
          _buildStatDivider(),
          _buildStatItem(
            'Account Status',
            user.isActive ? 'Active' : 'Inactive',
            user.isActive ? Icons.check_circle : Icons.cancel,
            user.isActive ? AppColors.successColor : AppColors.errorColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXSmall),
        Text(
          title,
          style: AppTheme.bodySmall.copyWith(
            color: AppColors.fadedTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.dividerColor,
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'My Bookings',
                  Icons.calendar_today,
                  AppColors.primaryColor,
                  () => Navigator.pushNamed(context, '/bookings'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _buildQuickActionCard(
                  'Favorites',
                  Icons.favorite,
                  AppColors.errorColor,
                  () => Navigator.pushNamed(context, '/favorites'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Payment Methods',
                  Icons.payment,
                  AppColors.successColor,
                  () => _showPaymentMethods(),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _buildQuickActionCard(
                  'Support',
                  Icons.support_agent,
                  AppColors.warningColor,
                  () => _showSupport(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Bookings',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/bookings'),
                child: Text(
                  'View All',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          ...(_recentBookings.take(3).map((booking) => _buildBookingCard(booking)).toList()),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    Color statusColor;
    switch (booking['status']) {
      case 'Completed':
        statusColor = AppColors.successColor;
        break;
      case 'Cancelled':
        statusColor = AppColors.errorColor;
        break;
      default:
        statusColor = AppColors.warningColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: Icon(
              booking['type'] == 'Flight' ? Icons.flight : Icons.hotel,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['title'],
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXSmall),
                Row(
                  children: [
                    Text(
                      'ID: ${booking['id']}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.fadedTextColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: AppTheme.spacingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        booking['status'],
                        style: AppTheme.bodySmall.copyWith(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${booking['amount']}',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              Text(
                _formatDate(booking['date']),
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.fadedTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(AuthState authState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          if (authState.isAuthenticated) ...[
            _buildSettingsGroup([
              _buildSettingsTile(
                'Personal Information',
                Icons.person_outline,
                () => _showPersonalInformation(authState.user!),
              ),
              _buildSettingsTile(
                'Notifications',
                Icons.notifications_outlined,
                () => _showNotificationSettings(),
              ),
              _buildSettingsTile(
                'Security',
                Icons.security_outlined,
                () => _showSecuritySettings(),
              ),
            ]),
            const SizedBox(height: AppTheme.spacingMedium),
          ],
          const SizedBox(height: AppTheme.spacingMedium),
          _buildSettingsGroup([
            _buildSettingsTile(
              'Language',
              Icons.language_outlined,
              () => _showLanguageSettings(),
            ),
            _buildSettingsTile(
              'Currency',
              Icons.monetization_on_outlined,
              () => _showCurrencySettings(),
            ),
            _buildSettingsTile(
              'Dark Mode',
              Icons.dark_mode_outlined,
              () => _toggleDarkMode(),
              trailing: Switch(
                value: false, // This would be connected to theme state
                onChanged: (value) => _toggleDarkMode(),
                activeColor: AppColors.primaryColor,
              ),
            ),
          ]),
          const SizedBox(height: AppTheme.spacingMedium),
          _buildSettingsGroup([
            _buildSettingsTile(
              'Privacy Policy',
              Icons.privacy_tip_outlined,
              () => _showPrivacyPolicy(),
            ),
            _buildSettingsTile(
              'Terms of Service',
              Icons.description_outlined,
              () => _showTermsOfService(),
            ),
            _buildSettingsTile(
              'Help & Support',
              Icons.help_outline,
              () => _showSupport(),
            ),
          ]),
          const SizedBox(height: AppTheme.spacingMedium),
          _buildSettingsGroup([
            _buildSettingsTile(
              'Reset Onboarding (Debug)',
              Icons.refresh,
              () => _resetOnboarding(),
              textColor: AppColors.warningColor,
              iconColor: AppColors.warningColor,
            ),
            if (authState.isAuthenticated)
              _buildSettingsTile(
                'Sign Out',
                Icons.logout,
                () => _signOut(),
                textColor: AppColors.errorColor,
                iconColor: AppColors.errorColor,
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        children: tiles,
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textColor,
      ),
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          color: textColor ?? AppColors.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right,
            color: AppColors.fadedTextColor,
          ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getMemberSinceText(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference < 30) {
      return '${difference}d';
    } else if (difference < 365) {
      return '${(difference / 30).round()}m';
    } else {
      return '${(difference / 365).round()}y';
    }
  }

  Widget _buildGuestModeContent() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: AppColors.fadedTextColor,
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            'Welcome, Guest!',
            style: AppTheme.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            'Sign in or create an account to access your profile, bookings, and personalized features.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.fadedTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/sign-in');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(color: AppColors.textTitleColor),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/sign-up');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Settings actions
  void _showPersonalInformation(User user) {
    // Navigate to personal information screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${user.name}'),
            Text('Email: ${user.email}'),
            if (user.phone != null) Text('Phone: ${user.phone}'),
            if (user.country != null) Text('Country: ${user.country}'),
            Text('Role: ${user.roleDisplayName}'),
            Text('Member Since: ${_formatDate(user.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditProfileDialog(user);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => _EditProfileDialog(
        user: user,
        onProfileUpdated: (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Profile updated successfully' : 'Failed to update profile'),
                backgroundColor: success ? AppColors.successColor : AppColors.errorColor,
              ),
            );
          }
        },
        authNotifier: ref.read(authNotifierProvider.notifier),
      ),
    );
  }

  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification Settings - Coming Soon')),
    );
  }

  void _showSecuritySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Security Settings - Coming Soon')),
    );
  }

  void _showLanguageSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language Settings - Coming Soon')),
    );
  }

  void _showCurrencySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Currency Settings - Coming Soon')),
    );
  }

  void _toggleDarkMode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dark Mode Toggle - Coming Soon')),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy Policy - Coming Soon')),
    );
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms of Service - Coming Soon')),
    );
  }

  void _showPaymentMethods() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Methods - Coming Soon')),
    );
  }

  void _showSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & Support - Coming Soon')),
    );
  }

  void _resetOnboarding() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Onboarding'),
        content: const Text('This will reset the onboarding flow. The app will show onboarding screens on the next launch. This is for debugging purposes only.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Reset onboarding using the provider
              await ref.read(onboardingNotifierProvider.notifier).resetOnboarding();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Onboarding reset! Restart the app to see onboarding again.'),
                    backgroundColor: AppColors.successColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningColor),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    // Close the confirmation dialog first
    Navigator.pop(context);
    
    // Set loading state
    setState(() {
      _isLoggingOut = true;
    });
    
    try {
      // Add timeout to prevent infinite loading
      await ref.read(authNotifierProvider.notifier).logout().timeout(
        const Duration(seconds: 5),
        onTimeout: () async {
          debugPrint('Logout timeout - forcing local cleanup');
          await ref.read(authNotifierProvider.notifier).forceLogout();
        },
      );
    } catch (e) {
      debugPrint('Logout error: $e');
      await ref.read(authNotifierProvider.notifier).forceLogout();
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoggingOut ? null : () => _performLogout(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final User user;
  final Function(bool success) onProfileUpdated;
  final AuthNotifier authNotifier;

  const _EditProfileDialog({
    required this.user,
    required this.onProfileUpdated,
    required this.authNotifier,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _countryController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _countryController = TextEditingController(text: widget.user.country ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await widget.authNotifier.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      Navigator.pop(context);
      widget.onProfileUpdated(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              TextFormField(
                controller: _phoneController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              TextFormField(
                controller: _countryController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Country (optional)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
