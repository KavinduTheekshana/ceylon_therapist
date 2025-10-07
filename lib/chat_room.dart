// lib/chat_room.dart

class ChatRoom {
  final int id;
  final Patient patient;
  final LastMessage? lastMessage;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.patient,
    this.lastMessage,
    required this.unreadCount,
    this.lastMessageAt,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      patient: Patient.fromJson(json['patient']),
      lastMessage: json['last_message'] != null 
          ? LastMessage.fromJson(json['last_message']) 
          : null,
      unreadCount: json['unread_count'],
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient': patient.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Patient {
  final int id;
  final String name;
  final String? image;

  Patient({
    required this.id,
    required this.name,
    this.image,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }
}

class LastMessage {
  final String content;
  final DateTime sentAt;
  final String senderName;
  final String senderType; // 'patient' or 'therapist'

  LastMessage({
    required this.content,
    required this.sentAt,
    required this.senderName,
    required this.senderType,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content'],
      sentAt: DateTime.parse(json['sent_at']),
      senderName: json['sender_name'],
      senderType: json['sender_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'sent_at': sentAt.toIso8601String(),
      'sender_name': senderName,
      'sender_type': senderType,
    };
  }
}