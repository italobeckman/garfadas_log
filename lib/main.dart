import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'widgets/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'database/database_helper.dart';
import 'services/restaurante_service.dart';
import 'services/prato_service.dart';
import 'services/pdf_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Inicialização obrigatória em v7.0+ (adaptada para Web vs Mobile)
  if (kIsWeb) {
    await GoogleSignIn.instance.initialize(
      clientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    );
  } else {
    await GoogleSignIn.instance.initialize(
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      clientId: dotenv.env['GOOGLE_IOS_CLIENT_ID'],
    );
  }

  final dbHelper = DatabaseHelper();
  final restauranteService = RestauranteService(dbHelper);
  final pratoService = PratoService(dbHelper);
  final pdfService = PdfService();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseHelper>.value(value: dbHelper),
        Provider<RestauranteService>.value(value: restauranteService),
        Provider<PratoService>.value(value: pratoService),
        Provider<PdfService>.value(value: pdfService),
        ChangeNotifierProvider(
          create: (context) => AppProvider(
            restauranteService: restauranteService,
            pratoService: pratoService,
          )..loadAllData(),
        ),
      ],
      child: const GarfadaLogApp(),
    ),
  );
}

class GarfadaLogApp extends StatelessWidget {
  const GarfadaLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garfada Log',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
        ),
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
