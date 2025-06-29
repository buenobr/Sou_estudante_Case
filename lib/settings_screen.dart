// =================================================================================
// 6. ARQUIVO: lib/settings_screen.dart (ATUALIZADO COM BANNER)
// =================================================================================
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final cred = EmailAuthProvider.credential(email: user!.email!, password: _currentPasswordController.text.trim());
    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha alterada com sucesso!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alterar senha: ${e.message}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text('Alterar Senha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(controller: _currentPasswordController, decoration: const InputDecoration(labelText: 'Senha Atual', border: OutlineInputBorder()), obscureText: true, validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _newPasswordController, decoration: const InputDecoration(labelText: 'Nova Senha', border: OutlineInputBorder()), obscureText: true, validator: (value) => (value == null || value.length < 6) ? 'A nova senha deve ter no mínimo 6 caracteres' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirmar Nova Senha', border: OutlineInputBorder()), obscureText: true, validator: (value) => (value != _newPasswordController.text) ? 'As senhas não coincidem' : null),
                    const SizedBox(height: 32),
                    if (_isLoading) const Center(child: CircularProgressIndicator()) else ElevatedButton(onPressed: _changePassword, child: const Text('Salvar Alterações')),
                  ],
                ),
              ),
            ),
          ),
          if (_bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
        ],
      ),
    );
  }
}