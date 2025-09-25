import 'package:flutter/material.dart';
import 'api_service.dart';

class PatientListScreen extends StatefulWidget {
  final Map<String, dynamic> therapistData;

  const PatientListScreen({super.key, required this.therapistData});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Map<String, dynamic>> patients = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String searchQuery = '';
  int currentPage = 1;
  int totalPages = 1;
  int totalPatients = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Modern color scheme
  static const Color _primaryColor = Color(0xFF9a563a);
  static const Color _surfaceColor = Color(0xFFFAFBFF);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _successColor = Color.fromARGB(255, 134, 74, 49);

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePatients();
    }
  }

  Future<void> _loadPatients({bool refresh = false}) async {
    try {
      if (refresh) {
        setState(() {
          isLoading = true;
          currentPage = 1;
          patients.clear();
        });
      } else {
        setState(() {
          isLoading = true;
        });
      }

      final result = await ApiService.getTherapistPatients(
        perPage: 20,
        search: searchQuery.isEmpty ? null : searchQuery,
      );

      if (result['success'] && mounted) {
        final patientsData = List<Map<String, dynamic>>.from(result['data'] ?? []);
        final pagination = result['pagination'] ?? {};
        
        setState(() {
          if (refresh) {
            patients = patientsData;
          } else {
            patients = patientsData;
          }
          currentPage = pagination['current_page'] ?? 1;
          totalPages = pagination['last_page'] ?? 1;
          totalPatients = pagination['total'] ?? 0;
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          _showErrorSnackBar(result['message'] ?? 'Failed to load patients');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Error loading patients: ${e.toString()}');
      }
    }
  }

  Future<void> _loadMorePatients() async {
    if (isLoadingMore || currentPage >= totalPages) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final result = await ApiService.getTherapistPatients(
        perPage: 20,
        search: searchQuery.isEmpty ? null : searchQuery,
      );

      if (result['success'] && mounted) {
        final newPatients = List<Map<String, dynamic>>.from(result['data'] ?? []);
        final pagination = result['pagination'] ?? {};
        
        setState(() {
          patients.addAll(newPatients);
          currentPage = pagination['current_page'] ?? currentPage;
          totalPages = pagination['last_page'] ?? totalPages;
          isLoadingMore = false;
        });
      } else {
        if (mounted) {
          setState(() {
            isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
    }
  }

  void _performSearch(String query) {
    if (searchQuery != query) {
      setState(() {
        searchQuery = query;
      });
      _loadPatients(refresh: true);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        title: const Text(
          'Patient List',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        surfaceTintColor: _cardColor,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        scrolledUnderElevation: 1,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
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
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search patients by name or email...',
                hintStyle: TextStyle(color: _textSecondary),
                prefixIcon: Icon(Icons.search, color: _textSecondary, size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: _textSecondary, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
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

          // Patient Count
          if (!isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$totalPatients patients found',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Searching: "$searchQuery"',
                        style: TextStyle(
                          fontSize: 12,
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Patient List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  )
                : patients.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: _primaryColor,
                        onRefresh: () => _loadPatients(refresh: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: patients.length + (isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= patients.length) {
                              // Loading more indicator
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                                  ),
                                ),
                              );
                            }
                            final patient = patients[index];
                            return _buildPatientCard(patient, index);
                          },
                        ),
                      ),
          ),
        ],
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
              searchQuery.isEmpty ? Icons.people_outline_rounded : Icons.search_off_rounded,
              size: 48,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            searchQuery.isEmpty ? 'No patients found' : 'No matching patients',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Patients who book your services will appear here'
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
                _searchController.clear();
                _performSearch('');
              },
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
              child: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPatientDetails(patient),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: patient['image'] != null && patient['image'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              patient['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildAvatarInitial(patient['name']);
                              },
                            ),
                          )
                        : _buildAvatarInitial(patient['name']),
                  ),
                  const SizedBox(width: 16),

                  // Patient Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient['name'] ?? 'Unknown Patient',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (patient['email'] != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: _textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  patient['email'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.event_available_outlined,
                              size: 14,
                              color: _textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${patient['total_appointments'] ?? 0} appointments',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _successColor,
                      ),
                    ),
                  ),
                ],
              ),

              // Additional Info
              if (patient['last_appointment'] != null ||
                  patient['total_spent'] != null) ...[
                const SizedBox(height: 16),
                const Divider(color: _borderColor),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (patient['last_appointment'] != null) ...[
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.access_time,
                          label: 'Last Visit',
                          value: patient['last_visit_formatted'] ?? 
                                 _formatDate(patient['last_appointment']),
                        ),
                      ),
                    ],
                    if (patient['total_spent'] != null) ...[
                      if (patient['last_appointment'] != null)
                        const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.payments_outlined,
                          label: 'Total Spent',
                          value: '£${(patient['total_spent'] ?? 0).toStringAsFixed(0)}',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarInitial(String? name) {
    return Center(
      child: Text(
        (name?.isNotEmpty == true) ? name!.substring(0, 1).toUpperCase() : 'P',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: patient['image'] != null && patient['image'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                patient['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      (patient['name']?.isNotEmpty == true) 
                                          ? patient['name']!.substring(0, 1).toUpperCase() 
                                          : 'P',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                (patient['name']?.isNotEmpty == true) 
                                    ? patient['name']!.substring(0, 1).toUpperCase() 
                                    : 'P',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
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
                            patient['name'] ?? 'Unknown Patient',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            patient['email'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Stats
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Visits',
                              '${patient['total_appointments'] ?? 0}',
                              Icons.event_available,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Total Spent',
                              '£${(patient['total_spent'] ?? 0).toStringAsFixed(0)}',
                              Icons.payments,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Last Visit',
                              patient['last_visit_formatted'] ?? 
                              _formatDate(patient['last_appointment']),
                              Icons.access_time,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Patient Since',
                              patient['patient_since'] ?? 'Unknown',
                              Icons.person_add,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                // TODO: Navigate to patient booking history
                              },
                              icon: const Icon(Icons.history),
                              label: const Text('View History'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                // TODO: Open contact options
                              },
                              icon: const Icon(Icons.message),
                              label: const Text('Contact'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: BorderSide(color: _primaryColor),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}