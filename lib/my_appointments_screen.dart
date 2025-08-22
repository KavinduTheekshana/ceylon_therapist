import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'package:intl/intl.dart';

class MyAppointmentsScreen extends StatefulWidget {
  final Map<String, dynamic> therapistData;

  const MyAppointmentsScreen({super.key, required this.therapistData});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  List<dynamic> _appointments = [];
  List<dynamic> _filteredAppointments = [];
  String? _errorMessage;
  String _selectedStatus = 'all'; // Default filter

  // Available status filters
  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'All Status'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'confirmed', 'label': 'Confirmed'},
    {'value': 'pending_payment', 'label': 'Payment Pending'},
    {'value': 'completed', 'label': 'Completed'},
    {'value': 'cancelled', 'label': 'Cancelled'},
  ];

  // Modern color scheme
  static const Color _primaryColor = Color(0xFF9a563a);
  static const Color _surfaceColor = Color(0xFFFAFBFF);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _loadAppointments();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    try {
      final token = await ApiService.getAccessToken();
      print('Access Token: $token'); // ✅ Dart syntax

      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/therapist/bookings'),
        headers: ApiService.getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        setState(() {
          _appointments = responseData['data'] ?? [];
          _filterAppointments();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              responseData['message'] ?? 'Unable to load appointments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please check your internet.';
        _isLoading = false;
      });
    }
  }

  void _filterAppointments() {
    if (_selectedStatus == 'all') {
      _filteredAppointments = List.from(_appointments);
    } else {
      _filteredAppointments = _appointments
          .where(
            (appointment) =>
                appointment['status'].toString().toLowerCase() ==
                _selectedStatus,
          )
          .toList();
    }
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
      _filterAppointments();
    });
  }

  Future<void> _refreshAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _loadAppointments();
  }



