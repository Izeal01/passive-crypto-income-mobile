import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/api_keys_provider.dart';
import 'services/api_service.dart';  // For global init of base URL
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wrap in try-catch for robust error handling/logging during init
  try {
    await ApiService.loadBaseUrl();  // Load saved base URL early (defaults to local if none saved)
  } catch (e) {
    // Log error (in prod, use proper logger; here, debugPrint for dev)
    debugPrint('Init failed: $e');
    // Optionally, set fallback base URL or show error screen
    ApiService.setBaseUrl('http://192.168.0.3:8000/');  // Fallback to local dev
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiKeysProvider()),  // Singleton-like for keys across screens
      ],
      child: MaterialApp(
        title: 'Passive Crypto Income',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
