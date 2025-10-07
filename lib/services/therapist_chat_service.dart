// lib/services/therapist_chat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../chat_room.dart';
import '../chat_message.dart';
import '../pagination.dart';

class TherapistChatService {
  // ⚠️ CHANGE THIS to your actual API URL
  static const String baseUrl = 'http://10.0.2.2:8000'; // For Android Emulator
  
  // Get auth token from shared preferences
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      // 🔍 DEBUG LOG
      if (token != null) {
        print('✅ [DEBUG] Token found: ${token.substring(0, 20)}...');
      } else {
        print('❌ [DEBUG] No token found in SharedPreferences!');
      }
      
      return token;
    } catch (e) {
      print('❌ [DEBUG] Error getting token: ${e.toString()}');
      return null;
    }
  }

  // Get auth headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
    
    print('🔍 [DEBUG] Request headers prepared');
    return headers;
  }

  // Send a message
  static Future<Map<String, dynamic>> sendMessage(
    int chatRoomId,
    String message, {
    String messageType = 'text',
  }) async {
    print('\n🚀 ============ STARTING SEND MESSAGE ============');
    print('📝 [DEBUG] Chat Room ID: $chatRoomId');
    print('📝 [DEBUG] Message: $message');
    print('📝 [DEBUG] Message Type: $messageType');
    
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/therapist/chats/$chatRoomId/messages';
      
      print('🌐 [DEBUG] Full URL: $url');
      print('🔑 [DEBUG] Headers: ${headers.keys.join(", ")}');
      
      final body = {
        'message': message,
        'message_type': messageType,
      };
      
      print('📦 [DEBUG] Request Body: ${json.encode(body)}');
      print('⏳ [DEBUG] Sending HTTP POST request...');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ [DEBUG] Request timed out after 30 seconds');
          throw Exception('Request timeout');
        },
      );

      print('📥 [DEBUG] Response received!');
      print('📊 [DEBUG] Status Code: ${response.statusCode}');
      print('📄 [DEBUG] Response Headers: ${response.headers}');
      print('📄 [DEBUG] Response Body: ${response.body}');

      // Try to parse response
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
        print('✅ [DEBUG] JSON parsed successfully');
      } catch (e) {
        print('❌ [DEBUG] Failed to parse JSON: ${e.toString()}');
        return {
          'success': false,
          'message': 'Invalid response from server',
        };
      }

      if (response.statusCode == 201 && data['success'] == true) {
        print('✅ [DEBUG] Message sent successfully!');
        
        try {
          ChatMessage sentMessage = ChatMessage.fromJson(data['data']);
          print('✅ [DEBUG] ChatMessage object created successfully');
          
          return {
            'success': true,
            'data': sentMessage,
            'message': data['message'] ?? 'Message sent successfully',
          };
        } catch (e) {
          print('❌ [DEBUG] Error creating ChatMessage object: ${e.toString()}');
          return {
            'success': false,
            'message': 'Error parsing message data: ${e.toString()}',
          };
        }
      } else {
        print('❌ [DEBUG] Server returned error');
        print('❌ [DEBUG] Success flag: ${data['success']}');
        print('❌ [DEBUG] Error message: ${data['message']}');
        
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send message',
          'errors': data['errors'],
          'status_code': response.statusCode,
        };
      }
    } on http.ClientException catch (e) {
      print('❌ [DEBUG] HTTP Client Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network connection error. Please check your internet connection.',
      };
    } on FormatException catch (e) {
      print('❌ [DEBUG] Format Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Invalid data format received from server',
      };
    } catch (e, stackTrace) {
      print('❌ [DEBUG] Unexpected Exception: ${e.toString()}');
      print('❌ [DEBUG] Stack trace: $stackTrace');
      
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    } finally {
      print('🏁 ============ SEND MESSAGE COMPLETED ============\n');
    }
  }

  // Get all chat rooms for therapist
  static Future<Map<String, dynamic>> getChatRooms() async {
    print('\n🚀 ============ FETCHING CHAT ROOMS ============');
    
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/therapist/chats';
      
      print('🌐 [DEBUG] URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📥 [DEBUG] Status Code: ${response.statusCode}');
      print('📄 [DEBUG] Response Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        List<ChatRoom> chatRooms = (data['data'] as List)
            .map((room) => ChatRoom.fromJson(room))
            .toList();

        print('✅ [DEBUG] Fetched ${chatRooms.length} chat rooms');
        
        return {
          'success': true,
          'data': chatRooms,
        };
      } else {
        print('❌ [DEBUG] Error: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch chat rooms',
        };
      }
    } catch (e) {
      print('❌ [DEBUG] Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    } finally {
      print('🏁 ============ FETCH CHAT ROOMS COMPLETED ============\n');
    }
  }

  // Get messages for a chat room with pagination
  static Future<Map<String, dynamic>> getMessages(
    int chatRoomId, {
    int page = 1,
    int perPage = 20,
  }) async {
    print('\n🚀 ============ FETCHING MESSAGES ============');
    print('📝 [DEBUG] Chat Room ID: $chatRoomId, Page: $page');
    
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/therapist/chats/$chatRoomId/messages?page=$page&per_page=$perPage';
      
      print('🌐 [DEBUG] URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📥 [DEBUG] Status Code: ${response.statusCode}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        List<ChatMessage> messages = (data['data']['messages'] as List)
            .map((msg) => ChatMessage.fromJson(msg))
            .toList();

        MessagePagination pagination = MessagePagination.fromJson(data['data']['pagination']);

        print('✅ [DEBUG] Fetched ${messages.length} messages');
        
        return {
          'success': true,
          'messages': messages,
          'pagination': pagination,
        };
      } else {
        print('❌ [DEBUG] Error: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch messages',
        };
      }
    } catch (e) {
      print('❌ [DEBUG] Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    } finally {
      print('🏁 ============ FETCH MESSAGES COMPLETED ============\n');
    }
  }

  // Mark patient messages as read
  static Future<Map<String, dynamic>> markAsRead(int chatRoomId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/therapist/chats/$chatRoomId/mark-read'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Messages marked as read',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to mark messages as read',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}