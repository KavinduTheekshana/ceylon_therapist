// lib/chat_conversation_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_room.dart';
import 'chat_message.dart';
import 'pagination.dart';
import 'services/therapist_chat_service.dart';

class ChatConversationScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatConversationScreen({
    Key? key,
    required this.chatRoom,
  }) : super(key: key);

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  MessagePagination? _pagination;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMore = false;

  final Color _primaryColor = const Color(0xFF9A563A);
  final Color _backgroundColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _markAsRead();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_pagination != null && _pagination!.hasMorePages && !_isLoadingMore) {
        _loadMoreMessages();
      }
    }
  }

  Future<void> _fetchMessages({int page = 1}) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await TherapistChatService.getMessages(
        widget.chatRoom.id,
        page: page,
      );

      if (result['success'] == true) {
        setState(() {
          if (page == 1) {
            _messages = result['messages'] as List<ChatMessage>;
          } else {
            _messages.addAll(result['messages'] as List<ChatMessage>);
          }
          _pagination = result['pagination'] as MessagePagination;
          _isLoading = false;
          _isLoadingMore = false;
        });

        // Scroll to bottom on initial load
        if (page == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        _showErrorSnackBar(result['message'] ?? 'Failed to load messages');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_pagination == null || !_pagination!.hasMorePages) return;

    setState(() {
      _isLoadingMore = true;
    });

    await _fetchMessages(page: _pagination!.currentPage + 1);
  }

  Future<void> _markAsRead() async {
    await TherapistChatService.markAsRead(widget.chatRoom.id);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    try {
      final result = await TherapistChatService.sendMessage(
        widget.chatRoom.id,
        message,
      );

      if (result['success'] == true) {
        setState(() {
          _messages.add(result['data'] as ChatMessage);
          _isSending = false;
        });

        // Scroll to bottom after sending
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        setState(() {
          _isSending = false;
        });
        _messageController.text = message;
        _showErrorSnackBar(result['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      _messageController.text = message;
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _primaryColor.withOpacity(0.1),
              backgroundImage: widget.chatRoom.patient.image != null
                  ? NetworkImage(widget.chatRoom.patient.image!)
                  : null,
              child: widget.chatRoom.patient.image == null
                  ? Text(
                      widget.chatRoom.patient.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.chatRoom.patient.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: _primaryColor,
        ),
      );
    }

    if (_messages.isEmpty) {
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
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start the conversation with your patient',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && _isLoadingMore) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            ),
          );
        }

        final messageIndex = _isLoadingMore ? index - 1 : index;
        return _buildMessageBubble(_messages[messageIndex]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMyMessage = message.sender.isTherapist;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMyMessage ? _primaryColor : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isMyMessage ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight: isMyMessage ? const Radius.circular(4) : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMyMessage)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.sender.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isMyMessage ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.sentAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isMyMessage 
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Colors.black38,
                      fontSize: 15,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}