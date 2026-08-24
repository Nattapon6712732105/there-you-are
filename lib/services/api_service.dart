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
      avatarUrl: (json['avatarUrl'] ?? json['profileImage']) as String?,
    );
  }
}

class CheckInUser {
  final int? id;
  final String? name;
  final String? profileImage;

  const CheckInUser({
    this.id,
    this.name,
    this.profileImage,
  });

  factory CheckInUser.fromJson(Map<String, dynamic> json) {
    return CheckInUser(
      id: json['id'] as int?,
      name: json['name'] as String?,
      profileImage: (json['profileImage'] ?? json['avatarUrl']) as String?,
    );
  }
}

class CheckIn {
  final int id;
  final double lat;
  final double lng;
  final String? locationName;
  final String? address;
  final double? accuracy;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;
  final CheckInUser? user;

  const CheckIn({
    required this.id,
    required this.lat,
    required this.lng,
    this.locationName,
    this.address,
    this.accuracy,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.user,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    double? parseOptDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    int parseId(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return CheckIn(
      id: parseId(json['id']),
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      locationName: json['locationName']?.toString(),
      address: json['address']?.toString(),
      accuracy: parseOptDouble(json['accuracy']),
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      user: json['user'] is Map<String, dynamic>
          ? CheckInUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AuthResult {
  final String token;
  final User user;

  const AuthResult({required this.token, required this.user});
}

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.startsWith('http')) {
        return origin;
      }
    }
    return 'https://where-am-i-silk.vercel.app';
  }
  static const _tokenKey = 'auth_token';

  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[ApiService] clearToken error: $e');
    }
  }

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
          res = await _client
              .post(uri,
                  headers: headers ?? _headers,
                  body: body == null ? null : jsonEncode(body))
              .timeout(const Duration(seconds: 25));
          break;
        case 'PUT':
          res = await _client
              .put(uri,
                  headers: headers ?? _headers,
                  body: body == null ? null : jsonEncode(body))
              .timeout(const Duration(seconds: 25));
          break;
        case 'DELETE':
          res = await _client
              .delete(uri, headers: headers ?? _headers)
              .timeout(const Duration(seconds: 25));
          break;
        default:
          res = await _client
              .get(uri, headers: headers ?? _headers)
              .timeout(const Duration(seconds: 25));
      }
    } catch (e, st) {
      debugPrint('[API] connection error: $e\n$st');
      if (kIsWeb) {
        throw ApiException(
            'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ (ติด CORS หรือเซิร์ฟเวอร์ยังไม่เปิดข้ามโดเมน)');
      }
      throw ApiException(
          'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ (หมดเวลา หรือขาดการเชื่อมต่อ)');
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

  /// GET /api/health
  Future<bool> checkHealth() async {
    try {
      final data = await _send('GET', Uri.parse('$baseUrl/api/health'));
      return data['status'] == 'ok';
    } catch (_) {
      return false;
    }
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
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (fname != null && fname.isNotEmpty) body['fname'] = fname;
    if (lname != null && lname.isNotEmpty) body['lname'] = lname;
    if (avatarUrl != null && avatarUrl.isNotEmpty) body['avatarUrl'] = avatarUrl;

    final data = await _send('PUT', Uri.parse('$baseUrl/api/auth/me'),
        headers: _authHeaders(token), body: body);
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

  /// DELETE /api/auth/me
  Future<void> deleteAccount({required String token}) async {
    try {
      await _send(
        'DELETE',
        Uri.parse('$baseUrl/api/auth/me'),
        headers: _authHeaders(token),
      );
    } finally {
      await clearToken();
    }
  }

  /// POST /api/auth/logout
  Future<void> logout({String? token}) async {
    try {
      if (token != null) {
        await _send(
          'POST',
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: _authHeaders(token),
        );
      }
    } finally {
      await clearToken();
    }
  }

  /// GET /api/checking
  Future<List<CheckIn>> getCheckIns() async {
    final data = await _send('GET', Uri.parse('$baseUrl/api/checking'));
    final list = (data['checkins'] ?? data['data'] ?? []) as List;
    return list
        .map((e) => CheckIn.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/checking
  Future<CheckIn> createCheckIn({
    required String token,
    required double lat,
    required double lng,
    String? locationName,
    String? description,
    double? accuracy,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'lat': lat,
      'lng': lng,
    };
    if (locationName != null && locationName.isNotEmpty) {
      body['locationName'] = locationName;
    }
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (accuracy != null) body['accuracy'] = accuracy;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      body['imageUrl'] = imageUrl;
    }

    final data = await _send(
      'POST',
      Uri.parse('$baseUrl/api/checking'),
      headers: _authHeaders(token),
      body: body,
    );
    final checkinData =
        (data['checkin'] ?? data['data'] ?? data) as Map<String, dynamic>;
    return CheckIn.fromJson(checkinData);
  }

  /// PUT /api/checking
  Future<CheckIn> updateCheckIn({
    required String token,
    required int id,
    double? lat,
    double? lng,
    String? locationName,
    String? description,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{'id': id};
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;
    if (locationName != null) body['locationName'] = locationName;
    if (description != null) body['description'] = description;
    if (imageUrl != null) body['imageUrl'] = imageUrl;

    final data = await _send(
      'PUT',
      Uri.parse('$baseUrl/api/checking'),
      headers: _authHeaders(token),
      body: body,
    );
    final checkinData =
        (data['checkin'] ?? data['data'] ?? data) as Map<String, dynamic>;
    return CheckIn.fromJson(checkinData);
  }

  /// DELETE /api/checking?id={id}
  Future<void> deleteCheckIn({
    required String token,
    required int id,
  }) async {
    await _send(
      'DELETE',
      Uri.parse('$baseUrl/api/checking?id=$id'),
      headers: _authHeaders(token),
    );
  }
}
