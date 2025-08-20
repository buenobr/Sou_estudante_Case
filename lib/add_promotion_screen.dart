import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'promotion_submitted_screen.dart';

class CurrencyPtBrInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    double value = double.parse(newText) / 100;
    final formatter = NumberFormat("#,##0.00", "pt_BR");
    String formattedText = formatter.format(value);
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class AddPromotionScreen extends StatefulWidget {
  const AddPromotionScreen({super.key});
  @override
  State<AddPromotionScreen> createState() => _AddPromotionScreenState();
}

class _AddPromotionScreenState extends State<AddPromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isFetchingLink = false;

  String? _manualImageUrl;
  String? _autoFetchedImageUrl;
  String? _selectedCategory;
  final List<String> _categories = ['Software', 'Cursos', 'Produtos', 'Viagens'];

  String _selectedPriceType = 'monetario';

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

  Future<void> _fetchLinkPreview() async {
    final normalizedLink = _normalizeAndValidateUrl(_linkController.text);
    if (normalizedLink == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, insira um link válido.')));
      return;
    }
    setState(() { _isFetchingLink = true; _autoFetchedImageUrl = null; });
    try {
      final metadata = await AnyLinkPreview.getMetadata(link: normalizedLink);
      if (mounted && metadata != null) {
        setState(() {
          if (metadata.title != null) _titleController.text = metadata.title!;
          if (metadata.image != null) _autoFetchedImageUrl = metadata.image;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar preview do link: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLink = false);
    }
  }

  Future<void> _showImageUrlDialog() async {
    final urlController = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Adicionar URL da Imagem'), content: TextField(controller: urlController, decoration: const InputDecoration(hintText: 'https://...'), autofocus: true), actions: [ TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.of(context).pop(urlController.text.trim()), child: const Text('Confirmar')) ]));
    if (result != null && result.isNotEmpty) {
      setState(() {
        _manualImageUrl = result;
      });
    }
  }

  Future<void> _submitPromotion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione uma categoria.')));
      return;
    }
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você precisa estar logado para enviar promoções!')));
      setState(() => _isLoading = false);
      return;
    }

    final String? normalizedLink = _normalizeAndValidateUrl(_linkController.text);

    if (normalizedLink == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O link da promoção não é válido.')));
      setState(() => _isLoading = false);
      return;
    }

    String finalLink;

    try {
      final existingPromotions = await FirebaseFirestore.instance
          .collection('promotions')
          .where('link', isEqualTo: normalizedLink)
          .limit(1)
          .get();

      if (existingPromotions.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta oferta já existe! Não podemos enviar ofertas duplicadas.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      String? finalImageUrl = _manualImageUrl ?? _autoFetchedImageUrl;

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

      finalLink = normalizedLink;

      await FirebaseFirestore.instance.collection('promotions').add({
        'title': _titleController.text.trim(),
        'link': finalLink,
        'priceValue': priceValue,
        'priceType': _selectedPriceType,
        'category': _selectedCategory,
        'imageUrl': finalImageUrl,
        'description': _descriptionController.text.trim(),
        'submittedBy': user.uid,
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promoção enviada para aprovação!')));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PromotionSubmittedScreen()),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar promoção: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Promoção')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Título da Promoção'), validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(value: _selectedCategory, decoration: const InputDecoration(labelText: 'Categoria'), items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _selectedCategory = v), validator: (v) => v == null ? 'Campo obrigatório' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _linkController, decoration: const InputDecoration(labelText: 'Link da Promoção'), keyboardType: TextInputType.url, validator: (value) => _normalizeAndValidateUrl(value) == null ? 'Por favor, insira um link válido' : null),
              Align(alignment: Alignment.centerRight, child: TextButton.icon(icon: const Icon(Icons.search, size: 20), label: const Text('Buscar dados do link'), onPressed: _fetchLinkPreview)),

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

              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descrição (opcional)', border: const OutlineInputBorder()), maxLines: 4),
              const SizedBox(height: 24),
              const Text('Imagem Principal', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(height: 200, width: double.infinity, decoration: BoxDecoration(border: Border.all(color: Colors.grey)), child: _buildImageWidget()),
              Center(child: TextButton.icon(icon: const Icon(Icons.link), label: const Text('Adicionar/Alterar Imagem por URL'), onPressed: _showImageUrlDialog)),
              const SizedBox(height: 32),
              if (_isLoading) const Center(child: CircularProgressIndicator()) else SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submitPromotion, child: const Text('Enviar Promoção'))),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildImageWidget() {
    if (_manualImageUrl != null) return Image.network(_manualImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Text('Erro ao carregar imagem.')));
    if (_isFetchingLink) return const Center(child: CircularProgressIndicator());
    if (_autoFetchedImageUrl != null) return Image.network(_autoFetchedImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Text('Erro ao carregar imagem.')));
    return const Center(child: Text('Busque um link ou adicione uma imagem.'));
  }
}
