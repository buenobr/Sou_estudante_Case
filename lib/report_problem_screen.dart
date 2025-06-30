// =================================================================================
// NOVO ARQUIVO: lib/report_problem_screen.dart
// =================================================================================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_colors.dart';

class ReportProblemScreen extends StatefulWidget {
  final String promotionId;
  final String promotionTitle;
  final String promotionLink;

  const ReportProblemScreen({
    super.key,
    required this.promotionId,
    required this.promotionTitle,
    required this.promotionLink,
  });

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final TextEditingController _problemDescriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para reportar um problema!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'promotionId': widget.promotionId,
        'promotionTitle': widget.promotionTitle,
        'promotionLink': widget.promotionLink,
        'reportedByUserId': user.uid,
        'reportedByUserEmail': user.email,
        'problemDescription': _problemDescriptionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // Pode ser 'pending', 'resolved', 'ignored'
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Problema reportado com sucesso!')),
        );
        Navigator.of(context).pop(); // Volta para a tela anterior
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reportar problema: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Problema'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Detalhes da Promoção:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Título: ${widget.promotionTitle}'),
              Text('ID: ${widget.promotionId}'),
              Text('Link: ${widget.promotionLink}'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _problemDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descreva o problema',
                  hintText: 'Por favor, seja o mais detalhado possível.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'A descrição do problema é obrigatória.';
                  }
                  if (value.trim().length < 20) {
                    return 'Por favor, forneça mais detalhes (mínimo 20 caracteres).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitReport,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar Reporte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}