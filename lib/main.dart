import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureStorageService();
  final apiService = ApiService(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080'),
    storage: storage,
  );
  final authController = AuthController(apiService: apiService, storage: storage);
  await authController.initAuth();

  runApp(ManhuaApp(
    apiService: apiService,
    authController: authController,
  ));
}

class ManhuaApp extends StatelessWidget {
  final ApiService apiService;
  final AuthController authController;

  const ManhuaApp({
    super.key,
    required this.apiService,
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<AuthController>.value(value: authController),
      ],
      child: Consumer<AuthController>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Manhua Central',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF090D16),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF6366F1),
                surface: Color(0xFF131B2E),
              ),
            ),
            home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
