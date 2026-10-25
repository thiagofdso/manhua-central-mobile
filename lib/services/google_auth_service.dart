import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  GoogleAuthService([GoogleSignIn? googleSignIn])
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      try {
        await _googleSignIn.initialize();
      } catch (_) {}
      _initialized = true;
    }
  }

  Future<String?> signInAndGetIdToken() async {
    try {
      await _ensureInitialized();
      final account = await _googleSignIn.authenticate();
      return account.authentication.idToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
