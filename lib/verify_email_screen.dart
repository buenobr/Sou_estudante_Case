import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_colors.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkEmailVerified());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    if (user?.emailVerified ?? false) {
      _timer?.cancel();
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail de verificação reenviado!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reenviar e-mail: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'seu e-mail';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação de E-mail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined, size: 100, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Verifique seu E-mail',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Enviamos um link de verificação para $userEmail. Por favor, clique no link para ativar sua conta.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Aguardando verificação...'),
              const SizedBox(height: 32),
              TextButton(
                onPressed: _resendVerificationEmail,
                child: const Text('Não recebeu? Reenviar e-mail'),
              ),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}