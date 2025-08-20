import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'home_screen.dart';
import 'app_colors.dart';
import 'verify_email_screen.dart';
import 'theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await MobileAds.instance.initialize().then((InitializationStatus status) {
    debugPrint('AdMob inicializado com sucesso: $status');
  }).catchError((e) {
    debugPrint('Erro ao inicializar AdMob: $e');
  });

  runApp(
    ChangeNotifierProvider<ThemeManager>(
      create: (_) => ThemeManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return MaterialApp(
      title: 'Promo Student',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(backgroundColor: AppColors.primary.shade700, foregroundColor: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[850],
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white.withOpacity(0.9)),
          bodyMedium: TextStyle(color: Colors.white.withOpacity(0.8)),
          labelLarge: TextStyle(color: Colors.white.withOpacity(0.9)),
        ),
      ),
      themeMode: themeManager.themeMode,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  Future<void> _signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint("Erro ao fazer login anônimo: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (!user.isAnonymous && !user.emailVerified) {
            return const VerifyEmailScreen();
          }
          return const HomeScreen();
        }
        return FutureBuilder(
          future: _signInAnonymously(),
          builder: (context, futureSnapshot) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          },
        );
      },
    );
  }
}