import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_appointments_screen.dart';
import 'my_services_screen.dart';
import 'my_availability_screen.dart';
import 'my_profile_screen.dart';
import 'today_appointments_screen.dart';
import 'api_service.dart';
import 'settings_screen.dart';
import 'treatment_history_list_screen.dart';

class TherapistDashboard extends StatefulWidget {
  final Map<String, dynamic> therapistData;

  const TherapistDashboard({super.key, required this.therapistData});

  @override
  State<TherapistDashboard> createState() => _TherapistDashboardState();
}

class _TherapistDashboardState extends State<TherapistDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Online status state variables
  bool _isOnline = false;
  bool _isUpdatingStatus = false;

  // Modern color scheme
  static const Color _primaryColor = Color(0xFF9a563a);
  static const Color _surfaceColor = Color(0xFFFAFBFF);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _successColor = Color.fromARGB(255, 134, 74, 49);
  static const Color _warningColor = Color(0xFFD97706);
  static const Color _errorColor = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();

    // Initialize online status from therapist data
    _isOnline = widget.therapistData['online_status'] ?? false;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Method to handle online status changes
  Future<void> _updateOnlineStatus(bool newStatus) async {
    if (_isUpdatingStatus) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final result = await ApiService.updateOnlineStatus(isOnline: newStatus);

      if (result['success']) {
        setState(() {
          _isOnline = newStatus;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'You are now online' : 'You are now offline',
            ),
            backgroundColor: newStatus ? _successColor : _warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Revert the switch if API call failed
        setState(() {
          _isOnline = !newStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to update online status',
            ),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Revert the switch if there was an error
      setState(() {
        _isOnline = !newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: _textSecondary),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: FilledButton.styleFrom(
                backgroundColor: _errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToTodayAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TodayAppointmentsScreen(therapistData: widget.therapistData),
      ),
    );
  }

  void _navigateToTreatmentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TreatmentHistoryListScreen(therapistData: widget.therapistData),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SettingsScreen(therapistData: widget.therapistData),
      ),
    );
  }

  void _navigateToAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MyAppointmentsScreen(therapistData: widget.therapistData),
      ),
    );
  }

  void _navigateToServices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MyServicesScreen(therapistData: widget.therapistData),
      ),
    );
  }

  void _navigateToAvailability() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MyAvailabilityScreen(therapistData: widget.therapistData),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MyProfileScreen(therapistData: widget.therapistData),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final therapist = widget.therapistData;
    final services = therapist['services'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        surfaceTintColor: _cardColor,
        shadowColor: Colors.black.withOpacity(0.1),
        scrolledUnderElevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 22),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout_rounded, size: 22),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildModernDrawer(therapist),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header with Online Status
                _buildWelcomeHeader(therapist),
                const SizedBox(height: 24),

                // Today's Appointments Button - Featured
                _buildTodayAppointmentsButton(),
                const SizedBox(height: 24),

                // Quick Stats
                // _buildQuickStats(services, therapist),
                // const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 32),

                // Profile Overview
                _buildProfileOverview(therapist),
                const SizedBox(height: 24),

                // Services Overview
                if (services.isNotEmpty) ...[
                  _buildServicesOverview(services),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayAppointmentsButton() {
    return GestureDetector(
      onTap: _navigateToTodayAppointments,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_successColor, _successColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _successColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.today_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Appointments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View your schedule for today',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawer(Map<String, dynamic> therapist) {
    return Drawer(
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Modern Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: therapist['image'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            therapist['image'],
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            therapist['name']?.substring(0, 1).toUpperCase() ??
                                'T',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  therapist['name'] ?? 'Therapist',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  therapist['email'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        therapist['status'] == true ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? const Color.fromARGB(
                                255,
                                255,
                                255,
                                255,
                              ).withOpacity(0.2)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _isOnline
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : const Color.fromARGB(255, 255, 255, 255),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOnline ? 'Online' : 'Offline',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Online status switch as first item
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: ListTile(
                    leading: Icon(
                      _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      color: _isOnline ? _successColor : _textSecondary,
                      size: 22,
                    ),
                    title: Text(
                      'Online Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      _isOnline
                          ? 'Available for Today New bookings'
                          : 'Not accepting bookings for today',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color.fromARGB(255, 65, 65, 65),
                      ),
                    ),
                    trailing: _isUpdatingStatus
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _primaryColor,
                              ),
                            ),
                          )
                        : Switch(
                            value: _isOnline,
                            onChanged: _isUpdatingStatus
                                ? null
                                : _updateOnlineStatus,
                            activeColor: _successColor,
                            activeTrackColor: _successColor.withOpacity(0.3),
                            inactiveThumbColor: const Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ),
                            inactiveTrackColor: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ).withOpacity(0.3),
                            trackOutlineColor: WidgetStateProperty.all(
                              const Color.fromARGB(255, 0, 0, 0),
                            ), // 🔴 border color
                            trackOutlineWidth: WidgetStateProperty.all(
                              2,
                            ), // 🔴 border width
                          ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),

                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  isSelected: true,
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.today_rounded,
                  title: 'Today\'s Appointments',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTodayAppointments();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today_rounded,
                  title: 'All Appointments',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAppointments();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assignment_rounded,
                  title: 'Treatment History',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTreatmentHistory();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.medical_services_rounded,
                  title: 'My Services',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToServices();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.schedule_rounded,
                  title: 'My Availability',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAvailability();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToProfile();
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),

                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToSettings();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  textColor: _errorColor,
                  iconColor: _errorColor,
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? _primaryColor : (iconColor ?? _textSecondary),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? _primaryColor : (textColor ?? _textPrimary),
            fontSize: 15,
          ),
        ),
        selected: isSelected,
        selectedTileColor: _primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildWelcomeHeader(Map<String, dynamic> therapist) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: therapist['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          therapist['image'],
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          therapist['name']?.substring(0, 1).toUpperCase() ??
                              'T',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _primaryColor,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      therapist['name'] ?? 'Therapist',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: therapist['status'] == true
                                      ? _successColor
                                      : _warningColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                therapist['status'] == true
                                    ? 'Active'
                                    : 'Inactive',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isOnline
                                ? const Color.fromARGB(
                                    255,
                                    255,
                                    255,
                                    255,
                                  ).withOpacity(0.2)
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _isOnline
                                      ? const Color.fromARGB(255, 254, 254, 254)
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isOnline ? 'Online' : 'Offline',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Online Status Switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Online Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isOnline
                            ? 'Available for new bookings'
                            : 'Not accepting new bookings for today',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _isUpdatingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(
                          2,
                        ), // space between border & switch
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // rounded edges
                        ),
                        child: Switch(
                          value: _isOnline,
                          onChanged: _isUpdatingStatus
                              ? null
                              : _updateOnlineStatus,
                          activeColor: _successColor,
                          activeTrackColor: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ).withOpacity(0.9),
                          inactiveThumbColor: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ),
                          inactiveTrackColor: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ).withOpacity(0.1),
                          trackOutlineColor: WidgetStateProperty.all(
                            const Color.fromARGB(255, 255, 255, 255),
                          ), // 🔴 border color
                          trackOutlineWidth: WidgetStateProperty.all(
                            2,
                          ), // 🔴 border width
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildQuickStats(List<dynamic> services, Map<String, dynamic> therapist) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: _buildStatCard(
  //           title: 'Services',
  //           value: services.length.toString(),
  //           icon: Icons.medical_services_rounded,
  //           color: _primaryColor,
  //         ),
  //       ),
  //       const SizedBox(width: 16),
  //       Expanded(
  //         child: _buildStatCard(
  //           title: 'Availability Slots',
  //           value: therapist['availability_count']?.toString() ?? '0',
  //           icon: Icons.schedule_rounded,
  //           color: _successColor,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildStatCard({
  //   required String title,
  //   required String value,
  //   required IconData icon,
  //   required Color color,
  // }) {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: _cardColor,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: _borderColor, width: 1),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.04),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(10),
  //               decoration: BoxDecoration(
  //                 color: color.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(
  //                 icon,
  //                 color: color,
  //                 size: 20,
  //               ),
  //             ),
  //             const Spacer(),
  //             Text(
  //               value,
  //               style: const TextStyle(
  //                 fontSize: 28,
  //                 fontWeight: FontWeight.w700,
  //                 color: _textPrimary,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         Text(
  //           title,
  //           style: const TextStyle(
  //             fontSize: 14,
  //             color: _textSecondary,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'All Appointments',
                subtitle: 'View & manage',
                icon: Icons.calendar_today_rounded,
                color: _successColor,
                onTap: _navigateToAppointments,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Services',
                subtitle: 'Manage offerings',
                icon: Icons.medical_services_rounded,
                color: _successColor,
                onTap: _navigateToServices,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Availability',
                subtitle: 'Set schedule',
                icon: Icons.schedule_rounded,
                color: _successColor,
                onTap: _navigateToAvailability,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Profile',
                subtitle: 'Manage profile',
                icon: Icons.person_rounded,
                color: _successColor,
                onTap: _navigateToProfile,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOverview(Map<String, dynamic> therapist) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_rounded, color: _primaryColor, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Profile Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Email', therapist['email'] ?? 'N/A'),
          _buildInfoRow('Phone', therapist['phone'] ?? 'N/A'),
          _buildInfoRow(
            'Work Start Date',
            _formatDate(therapist['work_start_date'] ?? ''),
          ),
          _buildInfoRow(
            'Last Login',
            _formatDate(therapist['last_login_at'] ?? ''),
          ),

          if (therapist['bio'] != null && therapist['bio'].isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Bio:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                therapist['bio'],
                style: const TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesOverview(List<dynamic> services) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_services_rounded,
                color: _primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'My Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${services.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...services.take(5).map<Widget>((service) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _borderColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      service['title'] ?? 'Unknown Service',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  if (service['price'] != null)
                    Text(
                      '£${service['price']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                ],
              ),
            );
          }),
          if (services.length > 5) ...[
            const SizedBox(height: 8),
            Text(
              'And ${services.length - 5} more services...',
              style: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: _textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
