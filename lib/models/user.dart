enum AuthProvider {
  email,
  google,
}

enum UserRole {
  reader,
  admin,
}

class User {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final AuthProvider authProvider;
  final UserRole role;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.authProvider,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    AuthProvider provider = AuthProvider.email;
    if (json['authProvider'] == 'google') {
      provider = AuthProvider.google;
    }

    UserRole role = UserRole.reader;
    if (json['role'] == 'admin') {
      role = UserRole.admin;
    }

    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? 'Leitor',
      avatarUrl: json['avatarUrl'] as String?,
      authProvider: provider,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'authProvider': authProvider.name,
      'role': role.name,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
