import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class User {
  final int? id;
  final String? name;
  final String email;
  final bool isVerified;
  final String? avatarUrl;

  const User({
    this.id,
    this.name,
    required this.email,
    this.isVerified = false,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ??
        '${json['fname'] ?? ''} ${json['lname'] ?? ''}'.trim();
    return User(
      id: json['id'] as int?,
      name: name.isEmpty ? null : name,
      email: (json['email'] ?? '') as String,
      isVerified: json['isVerified'] == true || json['is_verified'] == true,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class AuthResult {
  final String token;
  final User user;

  const AuthResult({required this.token, required this.user});
}

class ApiService {
  static const baseUrl = 'https://where-am-i-silk.vercel.app';
  static const _tokenKey = 'auth_token';

  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    late http.Response res;
    debugPrint('[API] --> $method $uri');
    if (body != null) {
      debugPrint('[API] body: ${jsonEncode(body)}');
    }
    try {
      switch (method) {
        case 'POST':
          res = await _client.post(uri,
              headers: headers ?? _headers,
              body: body == null ? null : jsonEncode(body));
          break;
        case 'PUT':
          res = await _client.put(uri,
              headers: headers ?? _headers,
              body: body == null ? null : jsonEncode(body));
          break;
        case 'DELETE':
          res = await _client.delete(uri, headers: headers ?? _headers);
          break;
        default:
          res = await _client.get(uri, headers: headers ?? _headers);
      }
    } catch (e, st) {
      debugPrint('[API] connection error: $e\n$st');
      throw ApiException('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }

    debugPrint('[API] <-- ${res.statusCode} $uri');
    debugPrint('[API] response: ${utf8.decode(res.bodyBytes)}');

    Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[API] json decode error: $e');
      throw ApiException('การตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง',
          statusCode: res.statusCode);
    }

    if (res.statusCode >= 400) {
      throw ApiException(
        (data['message'] ?? data['error'] ?? 'เกิดข้อผิดพลาด') as String,
        statusCode: res.statusCode,
      );
    }
    return data;
  }

  /// POST /api/auth/register
  Future<User> register({
    required String email,
    required String name,
    required String password,
  }) async {
    final data = await _send('POST', Uri.parse('$baseUrl/api/auth/register'),
        body: {'email': email, 'name': name, 'password': password});
    return User.fromJson((data['user'] ?? {}) as Map<String, dynamic>);
  }

  /// POST /api/auth/verify-otp — returns token + user on success
  Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final data = await _send('POST', Uri.parse('$baseUrl/api/auth/verify-otp'),
        body: {'email': email, 'otp': otp});
    final token = (data['token'] ?? data['accessToken']) as String?;
    if (token == null) {
      throw ApiException('การยืนยัน OTP ล้มเหลว');
    }
    return AuthResult(
      token: token,
      user: User.fromJson((data['user'] ?? {}) as Map<String, dynamic>),
    );
  }

  /// POST /api/auth/resend-otp
  Future<void> resendOtp({required String email}) async {
    await _send('POST', Uri.parse('$baseUrl/api/auth/resend-otp'),
        body: {'email': email});
  }

  /// POST /api/auth/login
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _send('POST', Uri.parse('$baseUrl/api/auth/login'),
        body: {'email': email, 'password': password});
    final token = (data['token'] ?? data['accessToken']) as String?;
    if (token == null) {
      throw ApiException('เข้าสู่ระบบล้มเหลว');
    }
    return AuthResult(
      token: token,
      user: User.fromJson((data['user'] ?? {}) as Map<String, dynamic>),
    );
  }

  /// POST /api/auth/forgot-password
  Future<void> forgotPassword({required String email}) async {
    await _send('POST', Uri.parse('$baseUrl/api/auth/forgot-password'),
        body: {'email': email});
  }

  /// POST /api/auth/reset-password
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _send('POST', Uri.parse('$baseUrl/api/auth/reset-password'), body: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  /// GET /api/auth/me
  Future<User> me({required String token}) async {
    final data = await _send('GET', Uri.parse('$baseUrl/api/auth/me'),
        headers: _authHeaders(token));
    return User.fromJson(data['user'] ?? data);
  }

  /// PUT /api/auth/me
  Future<User> updateProfile({
    required String token,
    String? name,
    String? fname,
    String? lname,
  }) async {
    final data = await _send('PUT', Uri.parse('$baseUrl/api/auth/me'),
        headers: _authHeaders(token),
        body: {
          'name': ?name,
          'fname': ?fname,
          'lname': ?lname,
        });
    return User.fromJson((data['user'] ?? data) as Map<String, dynamic>);
  }

  /// PUT /api/auth/change-password
  Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    await _send('PUT', Uri.parse('$baseUrl/api/auth/change-password'),
        headers: _authHeaders(token),
        body: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        });
  }

  /// POST /api/auth/logout
  Future<void> logout({String? token}) async {
    try {
      await _send(
        'POST',
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: token == null ? null : _authHeaders(token),
      );
    } finally {
      await clearToken();
    }
  }
}
