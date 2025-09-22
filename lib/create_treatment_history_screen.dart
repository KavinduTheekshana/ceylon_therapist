// lib/create_treatment_history_screen.dart

import 'package:flutter/material.dart';
import 'services/treatment_history_service.dart';

class CreateTreatmentHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic> therapistData;

  const CreateTreatmentHistoryScreen({
    super.key,
    required this.appointment,
    required this.therapistData,
  });

  @override
  State<CreateTreatmentHistoryScreen> createState() => _CreateTreatmentHistoryScreenState();
}

class _CreateTreatmentHistoryScreenState extends State<CreateTreatmentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _treatmentNotesController = TextEditingController();
  final _observationsController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final _nextTreatmentPlanController = TextEditingController();
  final _areaController = TextEditingController();

  // Form values
  String? _selectedCondition;
  int? _painLevelBefore;
  int? _painLevelAfter;
  List<String> _areasTreated = [];

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

  Future<void> _createTreatmentHistory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Debug appointment data structure
      print('🏥 Full Appointment Data: ${widget.appointment}');
      print('🏥 Appointment ID: ${widget.appointment['id']}');
      print('🏥 Appointment Keys: ${widget.appointment.keys.toList()}');
      
      // Check for different possible ID fields
      final possibleIds = [
        widget.appointment['id'],
        widget.appointment['booking_id'], 
        widget.appointment['appointment_id'],
        widget.appointment['reference'],
      ];
      print('🔍 Possible ID values: $possibleIds');
      
      print('📋 Form data - Treatment Notes: ${_treatmentNotesController.text.trim()}');
      print('📋 Form data - Areas Treated: $_areasTreated');

      // Try to determine the correct booking ID
      int? bookingId;
      if (widget.appointment['id'] is int) {
        bookingId = widget.appointment['id'];
      } else if (widget.appointment['id'] is String) {
        bookingId = int.tryParse(widget.appointment['id'].toString());
      } else if (widget.appointment['booking_id'] != null) {
        bookingId = widget.appointment['booking_id'] is int 
          ? widget.appointment['booking_id'] 
          : int.tryParse(widget.appointment['booking_id'].toString());
      }
      
      print('🎯 Using booking ID: $bookingId (type: ${bookingId.runtimeType})');
      print('📊 Appointment Status: ${widget.appointment['status']}');
      
      // Check if appointment is in correct status
      final status = widget.appointment['status']?.toString().toLowerCase();
      if (status != 'completed' && status != 'confirmed') {
        print('⚠️ Warning: Appointment status is "$status", expected "completed" or "confirmed"');
      }
      
      if (bookingId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid booking ID. Cannot create treatment history.'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final result = await TreatmentHistoryService.createTreatmentHistory(
        bookingId: bookingId,
        treatmentNotes: _treatmentNotesController.text.trim(),
        observations: _observationsController.text.trim(),
        recommendations: _recommendationsController.text.trim(),
        patientCondition: _selectedCondition,
        painLevelBefore: _painLevelBefore,
        painLevelAfter: _painLevelAfter,
        areasTreated: _areasTreated,
        nextTreatmentPlan: _nextTreatmentPlanController.text.trim(),
      );

      print('✅ Create result: $result');

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Treatment history created successfully'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        // Show detailed error information
        String errorMessage = result['message'] ?? 'Failed to create treatment history';
        if (result['errors'] != null) {
          errorMessage += '\n\nErrors: ${result['errors']}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5), // Longer duration to read errors
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        title: const Text(
          'Add Treatment History',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        surfaceTintColor: _cardColor,
        shadowColor: Colors.black.withOpacity(0.1),
        scrolledUnderElevation: 1,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card with appointment info
                  _buildAppointmentCard(),
                  const SizedBox(height: 20),

                  // Important notice
                  _buildNoticeCard(),
                  const SizedBox(height: 20),

                  // Treatment notes (required)
                  _buildSectionCard(
                    title: 'Treatment Notes *',
                    icon: Icons.notes_rounded,
                    child: TextFormField(
                      controller: _treatmentNotesController,
                      maxLines: 4,
                      maxLength: 2000,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Treatment notes are required';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Describe the treatment provided in detail...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primaryColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Patient condition and pain levels
                  _buildConditionAndPainCard(),
                  const SizedBox(height: 20),

                  // Areas treated
                  _buildAreasCard(),
                  const SizedBox(height: 20),

                  // Observations
                  _buildSectionCard(
                    title: 'Observations',
                    icon: Icons.visibility_rounded,
                    child: TextFormField(
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
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recommendations
                  _buildSectionCard(
                    title: 'Recommendations',
                    icon: Icons.lightbulb_outline_rounded,
                    child: TextFormField(
                      controller: _recommendationsController,
                      maxLines: 3,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText: 'Post-treatment recommendations for the patient...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primaryColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Next treatment plan
                  _buildSectionCard(
                    title: 'Next Treatment Plan',
                    icon: Icons.schedule_rounded,
                    child: TextFormField(
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
                    ),
                  ),

                  // Bottom spacing
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAppointmentCard() {
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
            widget.appointment['customer_name'] ?? 'Unknown Patient',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ref: ${widget.appointment['reference'] ?? 'N/A'}',
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
                        widget.appointment['service']['title'] ?? 'Treatment',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '£${widget.appointment['price'] ?? '0'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: _textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.appointment['service']['duration'] ?? 0} minutes',
                      style: const TextStyle(fontSize: 14, color: _textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Notice',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'You can edit this treatment history for 24 hours after creation.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
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
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getConditionColor(condition),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(condition.toUpperCase()),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCondition = value;
              });
            },
            hint: const Text('Select patient condition'),
          ),

          const SizedBox(height: 16),

          // Pain levels
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pain Before Treatment (1-10)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textSecondary),
                    ),
                    const SizedBox(height: 8),
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
                          child: Text('$level - ${_getPainDescription(level)}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _painLevelBefore = value;
                        });
                      },
                      hint: const Text('Level'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pain After Treatment (1-10)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textSecondary),
                    ),
                    const SizedBox(height: 8),
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
                          child: Text('$level - ${_getPainDescription(level)}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _painLevelAfter = value;
                        });
                      },
                      hint: const Text('Level'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPainDescription(int level) {
    switch (level) {
      case 1:
        return 'Minimal';
      case 2:
      case 3:
        return 'Mild';
      case 4:
      case 5:
      case 6:
        return 'Moderate';
      case 7:
      case 8:
        return 'Severe';
      case 9:
      case 10:
        return 'Extreme';
      default:
        return '';
    }
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

          // Quick add buttons for common areas
          const Text(
            'Common Areas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textSecondary),
          ),
          const SizedBox(height: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          const Text(
            'Add Custom Area',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _areaController,
                  decoration: InputDecoration(
                    hintText: 'Enter area name...',
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

          // Show selected areas
          if (_areasTreated.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Selected Areas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textSecondary),
            ),
            const SizedBox(height: 8),
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
                  ),
                );
              }).toList(),
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
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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
                onPressed: _isSaving ? null : _createTreatmentHistory,
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
                        'Create History',
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