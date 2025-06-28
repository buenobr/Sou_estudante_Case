// =================================================================================
// 5. NOVO ARQUIVO: lib/favorites_screen.dart
// =================================================================================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'promotion_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Future<List<String>> _getFavoriteIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()!['favorites'] != null) {
      return List<String>.from(doc.data()!['favorites']);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Favoritos')),
      body: FutureBuilder<List<String>>(
        future: _getFavoriteIds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Você ainda não favoritou nenhuma promoção.'));
          }

          final favoriteIds = snapshot.data!;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('promotions').where(FieldPath.documentId, whereIn: favoriteIds).snapshots(),
            builder: (context, promoSnapshot) {
              if (promoSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!promoSnapshot.hasData || promoSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Nenhuma promoção encontrada.'));
              }
              final promotions = promoSnapshot.data!.docs;
              return ListView.builder(
                itemCount: promotions.length,
                itemBuilder: (context, index) {
                  final data = promotions[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['title'] ?? ''),
                    subtitle: Text(data['category'] ?? ''),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PromotionDetailScreen(promotionData: data))),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}