// lib/treatment_history_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/treatment_history_service.dart';

class TreatmentHistoryDetailScreen extends StatefulWidget {
  final int historyId;
  final Map<String, dynamic> therapistData;

  const TreatmentHistoryDetailScreen({
    super.key,
    required this.historyId,
    required this.therapistData,
  });

  @override
  State<TreatmentHistoryDetailScreen> createState() => _TreatmentHistoryDetailScreenState();
}

class _TreatmentHistoryDetailScreenState extends State<TreatmentHistoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  Map<String, dynamic>? _historyData;
  String? _errorMessage;

  // Form controllers
  final _treatmentNotesController = TextEditingController();
  final _observationsController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final _nextTreatmentPlanController = TextEditingController();

  // Form values
  String? _selectedCondition;
  int? _painLevelBefore;
  int? _painLevelAfter;
  List<String> _areasTreated = [];
  final _areaController = TextEditingController();

  // Available options
  final List<String> _conditionOptions = ['improved', 'same', 'worse'];
  final List<String> _commonAreas = [
    'Head/Neck', 'Shoulders', 'Upper Back', 'Lower Back', 'Arms', 'Hands', 
    'Chest', 'Abdomen', 'Hips', 'Thighs', 'Knees', 'Calves', 'Feet'
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

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _loadTreatmentHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _treatmentNotesController.dispose();
    _observationsController.dispose();
    _recommendationsController.dispose();
    _nextTreatmentPlanController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _loadTreatmentHistory() async {
    try {
      final result = await TreatmentHistoryService.getTreatmentHistory(widget.historyId);

      if (result['success']) {
        setState(() {
          _historyData = result['data'];
          _isLoading = false;
          _populateFormFields();
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load treatment history';
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

  void _populateFormFields() {
    if (_historyData == null) return;

    _treatmentNotesController.text = _historyData!['treatment_notes'] ?? '';
    _observationsController.text = _historyData!['observations'] ?? '';
    _recommendationsController.text = _historyData!['recommendations'] ?? '';
    _nextTreatmentPlanController.text = _historyData!['next_treatment_plan'] ?? '';
    
    _selectedCondition = _historyData!['patient_condition'];
    _painLevelBefore = _historyData!['pain_level_before'];
    _painLevelAfter = _historyData!['pain_level_after'];
    
    final areas = _historyData!['areas_treated'];
    if (areas is List) {
      _areasTreated = List<String>.from(areas);
    }
  }

  Future<void> _saveChanges() async {
    if (!_canEdit()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await TreatmentHistoryService.updateTreatmentHistory(
        id: widget.historyId,
        treatmentNotes: _treatmentNotesController.text.trim(),
        observations: _observationsController.text.trim(),
        recommendations: _recommendationsController.text.trim(),
        patientCondition: _selectedCondition,
        painLevelBefore: _painLevelBefore,
        painLevelAfter: _painLevelAfter,
        areasTreated: _areasTreated,
        nextTreatmentPlan: _nextTreatmentPlanController.text.trim(),
      );

      if (result['success']) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Treatment history updated successfully'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Reload data to get updated edit status
        _loadTreatmentHistory();
      } else {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update treatment history'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _populateFormFields(); // Reset form to original values
    });
  }

  bool _canEdit() {
    return _historyData?['is_editable'] == true;
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
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

  String _formatTimeRemaining(dynamic timeRemaining) {
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
    
    if (wholeHours > 0 && minutes > 0) {
      return '${wholeHours}h ${minutes}m';
    } else if (wholeHours > 0) {
      return '${wholeHours}h';
    } else {
      return '${minutes}m';
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

  void _addArea(String area) {
    if (area.trim().isNotEmpty && !_areasTreated.contains(area.trim())) {
      setState(() {
        _areasTreated.add(area.trim());
      });
      _areaController.clear();
    }
  }

  void _removeArea(String area) {
    setState(() {
      _areasTreated.remove(area);
    });
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
          if (_canEdit() && !_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit_rounded, size: 22),
              tooltip: 'Edit',
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
                  : _buildContent(),
        ),
      ),
      bottomNavigationBar: _isEditing ? _buildBottomActions() : null,
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
                Icons.error_outline_rounded,
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
              _errorMessage ?? 'Failed to load treatment history',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loadTreatmentHistory,
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

  Widget _buildContent() {
    if (_historyData == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card with patient and booking info
          _buildHeaderCard(),
          const SizedBox(height: 20),

          // Edit status card
          if (_canEdit()) _buildEditStatusCard(),
          if (_canEdit()) const SizedBox(height: 20),

          // Treatment notes
          _buildSectionCard(
            title: 'Treatment Notes',
            icon: Icons.notes_rounded,
            child: _isEditing
                ? TextField(
                    controller: _treatmentNotesController,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: 'Describe the treatment provided...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryColor),
                      ),
                    ),
                  )
                : _buildReadOnlyText(_historyData!['treatment_notes'] ?? 'No treatment notes recorded'),
          ),
          const SizedBox(height: 16),

          // Patient condition and pain levels
          _buildConditionAndPainCard(),
          const SizedBox(height: 16),

          // Areas treated
          _buildAreasCard(),
          const SizedBox(height: 16),

          // Observations
          _buildSectionCard(
            title: 'Observations',
            icon: Icons.visibility_rounded,
            child: _isEditing
                ? TextField(
                    controller: _observationsController,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: 'Patient observations during treatment...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryColor),
                      ),
                    ),
                  )
                : _buildReadOnlyText(_historyData!['observations'] ?? 'No observations recorded'),
          ),
          const SizedBox(height: 16),

          // Recommendations
          _buildSectionCard(
            title: 'Recommendations',
            icon: Icons.lightbulb_outline_rounded,
            child: _isEditing
                ? TextField(
                    controller: _recommendationsController,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: 'Post-treatment recommendations...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryColor),
                      ),
                    ),
                  )
                : _buildReadOnlyText(_historyData!['recommendations'] ?? 'No recommendations recorded'),
          ),
          const SizedBox(height: 16),

          // Next treatment plan
          _buildSectionCard(
            title: 'Next Treatment Plan',
            icon: Icons.schedule_rounded,
            child: _isEditing
                ? TextField(
                    controller: _nextTreatmentPlanController,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: 'Plan for next treatment session...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryColor),
                      ),
                    ),
                  )
                : _buildReadOnlyText(_historyData!['next_treatment_plan'] ?? 'No treatment plan recorded'),
          ),

          // Bottom spacing for floating action button
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final booking = _historyData!['booking'];
    final service = _historyData!['service'];

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
          Text(
            _historyData!['patient_name'] ?? 'Unknown Patient',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ref: ${booking['reference'] ?? 'N/A'}',
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
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
                    Icon(Icons.medical_services_rounded, size: 18, color: _textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service['title'] ?? 'Treatment',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${service['duration'] ?? 0} min',
                      style: const TextStyle(fontSize: 14, color: _textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 16, color: _textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(booking['date'] ?? ''),
                      style: const TextStyle(fontSize: 14, color: _textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time_rounded, size: 16, color: _textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(booking['time'] ?? ''),
                      style: const TextStyle(fontSize: 14, color: _textSecondary),
                    ),
                  ],
                ),
                if (booking['address'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 16, color: _textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${booking['address']}, ${booking['city']} ${booking['postcode']}',
                          style: const TextStyle(fontSize: 14, color: _textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditStatusCard() {
    final hoursRemaining = _historyData!['hours_remaining_for_edit'] ?? 0;
    final editDeadline = _historyData!['edit_deadline_at'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Color(0xFF059669),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editable Period',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatTimeRemaining(hoursRemaining)} remaining (until ${_formatDateTime(editDeadline)})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionAndPainCard() {
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
              Icon(Icons.health_and_safety_rounded, color: _primaryColor, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Patient Condition & Pain Levels',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Patient condition
          if (_isEditing) ...[
            const Text(
              'Patient Condition',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textSecondary),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primaryColor),
                ),
              ),
              items: _conditionOptions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value;
                });
              },
              hint: const Text('Select condition'),
            ),
          ] else ...[
            if (_selectedCondition != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getConditionColor(_selectedCondition).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Condition: ${_selectedCondition!.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getConditionColor(_selectedCondition),
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 16),

          // Pain levels
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pain Before (1-10)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textSecondary),
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing) ...[
                      DropdownButtonFormField<int>(
                        value: _painLevelBefore,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _primaryColor),
                          ),
                        ),
                        items: List.generate(10, (index) => index + 1).map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _painLevelBefore = value;
                          });
                        },
                        hint: const Text('Level'),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _painLevelBefore?.toString() ?? 'Not recorded',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pain After (1-10)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textSecondary),
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing) ...[
                      DropdownButtonFormField<int>(
                        value: _painLevelAfter,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _primaryColor),
                          ),
                        ),
                        items: List.generate(10, (index) => index + 1).map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _painLevelAfter = value;
                          });
                        },
                        hint: const Text('Level'),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _painLevelAfter?.toString() ?? 'Not recorded',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreasCard() {
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
              Icon(Icons.accessibility_rounded, color: _primaryColor, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Areas Treated',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isEditing) ...[
            // Quick add buttons for common areas
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonAreas.map((area) {
                final isSelected = _areasTreated.contains(area);
                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      _removeArea(area);
                    } else {
                      _addArea(area);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryColor : _surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? _primaryColor : _borderColor,
                      ),
                    ),
                    child: Text(
                      area,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : _textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom area input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _areaController,
                    decoration: InputDecoration(
                      hintText: 'Add custom area...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryColor),
                      ),
                    ),
                    onSubmitted: (value) => _addArea(value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addArea(_areaController.text),
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],

          if (_areasTreated.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _areasTreated.map((area) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        area,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _primaryColor,
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeArea(area),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No areas recorded',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
              Icon(icon, color: _primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildReadOnlyText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text.isEmpty ? 'No information recorded' : text,
        style: TextStyle(
          fontSize: 14,
          color: text.isEmpty ? _textSecondary : _textPrimary,
          fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _cancelEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textSecondary,
                  side: const BorderSide(color: _borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}