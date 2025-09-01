import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  // static const String baseUrl = 'https://app.ceylonayurvedahealth.co.uk/api';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get therapist preferences
  static Future<Map<String, dynamic>> getTherapistPreferences() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/therapist/preferences'),
        headers: getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get preferences',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateTherapistPreferences({
    String? preferredGender,
    int? ageRangeStart,
    int? ageRangeEnd,
    String? preferredLanguage,
    bool? acceptNewPatients,
    bool? homeVisitsOnly,
    bool? clinicVisitsOnly,
    int? maxTravelDistance,
    bool? weekendsAvailable,
    bool? eveningsAvailable,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      // Build request body with only non-null values
      final Map<String, dynamic> requestBody = {};

      if (preferredGender != null)
        requestBody['preferred_gender'] = preferredGender;
      if (ageRangeStart != null) requestBody['age_range_start'] = ageRangeStart;
      if (ageRangeEnd != null) requestBody['age_range_end'] = ageRangeEnd;
      if (preferredLanguage != null)
        requestBody['preferred_language'] = preferredLanguage;
      if (acceptNewPatients != null)
        requestBody['accept_new_patients'] = acceptNewPatients;
      if (homeVisitsOnly != null)
        requestBody['home_visits_only'] = homeVisitsOnly;
      if (clinicVisitsOnly != null)
        requestBody['clinic_visits_only'] = clinicVisitsOnly;
      if (maxTravelDistance != null)
        requestBody['max_travel_distance'] = maxTravelDistance;
      if (weekendsAvailable != null)
        requestBody['weekends_available'] = weekendsAvailable;
      if (eveningsAvailable != null)
        requestBody['evenings_available'] = eveningsAvailable;

      final response = await http.post(
        Uri.parse('$baseUrl/therapist/preferences'),
        headers: getAuthHeaders(token),
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update preferences',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> resetTherapistPreferences() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/therapist/preferences/reset'),
        headers: getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reset preferences',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Map<String, String> getAuthHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };

  // Login method with better error handling
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/therapist/login'),
        headers: headers,
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      // Always return the status code for proper handling
      if (response.statusCode == 200) {
        // Check if the API returns success in the response
        if (responseData['success'] == true) {
          return {
            'success': true,
            'data': responseData['data'],
            'status_code': response.statusCode,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Login failed',
            'status_code': response.statusCode,
            'data': responseData['data'],
          };
        }
      } else if (response.statusCode == 401) {
        // Unauthorized - Invalid credentials
        return {
          'success': false,
          'message': responseData['message'] ?? 'Invalid email or password',
          'status_code': response.statusCode,
          'data': responseData['data'],
        };
      } else if (response.statusCode == 403) {
        // Forbidden - Account inactive or email not verified
        return {
          'success': false,
          'message': responseData['message'] ?? 'Access denied',
          'status_code': response.statusCode,
          'data':
              responseData['data'], // This will contain account_status, requires_verification, etc.
        };
      } else {
        // Other error status codes
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Login failed with status ${response.statusCode}',
          'status_code': response.statusCode,
          'data': responseData['data'],
        };
      }
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet connection.',
        'status_code': 0, // Network error indicator
      };
    } on FormatException catch (e) {
      return {
        'success': false,
        'message': 'Invalid server response format.',
        'status_code': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'status_code': 0,
      };
    }
  }

  // Register method for ApiService class
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? bio,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/therapist/register/app'),
        headers: headers,
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': confirmPassword,
          if (bio != null && bio.isNotEmpty) 'bio': bio,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        if (responseData['success'] == true) {
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Registration failed',
            'errors': responseData['errors'],
          };
        }
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Registration failed with status ${response.statusCode}',
          'errors': responseData['errors'],
        };
      }
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet connection.',
      };
    } on FormatException catch (e) {
      return {'success': false, 'message': 'Invalid server response format.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Add OTP verification method
  static Future<Map<String, dynamic>> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/therapist/verify-otp'),
        headers: headers,
        body: json.encode({'email': email, 'otp': otp}),
      );

      final responseData = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && responseData['success'] == true,
        'message':
            responseData['message'] ??
            (response.statusCode == 200
                ? 'OTP verified successfully'
                : 'Invalid OTP'),
        'data': responseData['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Add resend OTP method
  static Future<Map<String, dynamic>> resendRegistrationOtp({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/therapist/resend-otp'),
        headers: headers,
        body: json.encode({'email': email}),
      );

      final responseData = json.decode(response.body);

      return {
        'success':
            response.statusCode == 200 && responseData['success'] == true,
        'message':
            responseData['message'] ??
            (response.statusCode == 200
                ? 'OTP sent successfully'
                : 'Failed to send OTP'),
        'data': responseData['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Forgot Password method
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/therapist/forgot-password'),
        headers: headers,
        body: json.encode({'email': email}),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message':
            responseData['message'] ??
            (response.statusCode == 200
                ? 'Password reset code sent to your email'
                : 'Failed to send password reset code'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get holiday requests for therapist
  static Future<Map<String, dynamic>> getHolidayRequests() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/therapist/holiday-requests'),
        headers: getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to get holiday requests',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get holidays for calendar view
  static Future<Map<String, dynamic>> getCalendarHolidays() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/therapist/holiday-requests/calendar'),
        headers: getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to get calendar holidays',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Submit holiday request
  static Future<Map<String, dynamic>> requestHoliday({
    required String date, // Format: 'YYYY-MM-DD'
    required String reason,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/therapist/holiday-requests'),
        headers: getAuthHeaders(token),
        body: json.encode({'date': date, 'reason': reason}),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 201 || response.statusCode == 200,
        'message':
            responseData['message'] ??
            (response.statusCode == 201
                ? 'Holiday request submitted successfully'
                : 'Failed to submit holiday request'),
        'data': responseData['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Cancel holiday request
  static Future<Map<String, dynamic>> cancelHolidayRequest({
    required int requestId,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/therapist/holiday-requests/$requestId'),
        headers: getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message':
            responseData['message'] ??
            (response.statusCode == 200
                ? 'Holiday request cancelled successfully'
                : 'Failed to cancel holiday request'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Verify OTP method
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/therapist/verify-reset-code'),
        headers: headers,
        body: json.encode({'email': email, 'code': otp}),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message':
            responseData['message'] ??
            (response.statusCode == 200
                ? 'OTP verified successfully'
                : 'Invalid or expired OTP'),
        'data': responseData['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Reset Password method
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/therapist/reset-password'),
        headers: headers,
        body: json.encode({
          'email': email,
          'reset_token': resetToken,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message':
            responseData['message'] ??
            (response.statusCode == 200
                ? 'Password reset successfully'
                : 'Failed to reset password'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Save login data to SharedPreferences
  static Future<void> saveLoginData(Map<String, dynamic> loginData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final therapistData = loginData['data']['therapist'];
      final accessToken = loginData['data']['access_token'];
      final tokenType = loginData['data']['token_type'];

      await prefs.setString('access_token', accessToken);
      await prefs.setString('token_type', tokenType);
      await prefs.setString('therapist_data', json.encode(therapistData));
      await prefs.setBool('is_logged_in', true);
    } catch (e) {
      throw Exception('Failed to save login data');
    }
  }

  // Get stored access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get stored therapist data
  static Future<Map<String, dynamic>?> getTherapistData() async {
    final prefs = await SharedPreferences.getInstance();
    final therapistDataString = prefs.getString('therapist_data');
    if (therapistDataString != null) {
      return json.decode(therapistDataString);
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // Logout method
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Get therapist profile (with authentication)
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      // print('🔄 Making get profile request to: $baseUrl/therapist/profile');
      // print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/therapist/profile'),
        headers: getAuthHeaders(token),
      );

      // print('📱 Get profile response status: ${response.statusCode}');
      // print('📄 Get profile response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      // print('❌ Get profile error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update therapist profile - FIXED: Removed email parameter
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    String? bio,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      // print('🔄 Making update profile request to: $baseUrl/therapist/profile');
      // print('📄 Update data: name=$name, phone=$phone, bio=$bio');

      final response = await http.post(
        Uri.parse('$baseUrl/therapist/profile'),
        headers: getAuthHeaders(token),
        body: json.encode({'name': name, 'phone': phone, 'bio': bio}),
      );

      // print('📱 Update profile response status: ${response.statusCode}');
      // print('📄 Update profile response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update stored therapist data
        await saveTherapistData(responseData['data']['therapist']);
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      // print('❌ Update profile error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Save updated therapist data
  static Future<void> saveTherapistData(
    Map<String, dynamic> therapistData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('therapist_data', json.encode(therapistData));
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/therapist/change-password'),
        headers: getAuthHeaders(token),
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        }),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message':
            responseData['message'] ??
            (response.statusCode == 200
                ? 'Password changed successfully'
                : 'Failed to change password'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get therapist appointments
  static Future<Map<String, dynamic>> getAppointments() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/therapist/appointments'),
        headers: getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get appointments',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get therapist availability
  static Future<Map<String, dynamic>> getAvailability() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/therapist/availability'),
        headers: getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);
      // print('📅 Availability response: $responseData');

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get availability',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update booking status
  static Future<Map<String, dynamic>> updateBookingStatus({
    required int bookingId,
    required String status,
    String? notes,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/therapist/bookings/$bookingId/status'),
        headers: getAuthHeaders(token),
        body: json.encode({
          'status': status,
          if (notes != null) 'notes': notes,
        }),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message':
            responseData['message'] ??
            (response.statusCode == 200
                ? 'Booking status updated successfully'
                : 'Failed to update booking status'),
        'data': responseData['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Test connection method
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      // print('🧪 Testing connection to: $baseUrl');

      final response = await http
          .get(
            Uri.parse('$baseUrl/test'), // Add a test endpoint if available
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      return {
        'success': response.statusCode == 200,
        'message':
            'Connection ${response.statusCode == 200 ? 'successful' : 'failed'}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection failed: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateOnlineStatus({
    required bool isOnline,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      print('🔄 Updating online status to: $isOnline');

      final response = await http.post(
        Uri.parse('$baseUrl/therapist/online-status'),
        headers: getAuthHeaders(token),
        body: json.encode({'online_status': isOnline}),
      );

      print('📱 Online status response: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update stored therapist data with new online status
        final therapistData = await getTherapistData();
        if (therapistData != null) {
          therapistData['online_status'] = isOnline;
          await saveTherapistData(therapistData);
        }

        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to update online status',
        };
      }
    } catch (e) {
      print('❌ Online status update error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
