// lib/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_room.dart';
import 'services/therapist_chat_service.dart';
import 'chat_conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  final Color _primaryColor = const Color(0xFF9A563A);
  final Color _backgroundColor = const Color(0xFFF5F5F5);
  final Color _cardColor = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _fetchChatRooms();
  }

  Future<void> _fetchChatRooms({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await TherapistChatService.getChatRooms();

      if (result['success'] == true) {
        setState(() {
          _chatRooms = result['data'] as List<ChatRoom>;
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load chats';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 24) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  void _openConversation(ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatConversationScreen(
          chatRoom: chatRoom,
        ),
      ),
    ).then((_) {
      // Refresh chat list when returning from conversation
      _fetchChatRooms(isRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        title: const Text(
          'Patient Chats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: _primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchChatRooms(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your patient conversations will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () => _fetchChatRooms(isRefresh: true),
      child: ListView.builder(
        itemCount: _chatRooms.length,
        itemBuilder: (context, index) {
          return _buildChatRoomItem(_chatRooms[index]);
        },
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom chatRoom) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openConversation(chatRoom),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Patient avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      backgroundImage: chatRoom.patient.image != null
                          ? NetworkImage(chatRoom.patient.image!)
                          : null,
                      child: chatRoom.patient.image == null
                          ? Text(
                              chatRoom.patient.name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                            )
                          : null,
                    ),
                    // Unread badge
                    if (chatRoom.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: _cardColor, width: 2),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              chatRoom.unreadCount > 99
                                  ? '99+'
                                  : chatRoom.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chatRoom.patient.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: chatRoom.unreadCount > 0
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(chatRoom.lastMessageAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: chatRoom.unreadCount > 0
                                  ? _primaryColor
                                  : Colors.black45,
                              fontWeight: chatRoom.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (chatRoom.lastMessage != null)
                        Text(
                          chatRoom.lastMessage!.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: chatRoom.unreadCount > 0
                                ? Colors.black87
                                : Colors.black54,
                            fontWeight: chatRoom.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black38,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}