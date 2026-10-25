import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manhua_mobile/controllers/auth_controller.dart';
import 'package:manhua_mobile/main.dart';
import 'package:manhua_mobile/screens/login_screen.dart';
import 'package:manhua_mobile/services/api_service.dart';
import 'package:manhua_mobile/services/storage_service.dart';

void main() {
  testWidgets('ManhuaApp boots into LoginScreen when not authenticated', (WidgetTester tester) async {
    final storage = InMemoryStorageService();
    final apiService = ApiService(
      baseUrl: 'http://localhost:8080',
      client: MockClient((_) async => http.Response('{}', 401)),
      storage: storage,
    );
    final authController = AuthController(apiService: apiService, storage: storage);

    await tester.pumpWidget(ManhuaApp(
      apiService: apiService,
      authController: authController,
    ));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Manhua Central'), findsOneWidget);
  });
}
