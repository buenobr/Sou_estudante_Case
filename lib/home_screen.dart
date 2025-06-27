// 6. SEXTO PASSO: Substitua o conteúdo do seu arquivo lib/home_screen.dart:
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'login_screen.dart';
import 'add_promotion_screen.dart';
import 'promotion_detail_screen.dart';
import 'app_colors.dart'; // Importa nosso arquivo de cores

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _deletePromotion(BuildContext context, String docId, String? imageUrl) async {
    final bool? confirm = await showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Confirmar Exclusão'), content: const Text('Você tem certeza que deseja deletar esta promoção?'), actions: [ TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Deletar')) ]));
    if (confirm == true) {
      try {
        if (imageUrl != null && imageUrl.contains('firebasestorage.googleapis.com')) {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        }
        await FirebaseFirestore.instance.collection('promotions').doc(docId).delete();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao deletar promoção: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isRealUser = user != null && !user.isAnonymous;

    List<Widget> buildAppBarActions() {
      if (!isRealUser) {
        return [ TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())), child: const Text('Login / Cadastrar', style: TextStyle(color: Colors.white))) ];
      } else {
        return [ IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut()) ];
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Promoções'), actions: buildAppBarActions()),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('promotions').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('Ocorreu um erro ao carregar as promoções.'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Nenhuma promoção encontrada.'));

          final promotions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promo = promotions[index];
              final data = promo.data() as Map<String, dynamic>;
              
              final String title = data['title'] ?? 'Sem título';
              final double price = (data['price'] ?? 0.0).toDouble();
              final String? imageUrl = data['imageUrl'];
              final String category = data['category'] ?? 'Sem categoria';
              final String submittedBy = data['submittedBy'] ?? '';
              final bool isOwner = user?.uid == submittedBy;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                elevation: 2,
                child: ListTile(
                  leading: Container(width: 80, height: 80, color: Colors.grey[200], child: imageUrl != null ? Image.network(imageUrl, fit: BoxFit.contain, loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()), errorBuilder: (context, error, stackTrace) => const Icon(Icons.error)) : const Icon(Icons.shopping_bag, color: Colors.grey)),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ const SizedBox(height: 4), Text(category, style: const TextStyle(color: AppColors.primary, fontSize: 12)), const SizedBox(height: 4), Text('R\$ ${price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.price, fontWeight: FontWeight.bold)) ]),
                  trailing: isOwner ? PopupMenuButton<String>(onSelected: (value) { if (value == 'delete') { _deletePromotion(context, promo.id, imageUrl); } }, itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[ const PopupMenuItem<String>(value: 'delete', child: Text('Deletar')) ]) : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PromotionDetailScreen(promotionData: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isRealUser ? FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPromotionScreen())), child: const Icon(Icons.add)) : null,
    );
  }
}