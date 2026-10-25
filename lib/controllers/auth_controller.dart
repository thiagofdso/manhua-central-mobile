import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthController extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storage;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController({
    required ApiService apiService,
    StorageService? storage,
  })  : _apiService = apiService,
        _storage = storage ?? apiService.storage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @visibleForTesting
  void setUserForTesting(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _apiService.getCurrentUser();
      _currentUser = user;
    } catch (_) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.loginWithEmail(email, password);
      _currentUser = response.user;
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : 'Falha ao realizar login';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String displayName, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(displayName, email, password);
      _currentUser = response.user;
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : 'Falha ao criar conta';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle(String idToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.loginWithGoogle(idToken);
      _currentUser = response.user;
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : 'Falha no login com Google';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.clearTokens();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.deleteAccount();
      if (success) {
        _currentUser = null;
      }
      return success;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : 'Falha ao excluir conta';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
