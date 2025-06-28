// =================================================================================
// 5. NOVO ARQUIVO: lib/admin_approval_screen.dart
// =================================================================================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  Future<void> _updateStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance.collection('promotions').doc(docId).update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aprovar Promoções')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('promotions').where('status', isEqualTo: 'pending').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma promoção pendente.'));
          }
          final promotions = snapshot.data!.docs;
          return ListView.builder(
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final data = promotions[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: Text(data['category'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.check_circle, color: AppColors.price), onPressed: () => _updateStatus(promotions[index].id, 'approved')),
                      IconButton(icon: const Icon(Icons.cancel, color: AppColors.danger), onPressed: () => _updateStatus(promotions[index].id, 'deleted')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
