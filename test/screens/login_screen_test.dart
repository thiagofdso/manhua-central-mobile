import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:manhua_mobile/controllers/auth_controller.dart';
import 'package:manhua_mobile/screens/login_screen.dart';
import 'package:manhua_mobile/services/api_service.dart';
import 'package:manhua_mobile/services/storage_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  testWidgets('LoginScreen renders email, password fields and Google Sign-In button', (tester) async {
    final storage = InMemoryStorageService();
    final apiService = ApiService(
      baseUrl: 'http://localhost:8080',
      client: MockClient((_) async => http.Response('{}', 200)),
      storage: storage,
    );
    final authController = AuthController(apiService: apiService, storage: storage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authController),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Manhua Central'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Continuar com o Google'), findsOneWidget);
  });
}
