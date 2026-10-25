import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/download_manager.dart';
import 'services/offline_reader_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureStorageService();
  final apiService = ApiService(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080'),
    storage: storage,
  );
  final offlineService = OfflineReaderService();
  final downloadManager = DownloadManager(
    apiService: apiService,
    offlineService: offlineService,
  );
  final authController = AuthController(apiService: apiService, storage: storage);
  await authController.initAuth();

  runApp(ManhuaApp(
    apiService: apiService,
    authController: authController,
    offlineService: offlineService,
    downloadManager: downloadManager,
  ));
}

class ManhuaApp extends StatelessWidget {
  final ApiService apiService;
  final AuthController authController;
  final OfflineReaderService? offlineService;
  final DownloadManager? downloadManager;

  const ManhuaApp({
    super.key,
    required this.apiService,
    required this.authController,
    this.offlineService,
    this.downloadManager,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOffline = offlineService ?? OfflineReaderService();
    final effectiveDownload = downloadManager ?? DownloadManager(
      apiService: apiService,
      offlineService: effectiveOffline,
    );

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        Provider<OfflineReaderService>.value(value: effectiveOffline),
        ChangeNotifierProvider<DownloadManager>.value(value: effectiveDownload),
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
