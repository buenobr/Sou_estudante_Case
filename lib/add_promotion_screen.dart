// 4. QUARTO PASSO: Substitua o conteúdo do seu arquivo lib/add_promotion_screen.dart.
// Ele foi ajustado para usar as cores do tema.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:any_link_preview/any_link_preview.dart';

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

  File? _manualImageFile;
  String? _manualImageUrl;
  String? _autoFetchedImageUrl;

  String? _selectedCategory;
  final List<String> _categories = ['Software', 'Cursos', 'Produtos', 'Viagens'];

  Future<void> _fetchLinkPreview() async {
    final link = _linkController.text.trim();
    if (link.isEmpty || !link.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, insira um link válido.')));
      return;
    }
    setState(() { _isFetchingLink = true; _autoFetchedImageUrl = null; });
    try {
      final metadata = await AnyLinkPreview.getMetadata(link: link);
      if (metadata != null) {
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

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _manualImageFile = File(pickedFile.path);
        _manualImageUrl = null;
      });
    }
  }

  Future<void> _showImageUrlDialog() async {
    final urlController = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Adicionar URL da Imagem'), content: TextField(controller: urlController, decoration: const InputDecoration(hintText: 'https://...'), autofocus: true), actions: [ TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.of(context).pop(urlController.text.trim()), child: const Text('Confirmar')) ]));
    if (result != null && result.isNotEmpty) {
      setState(() {
        _manualImageUrl = result;
        _manualImageFile = null;
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
      setState(() => _isLoading = false);
      return;
    }

    try {
      String? finalImageUrl;
      if (_manualImageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('promotion_images').child('${DateTime.now().toIso8601String()}.jpg');
        await ref.putFile(_manualImageFile!);
        finalImageUrl = await ref.getDownloadURL();
      } else if (_manualImageUrl != null) {
        finalImageUrl = _manualImageUrl;
      } else {
        finalImageUrl = _autoFetchedImageUrl;
      }

      await FirebaseFirestore.instance.collection('promotions').add({
        'title': _titleController.text.trim(),
        'link': _linkController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'category': _selectedCategory,
        'imageUrl': finalImageUrl,
        'description': _descriptionController.text.trim(),
        'submittedBy': user.uid,
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promoção enviada para aprovação!')));
        Navigator.of(context).pop();
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
              DropdownButtonFormField<String>(value: _selectedCategory, decoration: const InputDecoration(labelText: 'Categoria'), items: _categories.map((String category) => DropdownMenuItem<String>(value: category, child: Text(category))).toList(), onChanged: (newValue) => setState(() => _selectedCategory = newValue), validator: (value) => value == null ? 'Campo obrigatório' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _linkController, decoration: const InputDecoration(labelText: 'Link da Promoção'), validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null),
              Align(alignment: Alignment.centerRight, child: TextButton.icon(icon: const Icon(Icons.search, size: 20), label: const Text('Buscar dados do link'), onPressed: _fetchLinkPreview)),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Preço (ex: 99.90)'), keyboardType: TextInputType.number, validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descrição (opcional)', border: OutlineInputBorder()), maxLines: 4),
              const SizedBox(height: 24),
              const Text('Imagem Principal', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(height: 200, width: double.infinity, decoration: BoxDecoration(border: Border.all(color: Colors.grey)), child: _buildImageWidget()),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ TextButton.icon(icon: const Icon(Icons.photo_library), label: const Text('Galeria'), onPressed: _pickImageFromGallery), TextButton.icon(icon: const Icon(Icons.link), label: const Text('URL'), onPressed: _showImageUrlDialog) ]),
              const SizedBox(height: 32),
              if (_isLoading) const Center(child: CircularProgressIndicator()) else SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submitPromotion, child: const Text('Enviar Promoção'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_manualImageFile != null) return Image.file(_manualImageFile!, fit: BoxFit.cover);
    if (_manualImageUrl != null) return Image.network(_manualImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Text('Erro ao carregar imagem.')));
    if (_isFetchingLink) return const Center(child: CircularProgressIndicator());
    if (_autoFetchedImageUrl != null) return Image.network(_autoFetchedImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Text('Erro ao carregar imagem.')));
    return const Center(child: Text('Busque um link ou adicione uma imagem.'));
  }
}