String _formatDate(String dateString) {
  try {
    final date = DateTime.parse(dateString).toLocal();
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day)).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  } catch (e) {
    return dateString;
  }
}


  String _formatTime(String timeString) {
    try {
      final time = DateTime.parse(timeString);
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return timeString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF059669);
      case 'pending':
        return const Color(0xFFD97706);
      case 'pending_payment':
        return const Color(0xFF2563EB);
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'completed':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return 'PAYMENT PENDING';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        title: const Text(
          'My Appointments',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        surfaceTintColor: _cardColor,
        shadowColor: Colors.black.withOpacity(0.1),
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            onPressed: _refreshAppointments,
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
          child: Column(
            children: [
              // Status Filter Dropdown
              Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 18,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Filter:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _onStatusFilterChanged(newValue);
                            }
                          },
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: _textSecondary,
                          ),
                          isDense: true,
                          items: _statusFilters.map<DropdownMenuItem<String>>((
                            filter,
                          ) {
                            return DropdownMenuItem<String>(
                              value: filter['value'],
                              child: Text(
                                filter['label']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedStatus == filter['value']
                                      ? _primaryColor
                                      : _textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          dropdownColor: _cardColor,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 8,
                        ),
                      ),
                    ),
                    // Show count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_filteredAppointments.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Appointments List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: _primaryColor,
                          strokeWidth: 2,
                        ),
                      )
                    : _errorMessage != null
                    ? _buildErrorState()
                    : _filteredAppointments.isEmpty
                    ? _buildEmptyState()
                    : _buildAppointmentsList(),
              ),
            ],
          ),
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
                color: const Color(0xFFDC2626).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Color(0xFFDC2626),
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
              onPressed: _refreshAppointments,
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

  Widget _buildEmptyState() {
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
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 40,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedStatus == 'all'
                  ? 'No appointments yet'
                  : 'No ${_statusFilters.firstWhere((f) => f['value'] == _selectedStatus)['label']?.toLowerCase()} appointments',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedStatus == 'all'
                  ? 'Your upcoming appointments\nwill appear here'
                  : 'Try selecting a different status filter',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _refreshAppointments,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: const BorderSide(color: _primaryColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return RefreshIndicator(
      onRefresh: _refreshAppointments,
      color: _primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        itemCount: _filteredAppointments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final appointment = _filteredAppointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with customer name and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['customer_name'] ?? 'Unknown Customer',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ref: ${appointment['reference'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusDisplayText(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Date and time row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: _textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(appointment['date'] ?? ''),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: _textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatTime(appointment['time'] ?? ''),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Service details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment['service']['title'] ?? 'Service',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '£${appointment['price'] ?? '0'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Duration and contact
            const SizedBox(height: 16),
            Row(
              children: [
                if (appointment['service']['duration'] != null) ...[
                  Icon(Icons.schedule_rounded, size: 16, color: _textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${appointment['service']['duration']} min',
                    style: const TextStyle(fontSize: 14, color: _textSecondary),
                  ),
                  const SizedBox(width: 24),
                ],
                Icon(Icons.phone_rounded, size: 16, color: _textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment['customer_phone'] ?? 'No phone',
                    style: const TextStyle(fontSize: 14, color: _textSecondary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAppointmentDetails(appointment),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF9a563a),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                // Show confirm button only for pending status
                // if (appointment['can_update_status'] == true &&
                //     status.toLowerCase() == 'pending') ...[
                //   const SizedBox(width: 12),
                //   Expanded(
                //     child: FilledButton(
                //       onPressed: () => _confirmAppointment(appointment),
                //       style: FilledButton.styleFrom(
                //         backgroundColor: const Color(0xFF059669),
                //         foregroundColor: Colors.white,
                //         padding: const EdgeInsets.symmetric(vertical: 12),
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(12),
                //         ),
                //       ),
                //       child: const Text(
                //         'Confirm',
                //         style: TextStyle(fontWeight: FontWeight.w500),
                //       ),
                //     ),
                //   ),
                // ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(bottom: BorderSide(color: _borderColor)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.event_note_rounded,
                          color: _primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Appointment Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ref: ${appointment['reference'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusDisplayText(status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          foregroundColor: _textSecondary,
                          backgroundColor: _borderColor.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          'Customer',
                          appointment['customer_name'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          'Phone',
                          appointment['customer_phone'] ?? 'N/A',
                        ),

                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: _borderColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),

                        _buildDetailRow(
                          'Date',
                          _formatDate(appointment['date'] ?? ''),
                        ),
                        _buildDetailRow(
                          'Time',
                          _formatTime(appointment['time'] ?? ''),
                        ),
                        _buildDetailRow(
                          'Status',
                          _getStatusDisplayText(appointment['status'] ?? 'N/A'),
                        ),

                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: _borderColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),

                        _buildDetailRow(
                          'Service',
                          appointment['service']['title'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          'Duration',
                          '${appointment['service']['duration'] ?? 'N/A'} minutes',
                        ),
                        _buildDetailRow(
                          'Price',
                          '£${appointment['price'] ?? '0'}',
                        ),

                        if (appointment['address'] != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: _borderColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
                              border: Border.all(
                                color: _borderColor.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              '${appointment['address']['line1'] ?? ''}\n'
                              '${appointment['address']['line2'] ?? ''}\n'
                              '${appointment['address']['city'] ?? ''}, ${appointment['address']['postcode'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: _textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],

                        if (appointment['notes'] != null &&
                            appointment['notes'].isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: _borderColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Notes', appointment['notes']),
                        ],
                      ],
                    ),
                  ),
                ),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: _borderColor.withOpacity(0.5)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (appointment['can_update_status'] == true &&
                          status.toLowerCase() == 'pending') ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _confirmAppointment(appointment);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF059669),
                              side: const BorderSide(color: Color(0xFF059669)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text(
                              'Confirm',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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

  void _confirmAppointment(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirm Appointment',
            style: TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
          ),
          content: Text(
            'Are you sure you want to confirm this appointment with ${appointment['customer_name']}?',
            style: const TextStyle(color: _textSecondary),
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
                // Update the appointment status locally and refresh the list
                setState(() {
                  appointment['status'] = 'confirmed';
                  _filterAppointments();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Appointment confirmed'),
                    backgroundColor: const Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
