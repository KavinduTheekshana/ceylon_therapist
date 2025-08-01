class TherapistService {
  final int id;
  final String title;
  final ServicePivot pivot;

  TherapistService({
    required this.id,
    required this.title,
    required this.pivot,
  });

  factory TherapistService.fromJson(Map<String, dynamic> json) {
    return TherapistService(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      pivot: ServicePivot.fromJson(json['pivot'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pivot': pivot.toJson(),
    };
  }
}

class ServicePivot {
  final int therapistId;
  final int serviceId;
  final String createdAt;
  final String updatedAt;

  ServicePivot({
    required this.therapistId,
    required this.serviceId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServicePivot.fromJson(Map<String, dynamic> json) {
    return ServicePivot(
      therapistId: json['therapist_id'] ?? 0,
      serviceId: json['service_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'therapist_id': therapistId,
      'service_id': serviceId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Therapist {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String? image;
  final String workStartDate;
  final bool status;
  final String? emailVerifiedAt;
  final String? lastLoginAt;
  final List<TherapistService> services;
  final int availabilityCount;

  Therapist({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    this.image,
    required this.workStartDate,
    required this.status,
    this.emailVerifiedAt,
    this.lastLoginAt,
    required this.services,
    required this.availabilityCount,
  });

  factory Therapist.fromJson(Map<String, dynamic> json) {
    return Therapist(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      bio: json['bio'] ?? '',
      image: json['image'],
      workStartDate: json['work_start_date'] ?? '',
      status: json['status'] ?? false,
      emailVerifiedAt: json['email_verified_at'],
      lastLoginAt: json['last_login_at'],
      services: (json['services'] as List<dynamic>?)
          ?.map((service) => TherapistService.fromJson(service))
          .toList() ?? [],
      availabilityCount: json['availability_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'image': image,
      'work_start_date': workStartDate,
      'status': status,
      'email_verified_at': emailVerifiedAt,
      'last_login_at': lastLoginAt,
      'services': services.map((service) => service.toJson()).toList(),
      'availability_count': availabilityCount,
    };
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final LoginData data;

  LoginResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: LoginData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class LoginData {
  final Therapist therapist;
  final String accessToken;
  final String tokenType;

  LoginData({
    required this.therapist,
    required this.accessToken,
    required this.tokenType,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      therapist: Therapist.fromJson(json['therapist'] ?? {}),
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'therapist': therapist.toJson(),
      'access_token': accessToken,
      'token_type': tokenType,
    };
  }
}

// API Service Helper
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}