import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/manhua.dart';
import '../models/ranking.dart';
import '../models/library_item.dart';
import '../models/reader.dart';
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

  Future<List<CanonicalManhua>> getCatalog({String? query, int page = 1, int pageSize = 20}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (query != null && query.isNotEmpty) {
      queryParams['query'] = query;
    }

    final uri = Uri.parse('$baseUrl/api/catalog').replace(queryParameters: queryParams);
    final response = await client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return items.map((e) => CanonicalManhua.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw ApiException('Falha ao carregar catálogo', response.statusCode);
    }
  }

  Future<List<RankedManhua>> getRankings(String type, {int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/api/rankings').replace(queryParameters: {
      'type': type,
      'limit': limit.toString(),
    });
    final response = await client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => RankedManhua.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw ApiException('Falha ao carregar rankings', response.statusCode);
    }
  }

  Future<List<UserLibrary>> getLibrary() async {
    final token = await storage.getAccessToken();
    if (token == null) return [];

    final response = await client.get(
      Uri.parse('$baseUrl/api/library'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => UserLibrary.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw ApiException('Falha ao carregar biblioteca', response.statusCode);
    }
  }

  Future<UserLibrary> addToLibrary(int canonicalManhuaId, {int currentChapter = 1, bool isFavorite = false}) async {
    final token = await storage.getAccessToken();
    if (token == null) throw ApiException('Não autenticado', 401);

    final response = await client.post(
      Uri.parse('$baseUrl/api/library'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'canonicalManhuaId': canonicalManhuaId,
        'currentChapter': currentChapter,
        'isFavorite': isFavorite,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserLibrary.fromJson(json);
    } else {
      throw ApiException('Falha ao adicionar à biblioteca', response.statusCode);
    }
  }

  Future<UserLibrary> updateProgress(String libraryId, int currentChapter) async {
    final token = await storage.getAccessToken();
    if (token == null) throw ApiException('Não autenticado', 401);

    final response = await client.patch(
      Uri.parse('$baseUrl/api/library/$libraryId/progress'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'currentChapter': currentChapter}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserLibrary.fromJson(json);
    } else {
      throw ApiException('Falha ao atualizar progresso', response.statusCode);
    }
  }

  Future<UserLibrary> toggleFavorite(String libraryId, bool isFavorite) async {
    final token = await storage.getAccessToken();
    if (token == null) throw ApiException('Não autenticado', 401);

    final response = await client.patch(
      Uri.parse('$baseUrl/api/library/$libraryId/favorite'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'isFavorite': isFavorite}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserLibrary.fromJson(json);
    } else {
      throw ApiException('Falha ao alternar favorito', response.statusCode);
    }
  }

  Future<void> reorderLibrary(List<String> orderedIds) async {
    final token = await storage.getAccessToken();
    if (token == null) throw ApiException('Não autenticado', 401);

    final response = await client.put(
      Uri.parse('$baseUrl/api/library/order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'orderedIds': orderedIds}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Falha ao reordenar biblioteca', response.statusCode);
    }
  }

  Future<void> removeFromLibrary(String libraryId) async {
    final token = await storage.getAccessToken();
    if (token == null) throw ApiException('Não autenticado', 401);

    final response = await client.delete(
      Uri.parse('$baseUrl/api/library/$libraryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Falha ao remover da biblioteca', response.statusCode);
    }
  }

  Future<void> submitRating(int canonicalManhuaId, int score) async {
    final token = await storage.getAccessToken();
    if (token == null) throw ApiException('Não autenticado', 401);

    final response = await client.post(
      Uri.parse('$baseUrl/api/ratings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'canonicalManhuaId': canonicalManhuaId,
        'score': score,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Falha ao registrar avaliação', response.statusCode);
    }
  }

  Future<void> registerFcmToken(String token) async {
    final jwt = await storage.getAccessToken();
    if (jwt == null) return;

    final response = await client.post(
      Uri.parse('$baseUrl/api/users/fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Falha ao registrar token FCM', response.statusCode);
    }
  }

  Future<ChapterImagesResponse> getChapterImages(String slug, int chapter) async {
    final uri = Uri.parse('$baseUrl/api/reader/chapter-images').replace(queryParameters: {
      'slug': slug,
      'chapter': chapter.toString(),
    });
    final response = await client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ChapterImagesResponse.fromJson(json);
    } else {
      String errMsg = 'Falha ao carregar imagens do capítulo';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error'] != null) errMsg = errJson['error'];
      } catch (_) {}
      throw ApiException(errMsg, response.statusCode);
    }
  }
}
