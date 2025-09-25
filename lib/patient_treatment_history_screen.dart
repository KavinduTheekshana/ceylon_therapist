import 'package:flutter/material.dart';
import 'api_service.dart';

class PatientTreatmentHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final Map<String, dynamic> therapistData;

  const PatientTreatmentHistoryScreen({
    super.key,
    required this.patient,
    required this.therapistData,
  });

  @override
  State<PatientTreatmentHistoryScreen> createState() =>
      _PatientTreatmentHistoryScreenState();
}

class _PatientTreatmentHistoryScreenState
    extends State<PatientTreatmentHistoryScreen> {
  List<Map<String, dynamic>> treatments = [];
  bool isLoading = true;
  String searchQuery = '';

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
    _loadTreatmentHistory();
  }

  Future<void> _loadTreatmentHistory() async {
    try {
      setState(() {
        isLoading = true;
      });

      final result = await ApiService.getPatientTreatmentHistory(
        patientId: widget.patient['id'],
      );

      if (result['success'] && mounted) {
        setState(() {
          treatments = List<Map<String, dynamic>>.from(result['data'] ?? []);
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          _showErrorSnackBar(result['message'] ?? 'Failed to load treatment history');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Error loading treatment history: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get filteredTreatments {
    if (searchQuery.isEmpty) return treatments;

    return treatments.where((treatment) {
      final serviceName = treatment['service_title']?.toString().toLowerCase() ?? '';
      final patientName = treatment['patient_name']?.toString().toLowerCase() ?? '';
      final treatmentNotes = treatment['treatment_notes']?.toString().toLowerCase() ?? '';
      final observations = treatment['observations']?.toString().toLowerCase() ?? '';
      final recommendations = treatment['recommendations']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();

      return serviceName.contains(query) ||
          patientName.contains(query) ||
          treatmentNotes.contains(query) ||
          observations.contains(query) ||
          recommendations.contains(query);
    }).toList();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return 'N/A';
    try {
      final time = DateTime.parse(timeString);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getConditionColor(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'improved':
        return _successColor;
      case 'same':
      case 'stable':
        return _warningColor;
      case 'worse':
      case 'deteriorated':
        return _errorColor;
      default:
        return _textSecondary;
    }
  }

  String _getPainLevelText(int? painLevel) {
    if (painLevel == null) return 'N/A';
    if (painLevel <= 3) return 'Low ($painLevel/10)';
    if (painLevel <= 6) return 'Moderate ($painLevel/10)';
    return 'High ($painLevel/10)';
  }

  Color _getPainLevelColor(int? painLevel) {
    if (painLevel == null) return _textSecondary;
    if (painLevel <= 3) return _successColor;
    if (painLevel <= 6) return _warningColor;
    return _errorColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Treatment History',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            Text(
              widget.patient['name'] ?? 'Unknown Patient',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        elevation: 0,
        surfaceTintColor: _cardColor,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        scrolledUnderElevation: 1,
      ),
      body: Column(
        children: [
          // Patient Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: widget.patient['image'] != null &&
                          widget.patient['image'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.patient['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildAvatarInitial();
                            },
                          ),
                        )
                      : _buildAvatarInitial(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient['name'] ?? 'Unknown Patient',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.patient['email'] != null)
                        Text(
                          widget.patient['email'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${treatments.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                    const Text(
                      'Treatments',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          if (treatments.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search treatments...',
                  hintStyle: const TextStyle(color: _textSecondary),
                  prefixIcon: const Icon(Icons.search, color: _textSecondary, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: _textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Treatment Count
          if (!isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${filteredTreatments.length} treatments found',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Treatment List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  )
                : filteredTreatments.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: _primaryColor,
                        onRefresh: _loadTreatmentHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredTreatments.length,
                          itemBuilder: (context, index) {
                            final treatment = filteredTreatments[index];
                            return _buildTreatmentCard(treatment, index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitial() {
    return Center(
      child: Text(
        (widget.patient['name']?.isNotEmpty == true)
            ? widget.patient['name']!.substring(0, 1).toUpperCase()
            : 'P',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _primaryColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              searchQuery.isEmpty
                  ? Icons.medical_services_outlined
                  : Icons.search_off_rounded,
              size: 48,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            searchQuery.isEmpty
                ? 'No treatments found'
                : 'No matching treatments',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'This patient hasn\'t received any treatments yet'
                : 'Try adjusting your search query',
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                });
              },
              child: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(Map<String, dynamic> treatment, int index) {
    final conditionColor = _getConditionColor(treatment['patient_condition']);
    final painBeforeColor = _getPainLevelColor(treatment['pain_level_before']);
    final painAfterColor = _getPainLevelColor(treatment['pain_level_after']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treatment['service_title'] ?? 'Unknown Service',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              treatment['booking_reference'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${treatment['service_duration'] ?? 0} hour${(treatment['service_duration'] ?? 0) != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (treatment['patient_condition'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: conditionColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (treatment['patient_condition'] ?? '').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: conditionColor,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Appointment Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, size: 16, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Booking: ${_formatDate(treatment['booking_date'])} at ${_formatTime(treatment['booking_time'])}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pain Level Improvement
            if (treatment['pain_level_before'] != null || treatment['pain_level_after'] != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildPainLevelCard(
                      'Before Treatment',
                      treatment['pain_level_before'],
                      painBeforeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPainLevelCard(
                      'After Treatment',
                      treatment['pain_level_after'],
                      painAfterColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Areas Treated
            if (treatment['areas_treated'] != null && treatment['areas_treated'].isNotEmpty) ...[
              const Text(
                'Areas Treated:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (treatment['areas_treated'] as List).map<Widget>((area) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      area.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Treatment Notes
            if (treatment['treatment_notes'] != null && treatment['treatment_notes'].toString().isNotEmpty) ...[
              _buildDetailSection(
                'Treatment Notes',
                treatment['treatment_notes'],
                Icons.notes,
              ),
              const SizedBox(height: 12),
            ],

            // Observations
            if (treatment['observations'] != null && treatment['observations'].toString().isNotEmpty) ...[
              _buildDetailSection(
                'Observations',
                treatment['observations'],
                Icons.visibility,
              ),
              const SizedBox(height: 12),
            ],

            // Recommendations
            if (treatment['recommendations'] != null && treatment['recommendations'].toString().isNotEmpty) ...[
              _buildDetailSection(
                'Recommendations',
                treatment['recommendations'],
                Icons.recommend,
              ),
              const SizedBox(height: 12),
            ],

            // Next Treatment Plan
            if (treatment['next_treatment_plan'] != null && treatment['next_treatment_plan'].toString().isNotEmpty) ...[
              _buildDetailSection(
                'Next Treatment Plan',
                treatment['next_treatment_plan'],
                Icons.schedule,
                color: _warningColor,
              ),
              const SizedBox(height: 12),
            ],

            // Completion Info
            if (treatment['treatment_completed_at'] != null) ...[
              const Divider(color: _borderColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: _successColor),
                  const SizedBox(width: 8),
                  Text(
                    'Completed: ${_formatDateTime(treatment['treatment_completed_at'])}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _successColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPainLevelCard(String title, int? painLevel, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.healing, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                _getPainLevelText(painLevel),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    String content,
    IconData icon, {
    Color? color,
  }) {
    final sectionColor = color ?? _primaryColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sectionColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sectionColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: sectionColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: sectionColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: _textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}