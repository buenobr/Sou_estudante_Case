import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'ad_helper.dart';
import 'theme_manager.dart';

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

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final cred = EmailAuthProvider.credential(
        email: user!.email!, password: _currentPasswordController.text.trim());
    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text.trim());
      if (mounted) {
        scaffoldMessenger.showSnackBar(const SnackBar(
            content: Text('Senha alterada com sucesso!'),
            backgroundColor: Colors.green));
        navigator.pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Erro ao alterar senha: ${e.message}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  const Text('Configurações de Tema',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Modo do Aplicativo'),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeManager.themeMode,
                      onChanged: (ThemeMode? newValue) {
                        if (newValue != null) {
                          themeManager.setThemeMode(newValue);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('Seguir Sistema')),
                        DropdownMenuItem(
                            value: ThemeMode.light, child: Text('Claro')),
                        DropdownMenuItem(
                            value: ThemeMode.dark, child: Text('Escuro')),
                      ],
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 32),
                  const Text('Alterar Senha',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: !_isCurrentPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Senha Atual',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_isCurrentPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _isCurrentPasswordVisible =
                                      !_isCurrentPasswordVisible),
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_isNewPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Nova Senha',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_isNewPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _isNewPasswordVisible =
                                      !_isNewPasswordVisible),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.length < 6)
                                  ? 'A nova senha deve ter no mínimo 6 caracteres'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Confirmar Nova Senha',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible),
                            ),
                          ),
                          validator: (value) =>
                              (value != _newPasswordController.text)
                                  ? 'As senhas não coincidem'
                                  : null,
                        ),
                        const SizedBox(height: 32),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          ElevatedButton(
                              onPressed: _changePassword,
                              child: const Text('Salvar Alterações')),
                      ],
                    ),
                  ),
                ],
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