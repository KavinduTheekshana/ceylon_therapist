// lib/services/treatment_history_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_service.dart';

class TreatmentHistoryService {
  static const String baseEndpoint = '/therapist/treatment-history';

  // Get all treatment histories for therapist
  static Future<Map<String, dynamic>> getTreatmentHistories({int page = 1}) async {
    try {
      final token = await ApiService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$baseEndpoint?page=$page'),
        headers: ApiService.getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'pagination': responseData['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get treatment histories',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Create new treatment history
  static Future<Map<String, dynamic>> createTreatmentHistory({
    required int bookingId,
    required String treatmentNotes,
    String? observations,
    String? recommendations,
    String? patientCondition,
    int? painLevelBefore,
    int? painLevelAfter,
    List<String>? areasTreated,
    String? nextTreatmentPlan,
  }) async {
    try {
      final token = await ApiService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final requestBody = <String, dynamic>{
        'booking_id': bookingId,
        'treatment_notes': treatmentNotes,
        'is_editable': true,
      };
      
      // Add optional fields
      if (observations != null && observations.isNotEmpty) {
        requestBody['observations'] = observations;
      }
      if (recommendations != null && recommendations.isNotEmpty) {
        requestBody['recommendations'] = recommendations;
      }
      if (patientCondition != null) {
        requestBody['patient_condition'] = patientCondition;
      }
      if (painLevelBefore != null) {
        requestBody['pain_level_before'] = painLevelBefore;
      }
      if (painLevelAfter != null) {
        requestBody['pain_level_after'] = painLevelAfter;
      }
      if (areasTreated != null && areasTreated.isNotEmpty) {
        requestBody['areas_treated'] = areasTreated;
      }
      if (nextTreatmentPlan != null && nextTreatmentPlan.isNotEmpty) {
        requestBody['next_treatment_plan'] = nextTreatmentPlan;
      }

      // Debug logging
      print('📤 Creating treatment history...');
      print('🔗 URL: ${ApiService.baseUrl}$baseEndpoint');
      print('📄 Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}$baseEndpoint'),
        headers: ApiService.getAuthHeaders(token),
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      // Debug response
      print('📱 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      return {
        'success': response.statusCode == 201 && responseData['success'] == true,
        'message': responseData['message'] ?? 
            (response.statusCode == 201 ? 'Treatment history created successfully' : 'Failed to create treatment history'),
        'data': responseData['data'],
        'errors': responseData['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get specific treatment history
  static Future<Map<String, dynamic>> getTreatmentHistory(int id) async {
    try {
      final token = await ApiService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$baseEndpoint/$id'),
        headers: ApiService.getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get treatment history',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update treatment history (within 24 hours)
  static Future<Map<String, dynamic>> updateTreatmentHistory({
    required int id,
    String? treatmentNotes,
    String? observations,
    String? recommendations,
    String? patientCondition,
    int? painLevelBefore,
    int? painLevelAfter,
    List<String>? areasTreated,
    String? nextTreatmentPlan,
  }) async {
    try {
      final token = await ApiService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final requestBody = <String, dynamic>{};
      if (treatmentNotes != null) requestBody['treatment_notes'] = treatmentNotes;
      if (observations != null) requestBody['observations'] = observations;
      if (recommendations != null) requestBody['recommendations'] = recommendations;
      if (patientCondition != null) requestBody['patient_condition'] = patientCondition;
      if (painLevelBefore != null) requestBody['pain_level_before'] = painLevelBefore;
      if (painLevelAfter != null) requestBody['pain_level_after'] = painLevelAfter;
      if (areasTreated != null) requestBody['areas_treated'] = areasTreated;
      if (nextTreatmentPlan != null) requestBody['next_treatment_plan'] = nextTreatmentPlan;

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}$baseEndpoint/$id'),
        headers: ApiService.getAuthHeaders(token),
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200 && responseData['success'] == true,
        'message': responseData['message'] ?? 
            (response.statusCode == 200 ? 'Treatment history updated successfully' : 'Failed to update treatment history'),
        'data': responseData['data'],
        'errors': responseData['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get treatment history by booking ID
  static Future<Map<String, dynamic>> getTreatmentHistoryByBooking(int bookingId) async {
    try {
      final token = await ApiService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$baseEndpoint/booking/$bookingId'),
        headers: ApiService.getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data']};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'No treatment history found', 'not_found': true};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get treatment history',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Check if booking has treatment history
  static Future<Map<String, dynamic>> checkBookingHasHistory(int bookingId) async {
    try {
      final token = await ApiService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/therapist/bookings/$bookingId/has-treatment-history'),
        headers: ApiService.getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'has_history': responseData['has_history'] ?? false,
        };
      } else {
        return {'success': false, 'message': 'Failed to check history status'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}