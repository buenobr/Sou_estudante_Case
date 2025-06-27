import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Promo Student',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// CORREÇÃO IMPORTANTE: Convertido para StatefulWidget para evitar loop infinito.
// O login anônimo agora é chamado apenas UMA VEZ quando o app inicia.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Verifica se o usuário atual é nulo e só então tenta o login anônimo.
    // Isso roda apenas uma vez quando o widget é criado.
    if (FirebaseAuth.instance.currentUser == null) {
      FirebaseAuth.instance.signInAnonymously();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se a conexão está esperando, mostra um loading.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se tem um usuário (anônimo ou real), vai para a HomeScreen.
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Se algo der muito errado (não deveria acontecer), mostra uma tela de erro.
        return const Scaffold(
          body: Center(child: Text("Erro de autenticação. Reinicie o app.")),
        );
      },
    );
  }
}