// =================================================================================
// ARQUIVO 3: lib/edit_promotion_screen.dart (VERSÃO CORRIGIDA NOME DA CLASSE STATE)
// =================================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EditPromotionScreen extends StatefulWidget {
  final String promotionId;
  const EditPromotionScreen({super.key, required this.promotionId});

  @override
  State<EditPromotionScreen> createState() => _EditPromotionScreenState();
}

// CORREÇÃO AQUI: Adicionar 'Screen' ao nome da classe
class _EditPromotionScreenState extends State<EditPromotionScreen> { // <--- CORREÇÃO AQUI!
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  String? _manualImageUrl;
  String? _currentImageUrl;

  String? _selectedCategory;
  final List<String> _categories = ['Software', 'Cursos', 'Produtos', 'Viagens'];

  String _selectedPriceType = 'monetario';

  @override
  void initState() {
    super.initState();
    _loadPromotionData();
  }

  String? _normalizeAndValidateUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    String link = url.trim();
    if (!link.toLowerCase().startsWith('http://') && !link.toLowerCase().startsWith('https://')) {
      link = 'https://$link';
    }
    try {
      Uri uri = Uri.parse(link);
      String scheme = uri.scheme.toLowerCase();
      String host = uri.host.toLowerCase();
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      String path = uri.path.toLowerCase();
      if (path.isNotEmpty && path != '/' && path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }
      uri = uri.replace(
        scheme: scheme,
        host: host,
        path: path,
        query: '',
        fragment: '',
        userInfo: '',
      );
      return uri.toString();
    } catch (e) {
      debugPrint('Erro ao normalizar URL: $e');
      return null;
    }
  }

  Future<void> _loadPromotionData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('promotions').doc(widget.promotionId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _titleController.text = data['title'] ?? '';
        _linkController.text = data['link'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _selectedCategory = data['category'];
        _currentImageUrl = data['imageUrl'];
        
        final double priceValue = (data['priceValue'] ?? 0.0).toDouble();
        final String fetchedPriceType = data['priceType'] ?? 'monetario';

        if (fetchedPriceType == 'monetario') {
          final formatter = NumberFormat("#,##0.00", "pt_BR");
          _priceController.text = formatter.format(priceValue);
        } else {
          _priceController.text = priceValue.toInt().toString();
        }

        setState(() {
          _selectedPriceType = fetchedPriceType;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível abrir o link $urlString')));
    }
  }

  Future<void> _showImageUrlDialog() async {
    final urlController = TextEditingController(text: _manualImageUrl ?? _currentImageUrl);
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Adicionar URL da Imagem'), content: TextField(controller: urlController, decoration: const InputDecoration(hintText: 'https://...'), autofocus: true), actions: [ TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.of(context).pop(urlController.text.trim()), child: const Text('Confirmar')) ]));
    if (result != null && result.isNotEmpty) {
      setState(() {
        _manualImageUrl = result;
        _currentImageUrl = null;
      });
    }
  }

  Future<void> _updatePromotion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final String? normalizedLink = _normalizeAndValidateUrl(_linkController.text);
    if (normalizedLink == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O link da promoção não é válido.')));
      setState(() => _isSaving = false);
      return;
    }

    try {
      String? finalImageUrl = _manualImageUrl ?? _currentImageUrl;
      
      double priceValue;
      if (_priceController.text.isEmpty) {
        priceValue = 0.0;
      } else if (_selectedPriceType == 'monetario') {
        final String priceString = _priceController.text.replaceAll('.', '').replaceAll(',', '.');
        priceValue = double.tryParse(priceString) ?? 0.0;
      } else {
        priceValue = double.tryParse(_priceController.text) ?? 0.0;
        if (priceValue < 0) priceValue = 0;
        if (priceValue > 100) priceValue = 100;
      }

      await FirebaseFirestore.instance.collection('promotions').doc(widget.promotionId).update({
        'title': _titleController.text.trim(),
        'link': normalizedLink,
        'priceValue': priceValue,
        'priceType': _selectedPriceType,
        'category': _selectedCategory,
        'imageUrl': finalImageUrl,
        'description': _descriptionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promoção atualizada com sucesso!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar promoção: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Promoção')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(value: _selectedCategory, decoration: const InputDecoration(labelText: 'Categoria'), items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _selectedCategory = v), validator: (v) => v == null ? 'Obrigatório' : null),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        labelText: 'Link',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => _launchURL(_linkController.text),
                        ),
                      ),
                      validator: (v) => _normalizeAndValidateUrl(v) == null ? 'Por favor, insira um link válido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedPriceType,
                      decoration: const InputDecoration(labelText: 'Tipo de Preço'),
                      items: const [
                        DropdownMenuItem(value: 'monetario', child: Text('Monetário (R\$)')),
                        DropdownMenuItem(value: 'porcentagem', child: Text('Porcentagem (%)')),
                      ],
                      onChanged: (newValue) {
                        setState(() {
                          _selectedPriceType = newValue!;
                          _priceController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: _selectedPriceType == 'monetario' ? 'Preço' : 'Porcentagem',
                        border: const OutlineInputBorder(),
                        prefixText: _selectedPriceType == 'monetario' ? 'R\$ ' : null,
                        suffixText: _selectedPriceType == 'porcentagem' ? '%' : null,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: _selectedPriceType == 'monetario'
                          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}$'))]
                          : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        }
                        if (_selectedPriceType == 'porcentagem') {
                          final double? percent = double.tryParse(value);
                          if (percent == null || percent < 0 || percent > 100) {
                            return 'Porcentagem inválida (0-100)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descrição'), maxLines: 4),
                    const SizedBox(height: 24),
                    const Text('Imagem Principal', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(height: 200, width: double.infinity, decoration: BoxDecoration(border: Border.all(color: Colors.grey)), child: _buildImageWidget()),
                    Center(child: TextButton.icon(icon: const Icon(Icons.link), label: const Text('Adicionar/Alterar Imagem por URL'), onPressed: _showImageUrlDialog)),
                    const SizedBox(height: 32),
                    if (_isSaving) const Center(child: CircularProgressIndicator()) else ElevatedButton(onPressed: _updatePromotion, child: const Text('Salvar Alterações')),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageWidget() {
    if (_manualImageUrl != null) return Image.network(_manualImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Text('Erro')));
    if (_currentImageUrl != null) return Image.network(_currentImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Text('Erro')));
    return const Center(child: Text('Nenhuma imagem.'));
  }
}