import 'package:flutter/material.dart';
import 'api_service.dart';

class MyAvailabilityScreen extends StatefulWidget {
  final Map<String, dynamic> therapistData;

  const MyAvailabilityScreen({super.key, required this.therapistData});

  @override
  State<MyAvailabilityScreen> createState() => _MyAvailabilityScreenState();
}

class _MyAvailabilityScreenState extends State<MyAvailabilityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  List<dynamic> _weeklyAvailability = [];
  final Set<DateTime> _holidayRequests = <DateTime>{};
  final Set<DateTime> _approvedHolidays = <DateTime>{};
  String? _errorMessage;

  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDay;
  int _currentViewIndex = 0; // 0: Calendar, 1: Weekly Schedule

  // Modern color scheme
  static const Color _primaryColor = Color(0xFF9a563a);
  static const Color _surfaceColor = Color(0xFFFAFBFF);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _successColor = Color(0xFF059669);
  static const Color _warningColor = Color(0xFFD97706);
  static const Color _errorColor = Color(0xFFDC2626);

  final List<String> _weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

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
    _loadAvailabilityData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailabilityData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load weekly availability
      final result = await ApiService.getAvailability();

      print('🔍 API Result: $result'); // Debug print

      if (result['success']) {
        // Handle the API response structure properly
        var availabilityData = result['data'];

        // Check if data is wrapped in another structure
        if (availabilityData is Map<String, dynamic>) {
          // If data contains an 'availability' key, use that
          if (availabilityData.containsKey('availability')) {
            availabilityData = availabilityData['availability'];
          }
          // If it's just a map, convert to list
          else if (availabilityData.containsKey('data')) {
            availabilityData = availabilityData['data'];
          }
          // If it's a direct array response, use as is
          else {
            // Convert map to list if needed
            availabilityData = [availabilityData];
          }
        }

        setState(() {
          _weeklyAvailability = availabilityData is List
              ? availabilityData
              : [];
          _isLoading = false;
        });

        print('✅ Parsed availability: $_weeklyAvailability'); // Debug print

        // Load holiday requests (mock data for now)
        await _loadHolidayRequests();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load availability';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading availability: $e'); // Debug print
      setState(() {
        _errorMessage = 'Failed to load availability data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHolidayRequests() async {
    try {
      // Load calendar holidays for efficient calendar display
      final calendarResult = await ApiService.getCalendarHolidays();

      if (calendarResult['success']) {
        final data = calendarResult['data'];

        setState(() {
          // Clear existing sets
          _holidayRequests.clear();
          _approvedHolidays.clear();

          // Parse pending holidays
          if (data['pending_holidays'] != null) {
            for (String dateString in data['pending_holidays']) {
              try {
                final date = DateTime.parse(dateString);
                _holidayRequests.add(date);
              } catch (e) {
                print('Error parsing pending holiday date: $dateString');
              }
            }
          }

          // Parse approved holidays
          if (data['approved_holidays'] != null) {
            for (String dateString in data['approved_holidays']) {
              try {
                final date = DateTime.parse(dateString);
                _approvedHolidays.add(date);
              } catch (e) {
                print('Error parsing approved holiday date: $dateString');
              }
            }
          }
        });

        print(
          '✅ Loaded holidays - Pending: ${_holidayRequests.length}, Approved: ${_approvedHolidays.length}',
        );
      } else {
        print(
          '❌ Failed to load calendar holidays: ${calendarResult['message']}',
        );
        // Keep existing mock data as fallback
      }
    } catch (e) {
      print('❌ Error loading holiday requests: $e');
      // Keep existing mock data as fallback
    }
  }

  Future<void> _refreshData() async {
    await _loadAvailabilityData();
  }

  String _formatTime(String timeString) {
    try {
      final time = DateTime.parse('2024-01-01 $timeString');
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return timeString;
    }
  }

  Map<String, dynamic>? _getAvailabilityForDay(String dayOfWeek) {
    try {
      if (_weeklyAvailability.isEmpty) return null;

      for (var availability in _weeklyAvailability) {
        if (availability is Map<String, dynamic>) {
          final apiDay =
              availability['day_of_week']?.toString().toLowerCase() ?? '';
          if (apiDay == dayOfWeek.toLowerCase()) {
            return availability;
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting availability for $dayOfWeek: $e');
      return null;
    }
  }

  bool _isWorkingDay(DateTime day) {
    final dayOfWeek = _getDayOfWeekString(day.weekday);
    final availability = _getAvailabilityForDay(dayOfWeek);
    return availability != null && availability['is_active'] == true;
  }

  bool _isHolidayRequested(DateTime day) {
    return _holidayRequests.any((holiday) => _isSameDay(holiday, day));
  }

  bool _isApprovedHoliday(DateTime day) {
    return _approvedHolidays.any((holiday) => _isSameDay(holiday, day));
  }

  bool _isSameDay(DateTime day1, DateTime day2) {
    return day1.year == day2.year &&
        day1.month == day2.month &&
        day1.day == day2.day;
  }

  String _getDayOfWeekString(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  void _requestHoliday(DateTime selectedDate) {
    if (selectedDate.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    )) {
      _showErrorMessage('Cannot request holiday for past dates');
      return;
    }

    if (_isApprovedHoliday(selectedDate)) {
      _showErrorMessage('This date is already an approved holiday');
      return;
    }

    if (_isHolidayRequested(selectedDate)) {
      _showErrorMessage('Holiday request already exists for this date');
      return;
    }

    _showHolidayRequestDialog(selectedDate);
  }

  void _showHolidayRequestDialog(DateTime selectedDate) {
    final TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.beach_access_rounded,
                      color: _warningColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Request Holiday',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Date:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Reason for Holiday Request',
                      hintText:
                          'Please provide a reason for your holiday request...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (reasonController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please provide a reason for the holiday request',
                                ),
                                backgroundColor: _errorColor,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isSubmitting = true;
                          });

                          try {
                            // Format date for API (YYYY-MM-DD)
                            final dateString = selectedDate
                                .toIso8601String()
                                .split('T')[0];

                            final result = await ApiService.requestHoliday(
                              date: dateString,
                              reason: reasonController.text.trim(),
                            );

                            if (result['success']) {
                              // Add to local state
                              this.setState(() {
                                _holidayRequests.add(selectedDate);
                              });

                              Navigator.of(context).pop();
                              _showSuccessMessage(
                                result['message'] ??
                                    'Holiday request submitted successfully',
                              );

                              // Refresh holiday data
                              await _loadHolidayRequests();
                            } else {
                              _showErrorMessage(
                                result['message'] ??
                                    'Failed to submit holiday request',
                              );
                            }
                          } catch (e) {
                            print('❌ Error submitting holiday request: $e');
                            _showErrorMessage(
                              'Failed to submit holiday request: ${e.toString()}',
                            );
                          } finally {
                            setState(() {
                              isSubmitting = false;
                            });
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        title: const Text(
          'My Availability',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        surfaceTintColor: _cardColor,
        shadowColor: Colors.black.withOpacity(0.1),
        scrolledUnderElevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggle(Icons.calendar_month_rounded, 0),
                _buildViewToggle(Icons.list_rounded, 1),
              ],
            ),
          ),
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                )
              : _errorMessage != null
              ? _buildErrorState()
              : _buildAvailabilityContent(),
        ),
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, int index) {
    final isSelected = _currentViewIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentViewIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : _textSecondary,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: _errorColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _refreshData,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Header
          _buildStatsHeader(),
          const SizedBox(height: 24),

          // View Content
          if (_currentViewIndex == 0) ...[
            _buildCustomCalendar(),
            const SizedBox(height: 24),
            _buildHolidayRequestsSummary(),
          ] else ...[
            _buildWeeklySchedule(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final activeSlots = _weeklyAvailability
        .where((slot) => slot['is_active'] == true)
        .length;

    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.schedule_rounded,
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
                  'Weekly Availability',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$activeSlots Active Days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
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
                    '${_holidayRequests.length} pending holiday requests',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCalendar() {
    return Container(
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
        children: [
          // Calendar Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: _primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Availability Calendar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Request Holiday',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Month Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: _surfaceColor,
                    foregroundColor: _textPrimary,
                  ),
                ),
                Text(
                  _getMonthYearString(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: _surfaceColor,
                    foregroundColor: _textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Calendar Grid
          _buildCalendarGrid(),

          // Calendar Legend
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Flexible(
                      child: _buildLegendItem(
                        color: _successColor,
                        label: 'Available',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    Flexible(
                      child: _buildLegendItem(
                        color: _warningColor,
                        label: 'Holiday Requested',
                        icon: Icons.pending_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildLegendItem(
                  color: _errorColor,
                  label: 'Holiday Approved',
                  icon: Icons.beach_access_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    final startDate = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday - 1),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),

          // Calendar days - Fixed to show 6 weeks maximum
          ...List.generate(6, (weekIndex) {
            final weekStartDate = startDate.add(Duration(days: weekIndex * 7));

            // Check if this week contains any days from current month
            bool hasCurrentMonthDays = false;
            for (int i = 0; i < 7; i++) {
              final checkDate = weekStartDate.add(Duration(days: i));
              if (checkDate.month == _selectedMonth.month) {
                hasCurrentMonthDays = true;
                break;
              }
            }

            // Only show weeks that have days from current month
            if (!hasCurrentMonthDays) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final date = weekStartDate.add(Duration(days: dayIndex));
                  final isCurrentMonth = date.month == _selectedMonth.month;
                  final isToday = _isSameDay(date, DateTime.now());
                  final isWorkingDay = _isWorkingDay(date);
                  final isHolidayRequested = _isHolidayRequested(date);
                  final isApprovedHoliday = _isApprovedHoliday(date);

                  return Expanded(
                    child: GestureDetector(
                      onTap: isCurrentMonth && isWorkingDay
                          ? () => _requestHoliday(date)
                          : null,
                      child: Container(
                        height: 48,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _getDayBackgroundColor(
                            date,
                            isCurrentMonth,
                            isWorkingDay,
                            isHolidayRequested,
                            isApprovedHoliday,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: isToday
                              ? Border.all(color: _primaryColor, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _getDayTextColor(
                                date,
                                isCurrentMonth,
                                isWorkingDay,
                                isHolidayRequested,
                                isApprovedHoliday,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }).where((widget) => widget is! SizedBox),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getDayBackgroundColor(
    DateTime date,
    bool isCurrentMonth,
    bool isWorkingDay,
    bool isHolidayRequested,
    bool isApprovedHoliday,
  ) {
    if (!isCurrentMonth) return Colors.transparent;

    if (isApprovedHoliday) return _errorColor.withOpacity(0.1);
    if (isHolidayRequested) return _warningColor.withOpacity(0.1);
    if (isWorkingDay) return _successColor.withOpacity(0.1);

    return Colors.transparent;
  }

  Color _getDayTextColor(
    DateTime date,
    bool isCurrentMonth,
    bool isWorkingDay,
    bool isHolidayRequested,
    bool isApprovedHoliday,
  ) {
    if (!isCurrentMonth) return _textSecondary.withOpacity(0.3);

    if (isApprovedHoliday) return _errorColor;
    if (isHolidayRequested) return _warningColor;
    if (isWorkingDay) return _successColor;

    return _textSecondary;
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySchedule() {
    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.view_week_rounded, color: _primaryColor, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Weekly Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_weekDays.length, (index) {
            final dayName = _weekDays[index];
            final availability = _getAvailabilityForDay(dayName);
            final isActive = availability?['is_active'] == true;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive
                    ? _successColor.withOpacity(0.05)
                    : _surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? _successColor.withOpacity(0.2)
                      : _borderColor.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isActive ? _successColor : _textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName.substring(0, 1).toUpperCase() +
                              dayName.substring(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        if (availability != null && isActive) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_formatTime(availability['start_time'])} - ${_formatTime(availability['end_time'])}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: _textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Not Available',
                            style: TextStyle(
                              fontSize: 14,
                              color: _textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _successColor.withOpacity(0.1)
                          : _textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive ? _successColor : _textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHolidayRequestsSummary() {
    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.beach_access_rounded,
                  color: _warningColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Holiday Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_holidayRequests.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_holidayRequests.isEmpty && _approvedHolidays.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.beach_access_rounded,
                      size: 48,
                      color: _textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Holiday Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap on working days in the calendar above to request holidays',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Pending Requests
            if (_holidayRequests.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _warningColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.pending_outlined,
                            color: _warningColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pending Requests (${_holidayRequests.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _warningColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _holidayRequests
                            .map(
                              (date) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _warningColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _warningColor,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Approved Holidays
            if (_approvedHolidays.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _errorColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: _errorColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Approved Holidays (${_approvedHolidays.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _errorColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _approvedHolidays
                            .map(
                              (date) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _errorColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _errorColor,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
