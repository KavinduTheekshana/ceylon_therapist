import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> therapistData;

  const SettingsScreen({super.key, required this.therapistData});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Loading and saving states
  bool _isLoading = true;
  bool _isSaving = false;

  // Service User Selection Filters
  String _selectedGender = 'all'; // all, male, female
  RangeValues _ageRange = const RangeValues(18, 65);
  String _preferredLanguage = 'english';
  bool _acceptNewPatients = true;
  bool _homeVisitsOnly = false;
  bool _clinicVisitsOnly = false;
  String _maxTravelDistance = '10'; // in miles
  bool _weekendsAvailable = false;
  bool _eveningsAvailable = false;

  // App Settings (still local only)
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _theme = 'light'; // light, dark, system

  // Available options
  final List<String> _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Bengali',
    'Gujarati',
    'Malayalam',
    'Kannada',
    'Punjabi',
    'Marathi',
  ];

  final List<String> _distances = ['5', '10', '15', '20', '25', '30', '50'];

  // Modern color scheme
  static const Color _primaryColor = Color(0xFF9a563a);
  static const Color _surfaceColor = Color(0xFFFAFBFF);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _successColor = Color(0xFF059669);
  static const Color _errorColor = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _animationController.forward();
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load preferences from API
      final apiResult = await ApiService.getTherapistPreferences();

      if (apiResult['success']) {
        final preferences = apiResult['data'];
        final serviceUser = preferences['service_user_preferences'];
        final serviceDelivery = preferences['service_delivery'];

        setState(() {
          // Service User Preferences from API
          _selectedGender = serviceUser['preferred_gender'] ?? 'all';
          _ageRange = RangeValues(
            (serviceUser['age_range']['start'] ?? 18).toDouble(),
            (serviceUser['age_range']['end'] ?? 65).toDouble(),
          );
          _preferredLanguage = serviceUser['preferred_language'] ?? 'english';

          // Service Delivery from API
          _acceptNewPatients = serviceDelivery['accept_new_patients'] ?? true;
          _homeVisitsOnly = serviceDelivery['home_visits_only'] ?? false;
          _clinicVisitsOnly = serviceDelivery['clinic_visits_only'] ?? false;
          _maxTravelDistance =
              serviceDelivery['max_travel_distance']?.toString() ?? '10';
          _weekendsAvailable = serviceDelivery['weekends_available'] ?? false;
          _eveningsAvailable = serviceDelivery['evenings_available'] ?? false;
        });
      }

      // Load local app settings
      await _loadLocalSettings();
    } catch (e) {
      print('Error loading settings: $e');
      _showErrorMessage('Failed to load settings from server');
      // Try to load local fallback
      await _loadLocalSettings();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add these methods to your _SettingsScreenState class in settings_screen.dart

  // Add this method for account deletion
// Replace the _showDeleteAccountDialog method with this fixed version:

Future<void> _showDeleteAccountDialog() async {
  // First check if account can be deleted
  setState(() {
    _isLoading = true;
  });

  final accountInfo = await ApiService.getAccountDeletionInfo();

  setState(() {
    _isLoading = false;
  });

  if (!accountInfo['success']) {
    _showErrorMessage(
      'Failed to check account status: ${accountInfo['message']}',
    );
    return;
  }

  final data = accountInfo['data'];
  final hasPendingAppointments = data['pending_bookings_count'] > 0;
  final upcomingAppointments = data['pending_bookings_count'] ?? 0;

  if (hasPendingAppointments) {
    // Show warning about pending appointments
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Cannot Delete Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have $upcomingAppointments pending appointment${upcomingAppointments == 1 ? '' : 's'}. You must complete or cancel all appointments before deleting your account.',
                style: const TextStyle(color: _textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please manage your appointments first, then try again.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: _primaryColor)),
            ),
          ],
        );
      },
    );
    return;
  }

  // Show deletion confirmation dialog
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  bool isDeleting = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          // Add listener to password controller for real-time updates
          void onPasswordChanged() {
            setDialogState(() {}); // Rebuild when password changes
          }

          // Add the listener if not already added
          if (!passwordController.hasListeners) {
            passwordController.addListener(onPasswordChanged);
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.delete_forever_rounded,
                  color: _errorColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _errorColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: _errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'This action cannot be undone',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _errorColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deleting your account will permanently remove:\n• Your profile and credentials\n• All appointment history\n• Personal preferences\n• Any stored data',
                          style: TextStyle(
                            color: _errorColor.withOpacity(0.9),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Enter your password to confirm:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    enabled: !isDeleting,
                    decoration: InputDecoration(
                      hintText: 'Your current password',
                      hintStyle: const TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reason for deletion (optional):',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    enabled: !isDeleting,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Help us improve by sharing why you\'re leaving...',
                      hintStyle: const TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () {
                        passwordController.dispose();
                        reasonController.dispose();
                        Navigator.of(dialogContext).pop();
                      },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: _textSecondary),
                ),
              ),
              FilledButton(
                // Fixed condition - now checks current text value
                onPressed: isDeleting || passwordController.text.trim().isEmpty
                    ? null
                    : () async {
                        setDialogState(() {
                          isDeleting = true;
                        });

                        final result = await ApiService.deleteAccount(
                          password: passwordController.text.trim(),
                          reason: reasonController.text.trim().isEmpty
                              ? null
                              : reasonController.text.trim(),
                        );

                        passwordController.dispose();
                        reasonController.dispose();
                        Navigator.of(dialogContext).pop();

                        if (result['success']) {
                          // Account deleted successfully, navigate to login
                          _showSuccessMessage('Account deleted successfully');
                          Navigator.of(context).pushReplacementNamed('/login');
                        } else {
                          _showErrorMessage(
                            result['message'] ?? 'Failed to delete account',
                          );
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: _errorColor,
                  foregroundColor: Colors.white,
                ),
                child: isDeleting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Deleting...'),
                        ],
                      )
                    : const Text('Delete Account'),
              ),
            ],
          );
        },
      );
    },
  );
}

  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        // App Settings (local only)
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        _theme = prefs.getString('theme') ?? 'light';
      });
    } catch (e) {
      print('Error loading local settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Save preferences to API
      final apiResult = await ApiService.updateTherapistPreferences(
        preferredGender: _selectedGender,
        ageRangeStart: _ageRange.start.round(),
        ageRangeEnd: _ageRange.end.round(),
        preferredLanguage: _preferredLanguage,
        acceptNewPatients: _acceptNewPatients,
        homeVisitsOnly: _homeVisitsOnly,
        clinicVisitsOnly: _clinicVisitsOnly,
        maxTravelDistance: int.parse(_maxTravelDistance),
        weekendsAvailable: _weekendsAvailable,
        eveningsAvailable: _eveningsAvailable,
      );

      if (apiResult['success']) {
        // Save local app settings
        await _saveLocalSettings();
        _showSuccessMessage('Settings saved successfully');
      } else {
        // Handle validation errors
        if (apiResult['errors'] != null) {
          String errorMessage = 'Validation errors:\n';
          final errors = apiResult['errors'];
          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessage += '• ${messages.join(', ')}\n';
            }
          });
          _showErrorMessage(errorMessage);
        } else {
          _showErrorMessage(
            apiResult['message'] ?? 'Failed to save preferences',
          );
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to save settings: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save app settings locally
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
      await prefs.setString('theme', _theme);
    } catch (e) {
      print('Error saving local settings: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Reset Settings',
            style: TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
          ),
          content: const Text(
            'Are you sure you want to reset all settings to default values? This will update your server preferences.',
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: _textSecondary),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();

                setState(() {
                  _isSaving = true;
                });

                try {
                  // Reset preferences on server
                  final result = await ApiService.resetTherapistPreferences();

                  if (result['success']) {
                    // Update local state with server response
                    final preferences = result['data'];
                    final serviceUser = preferences['service_user_preferences'];
                    final serviceDelivery = preferences['service_delivery'];

                    setState(() {
                      _selectedGender = serviceUser['preferred_gender'];
                      _ageRange = RangeValues(
                        serviceUser['age_range']['start'].toDouble(),
                        serviceUser['age_range']['end'].toDouble(),
                      );
                      _preferredLanguage = serviceUser['preferred_language'];
                      _acceptNewPatients =
                          serviceDelivery['accept_new_patients'];
                      _homeVisitsOnly = serviceDelivery['home_visits_only'];
                      _clinicVisitsOnly = serviceDelivery['clinic_visits_only'];
                      _maxTravelDistance =
                          serviceDelivery['max_travel_distance'].toString();
                      _weekendsAvailable =
                          serviceDelivery['weekends_available'];
                      _eveningsAvailable =
                          serviceDelivery['evenings_available'];

                      // Reset local settings too
                      _notificationsEnabled = true;
                      _soundEnabled = true;
                      _vibrationEnabled = true;
                      _theme = 'light';
                    });

                    await _saveLocalSettings();
                    _showSuccessMessage('Settings reset to defaults');
                  } else {
                    _showErrorMessage(
                      result['message'] ?? 'Failed to reset preferences',
                    );
                  }
                } catch (e) {
                  _showErrorMessage(
                    'Failed to reset settings: ${e.toString()}',
                  );
                } finally {
                  setState(() {
                    _isSaving = false;
                  });
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: _errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        surfaceTintColor: _cardColor,
        shadowColor: Colors.black.withOpacity(0.1),
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _resetToDefaults,
            icon: const Icon(Icons.restore_rounded, size: 22),
            tooltip: 'Reset to Defaults',
          ),
          IconButton(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 22),
            tooltip: 'Save Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service User Preferences
                      _buildSectionCard(
                        'Service User Preferences',
                        Icons.people_rounded,
                        [
                          _buildGenderSelection(),
                          const SizedBox(height: 20),
                          _buildAgeRangeSlider(),
                          const SizedBox(height: 20),
                          _buildLanguageDropdown(),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Service Delivery Preferences
                      _buildSectionCard(
                        'Service Delivery',
                        Icons.location_on_rounded,
                        [
                          _buildVisitTypeToggles(),
                          const SizedBox(height: 20),
                          _buildTravelDistanceDropdown(),
                          const SizedBox(height: 20),
                          _buildAvailabilityToggles(),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // General Settings (Local only)
                      _buildSectionCard(
                        'App Settings',
                        Icons.settings_rounded,
                        [
                          _buildGeneralToggles(),
                          const SizedBox(height: 20),
                          _buildThemeSelection(),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildSectionCard(
                        'Account Management',
                        Icons.account_circle_rounded,
                        [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _errorColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _errorColor.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: _errorColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Danger Zone',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _errorColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Once you delete your account, there is no going back. Please be certain.',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isSaving || _isLoading
                                        ? null
                                        : _showDeleteAccountDialog,
                                    icon: const Icon(
                                      Icons.delete_forever_rounded,
                                      size: 20,
                                    ),
                                    label: const Text('Delete My Account'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _errorColor,
                                      side: BorderSide(
                                        color: _errorColor,
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                   const SizedBox(height: 24),
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Saving...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_rounded, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      'Save All Settings',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _primaryColor, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender Preference',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                'all',
                'All Genders',
                Icons.people_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption(
                'male',
                'Male Only',
                Icons.male_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption(
                'female',
                'Female Only',
                Icons.female_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () {
              setState(() {
                _selectedGender = value;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : _borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? _primaryColor : _textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _primaryColor : _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Age Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: _ageRange,
          min: 16,
          max: 80,
          divisions: 64,
          activeColor: _primaryColor,
          inactiveColor: _primaryColor.withOpacity(0.2),
          labels: RangeLabels(
            _ageRange.start.round().toString(),
            _ageRange.end.round().toString(),
          ),
          onChanged: _isSaving
              ? null
              : (RangeValues values) {
                  setState(() {
                    _ageRange = values;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred Communication Language',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _preferredLanguage,
              onChanged: _isSaving
                  ? null
                  : (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _preferredLanguage = newValue;
                        });
                      }
                    },
              items: _languages.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value.toLowerCase(),
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 14, color: _textPrimary),
                  ),
                );
              }).toList(),
              icon: Icon(Icons.arrow_drop_down_rounded, color: _textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitTypeToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visit Type Preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          'Accept New Patients',
          'Allow new patient bookings',
          _acceptNewPatients,
          (value) => setState(() => _acceptNewPatients = value),
          Icons.person_add_rounded,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          'Home Visits Only',
          'Only provide services at patient\'s location',
          _homeVisitsOnly,
          (value) => setState(() {
            _homeVisitsOnly = value;
            if (value) _clinicVisitsOnly = false;
          }),
          Icons.home_rounded,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          'Clinic Visits Only',
          'Only provide services at clinic location',
          _clinicVisitsOnly,
          (value) => setState(() {
            _clinicVisitsOnly = value;
            if (value) _homeVisitsOnly = false;
          }),
          Icons.local_hospital_rounded,
        ),
      ],
    );
  }

  Widget _buildTravelDistanceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maximum Travel Distance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _maxTravelDistance,
              onChanged: _isSaving
                  ? null
                  : (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _maxTravelDistance = newValue;
                        });
                      }
                    },
              items: _distances.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    '$value miles',
                    style: const TextStyle(fontSize: 14, color: _textPrimary),
                  ),
                );
              }).toList(),
              icon: Icon(Icons.arrow_drop_down_rounded, color: _textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Extended Availability',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          'Weekend Availability',
          'Available on Saturdays and Sundays',
          _weekendsAvailable,
          (value) => setState(() => _weekendsAvailable = value),
          Icons.weekend_rounded,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          'Evening Availability',
          'Available after 6 PM on weekdays',
          _eveningsAvailable,
          (value) => setState(() => _eveningsAvailable = value),
          Icons.nights_stay_rounded,
        ),
      ],
    );
  }

  Widget _buildGeneralToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'App Preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSwitchTile(
          'Push Notifications',
          'Receive appointment and booking alerts',
          _notificationsEnabled,
          (value) => setState(() => _notificationsEnabled = value),
          Icons.notifications_rounded,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          'Sound Alerts',
          'Play sounds for notifications and alerts',
          _soundEnabled,
          (value) => setState(() => _soundEnabled = value),
          Icons.volume_up_rounded,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          'Vibration',
          'Vibrate for important notifications',
          _vibrationEnabled,
          (value) => setState(() => _vibrationEnabled = value),
          Icons.vibration_rounded,
        ),
      ],
    );
  }

  Widget _buildThemeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'App Theme',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildThemeOption(
                'light',
                'Light',
                Icons.light_mode_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemeOption('dark', 'Dark', Icons.dark_mode_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemeOption(
                'system',
                'System',
                Icons.settings_brightness_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(String value, String label, IconData icon) {
    final isSelected = _theme == value;
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () {
              setState(() {
                _theme = value;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : _borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? _primaryColor : _textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _primaryColor : _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: value ? _primaryColor : _textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value ? _primaryColor : _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: _isSaving ? null : onChanged,
            activeColor: _primaryColor,
            activeTrackColor: _primaryColor.withOpacity(0.3),
            inactiveThumbColor: _textSecondary,
            inactiveTrackColor: _borderColor,
          ),
        ],
      ),
    );
  }
}
