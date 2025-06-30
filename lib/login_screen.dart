// =================================================================================
// ARQUIVO 2: lib/login_screen.dart
// =================================================================================
// Copie e cole todo este conteúdo no seu arquivo lib/login_screen.dart,
// substituindo tudo que está lá.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      await _createUserDocument(userCredential.user!);
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar('Erro no cadastro: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _createUserDocument(userCredential.user!);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Erro ao fazer login com Google: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createUserDocument(User user) async {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userDocRef.get();
    if (!doc.exists) {
      await userDocRef.set({
        'email': user.email,
        'uid': user.uid,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'role': 'user',
        'favorites': [],
        'createdAt': Timestamp.now(),
      });
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
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  // MUDANÇA: Voltamos a usar a imagem da pasta assets
                  icon: Image.asset('assets/google_logo.png', height: 24.0),
                  label: const Text('Entrar com Google'),
                  onPressed: _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black, backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('OU'),
                const SizedBox(height: 16),
                TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress, validator: (value) => value!.isEmpty ? 'Por favor, insira um e-mail' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()), obscureText: true, validator: (value) => value!.length < 6 ? 'A senha deve ter no mínimo 6 caracteres' : null),
                const SizedBox(height: 24),
                if (_isLoading) const CircularProgressIndicator() else Column(children: [ SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _signIn, child: const Text('Entrar com E-mail'))), const SizedBox(height: 16), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _signUp, child: const Text('Não tenho conta, quero me cadastrar'))) ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}