// =================================================================================
// 4. ARQUIVO: lib/login_screen.dart (ATUALIZADO)
// =================================================================================
// Adicionada a criação do documento do usuário no Firestore ao se cadastrar.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar('Erro no login: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
      
      // CRIA O DOCUMENTO DO USUÁRIO NO FIRESTORE
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'uid': userCredential.user!.uid,
        'role': 'user', // Papel padrão
        'favorites': [], // Lista de favoritos inicial
        'createdAt': Timestamp.now(),
      });

      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar('Erro no cadastro: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Cadastro')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Acesse sua conta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress, validator: (value) => value!.isEmpty ? 'Por favor, insira um e-mail' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()), obscureText: true, validator: (value) => value!.length < 6 ? 'A senha deve ter no mínimo 6 caracteres' : null),
                const SizedBox(height: 24),
                if (_isLoading) const CircularProgressIndicator() else Column(children: [ SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _signIn, child: const Text('Entrar'))), const SizedBox(height: 16), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _signUp, child: const Text('Não tenho conta, quero me cadastrar'))) ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}