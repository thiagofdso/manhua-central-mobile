import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, [this.statusCode = 500]);

  @override
  String toString() => 'ApiException: $message (code: $statusCode)';
}

class ApiService {
  final String baseUrl;
  final http.Client client;
  final StorageService storage;

  ApiService({
    required this.baseUrl,
    http.Client? client,
    StorageService? storage,
  })  : client = client ?? http.Client(),
        storage = storage ?? SecureStorageService();

  Future<AuthResponse> loginWithGoogle(String idToken) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(json);

      await storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      return authResponse;
    } else {
      String errMsg = 'Falha ao autenticar com Google';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error'] != null) errMsg = errJson['error'];
      } catch (_) {}
      throw ApiException(errMsg, response.statusCode);
    }
  }

  Future<AuthResponse> loginWithEmail(String email, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(json);

      await storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      return authResponse;
    } else {
      String errMsg = 'Credenciais inválidas';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error'] != null) errMsg = errJson['error'];
      } catch (_) {}
      throw ApiException(errMsg, response.statusCode);
    }
  }

  Future<AuthResponse> register(String displayName, String email, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'displayName': displayName,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(json);

      await storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      return authResponse;
    } else {
      String errMsg = 'Falha ao criar conta';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error'] != null) errMsg = errJson['error'];
      } catch (_) {}
      throw ApiException(errMsg, response.statusCode);
    }
  }

  Future<bool> deleteAccount() async {
    final token = await storage.getAccessToken();
    if (token == null) {
      throw ApiException('Não autenticado', 401);
    }

    final response = await client.delete(
      Uri.parse('$baseUrl/api/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await storage.clearTokens();
      return true;
    } else {
      throw ApiException('Falha ao excluir conta', response.statusCode);
    }
  }

  Future<User?> getCurrentUser() async {
    final token = await storage.getAccessToken();
    if (token == null) return null;

    final response = await client.get(
      Uri.parse('$baseUrl/api/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(json);
    }
    return null;
  }
}
