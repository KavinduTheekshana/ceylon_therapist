// lib/treatment_history_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/treatment_history_service.dart';
import 'treatment_history_detail_screen.dart';

class TreatmentHistoryListScreen extends StatefulWidget {
  final Map<String, dynamic> therapistData;

  const TreatmentHistoryListScreen({super.key, required this.therapistData});

  @override
  State<TreatmentHistoryListScreen> createState() => _TreatmentHistoryListScreenState();
}

class _TreatmentHistoryListScreenState extends State<TreatmentHistoryListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  List<dynamic> _treatmentHistories = [];
  Map<String, dynamic>? _pagination;
  String? _errorMessage;
  int _currentPage = 1;
  bool _isLoadingMore = false;

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

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _loadTreatmentHistories();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTreatmentHistories({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _treatmentHistories.clear();
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await TreatmentHistoryService.getTreatmentHistories(page: _currentPage);

      if (result['success']) {
        setState(() {
          if (refresh) {
            _treatmentHistories = result['data'] ?? [];
          } else {
            _treatmentHistories.addAll(result['data'] ?? []);
          }
          _pagination = result['pagination'];
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load treatment histories';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please check your internet.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreHistories() async {
    if (_pagination != null && _currentPage < _pagination!['last_page'] && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      await _loadTreatmentHistories();
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
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

  Color _getConditionColor(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'improved':
        return const Color(0xFF059669);
      case 'worse':
        return const Color(0xFFDC2626);
      case 'same':
        return const Color(0xFFD97706);
      default:
        return _textSecondary;
    }
  }

  IconData _getConditionIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'improved':
        return Icons.trending_up_rounded;
      case 'worse':
        return Icons.trending_down_rounded;
      case 'same':
        return Icons.trending_flat_rounded;
      default:
        return Icons.help_outline_rounded;
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
          'Treatment History',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        surfaceTintColor: _cardColor,
        shadowColor: Colors.black.withOpacity(0.1),
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            onPressed: () => _loadTreatmentHistories(refresh: true),
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
                  child: CircularProgressIndicator(color: _primaryColor, strokeWidth: 2),
                )
              : _errorMessage != null
                  ? _buildErrorState()
                  : _treatmentHistories.isEmpty
                      ? _buildEmptyState()
                      : _buildHistoryList(),
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
              onPressed: () => _loadTreatmentHistories(refresh: true),
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                Icons.assignment_outlined,
                size: 40,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Treatment History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Treatment histories will appear here\nafter you complete sessions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _loadTreatmentHistories(refresh: true),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: const BorderSide(color: _primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: () => _loadTreatmentHistories(refresh: true),
      color: _primaryColor,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoadingMore &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              _pagination != null &&
              _currentPage < _pagination!['last_page']) {
            _loadMoreHistories();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _treatmentHistories.length + (_isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (index == _treatmentHistories.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: _primaryColor, strokeWidth: 2),
                ),
              );
            }

            final history = _treatmentHistories[index];
            return _buildHistoryCard(history);
          },
        ),
      ),
    );
  }

  String _formatTimeRemaining(dynamic timeRemaining) {
    print('🕒 Formatting time remaining: $timeRemaining (type: ${timeRemaining.runtimeType})');
    
    if (timeRemaining == null) return '0h 0m';
    
    double hours = 0.0;
    if (timeRemaining is int) {
      hours = timeRemaining.toDouble();
    } else if (timeRemaining is double) {
      hours = timeRemaining;
    } else if (timeRemaining is String) {
      hours = double.tryParse(timeRemaining) ?? 0.0;
    }
    
    if (hours <= 0) return '0h 0m';
    
    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();
    
    String result;
    if (wholeHours > 0 && minutes > 0) {
      result = '${wholeHours}h ${minutes}m';
    } else if (wholeHours > 0) {
      result = '${wholeHours}h';
    } else {
      result = '${minutes}m';
    }
    
    print('🕒 Formatted result: $result');
    return result;
  }

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    final condition = history['patient_condition'];
    final conditionColor = _getConditionColor(condition);
    final isEditable = history['is_editable'] ?? false;
    final timeRemaining = history['hours_remaining_for_edit'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TreatmentHistoryDetailScreen(
              historyId: history['id'],
              therapistData: widget.therapistData,
            ),
          ),
        ).then((_) => _loadTreatmentHistories(refresh: true));
      },
      child: Container(
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
              // Header with patient name and edit status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          history['patient_name'] ?? 'Unknown Patient',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ref: ${history['booking_reference'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEditable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatTimeRemaining(timeRemaining)} left',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Service and date info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services_rounded,
                          size: 18,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            history['service_title'] ?? 'Treatment',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(history['treatment_date'] ?? ''),
                          style: const TextStyle(fontSize: 14, color: _textSecondary),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(history['treatment_time'] ?? ''),
                          style: const TextStyle(fontSize: 14, color: _textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Patient condition and pain levels
              Row(
                children: [
                  // Patient condition
                  if (condition != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: conditionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getConditionIcon(condition),
                            size: 16,
                            color: conditionColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            condition.toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: conditionColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Pain levels
                  if (history['pain_level_before'] != null && history['pain_level_after'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Pain: ${history['pain_level_before']} → ${history['pain_level_after']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // View details button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreatmentHistoryDetailScreen(
                          historyId: history['id'],
                          therapistData: widget.therapistData,
                        ),
                      ),
                    ).then((_) => _loadTreatmentHistories(refresh: true));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: const BorderSide(color: _borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(
                    isEditable ? Icons.edit_rounded : Icons.visibility_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isEditable ? 'View & Edit' : 'View Details',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}