// =================================================================================
// 6. NOVO ARQUIVO: lib/admin_trash_screen.dart
// =================================================================================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';

class AdminTrashScreen extends StatelessWidget {
  const AdminTrashScreen({super.key});

  Future<void> _restorePromotion(String docId) async {
    await FirebaseFirestore.instance.collection('promotions').doc(docId).update({'status': 'pending'});
  }

  Future<void> _deletePermanently(String docId) async {
    await FirebaseFirestore.instance.collection('promotions').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lixeira')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('promotions').where('status', isEqualTo: 'deleted').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('A lixeira está vazia.'));
          }
          final promotions = snapshot.data!.docs;
          return ListView.builder(
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final data = promotions[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.restore, color: AppColors.price), onPressed: () => _restorePromotion(promotions[index].id)),
                    IconButton(icon: const Icon(Icons.delete_forever, color: AppColors.danger), onPressed: () => _deletePermanently(promotions[index].id)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}