import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.213:8000/api';
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };

  // Login method
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/therapist/login'),
        headers: headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
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
        body: json.encode({
          'email': email,
        }),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': responseData['message'] ?? (response.statusCode == 200 
            ? 'Password reset code sent to your email' 
            : 'Failed to send password reset code'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
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
        body: json.encode({
          'email': email,
          'code': otp,
        }),
      );

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': responseData['message'] ?? (response.statusCode == 200 
            ? 'OTP verified successfully' 
            : 'Invalid or expired OTP'),
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
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
        'message': responseData['message'] ?? (response.statusCode == 200 
            ? 'Password reset successfully' 
            : 'Failed to reset password'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Save login data to SharedPreferences
  static Future<void> saveLoginData(Map<String, dynamic> loginData) async {
    final prefs = await SharedPreferences.getInstance();
    final therapistData = loginData['data']['therapist'];
    final accessToken = loginData['data']['access_token'];
    final tokenType = loginData['data']['token_type'];
    
    await prefs.setString('access_token', accessToken);
    await prefs.setString('token_type', tokenType);
    await prefs.setString('therapist_data', json.encode(therapistData));
    await prefs.setBool('is_logged_in', true);
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
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/therapist/profile'),
        headers: getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update therapist profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? bio,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/therapist/profile'),
        headers: getAuthHeaders(token),
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'bio': bio,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update stored therapist data
        await saveTherapistData(responseData['data']['therapist']);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Save updated therapist data
  static Future<void> saveTherapistData(Map<String, dynamic> therapistData) async {
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
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final response = await http.put(
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
        'message': responseData['message'] ?? (response.statusCode == 200 
            ? 'Password changed successfully' 
            : 'Failed to change password'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get therapist appointments
  static Future<Map<String, dynamic>> getAppointments() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/therapist/appointments'),
        headers: getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get appointments',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get therapist availability
  static Future<Map<String, dynamic>> getAvailability() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/therapist/availability'),
        headers: getAuthHeaders(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get availability',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
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
        return {
          'success': false,
          'message': 'No access token found',
        };
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
        'message': responseData['message'] ?? (response.statusCode == 200 
            ? 'Booking status updated successfully' 
            : 'Failed to update booking status'),
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}