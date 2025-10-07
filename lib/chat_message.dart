// lib/chat_message.dart

class ChatMessage {
  final int id;
  final String content;
  final MessageSender sender;
  final String messageType;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? editedAt;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.messageType,
    required this.isRead,
    required this.sentAt,
    this.editedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      sender: MessageSender.fromJson(json['sender']),
      messageType: json['message_type'],
      isRead: json['is_read'],
      sentAt: DateTime.parse(json['sent_at']),
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender.toJson(),
      'message_type': messageType,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
    };
  }
}

class MessageSender {
  final int id;
  final String name;
  final String type; // 'patient' or 'therapist'

  MessageSender({
    required this.id,
    required this.name,
    required this.type,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  bool get isPatient => type == 'patient';
  bool get isTherapist => type == 'therapist';
}