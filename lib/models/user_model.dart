import 'package:pos_azmi/models/setting_model.dart';

class AuthResponse {
  final bool ok;
  final int code;
  final String accessToken;
  final String tokenType;
  final UserModel user;
  final Setting setting;

  AuthResponse({
    required this.ok,
    required this.code,
    required this.accessToken,
    required this.tokenType,
    required this.user,
    required this.setting,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return AuthResponse(
      ok: json['ok'] ?? false,
      code: json['code'] ?? 0,
      accessToken: data['access_token'] ?? '',
      tokenType: data['token_type'] ?? '',
      user: UserModel.fromJson(data['user'] ?? {}),
      setting: Setting.fromJson(data['setting'] ?? {}),
    );
  }
}

class UserModel {
  final int id;
  final int roleId;
  final String name;
  final String username;
  final String email;
  final String? emailVerifiedAt;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  UserModel({
    required this.id,
    required this.roleId,
    required this.name,
    required this.username,
    required this.email,
    this.emailVerifiedAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      roleId: json['role_id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      emailVerifiedAt: json['email_verified_at'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_id': roleId,
      'name': name,
      'username': username,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }
}
