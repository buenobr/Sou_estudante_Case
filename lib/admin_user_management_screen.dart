// =================================================================================
// 2. NOVO ARQUIVO: lib/admin_user_management_screen.dart
// =================================================================================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Função para promover um usuário a admin
  Future<void> _promoteUser(String uid) async {
    final confirm = await _showConfirmationDialog(
      title: 'Promover Usuário',
      content: 'Tem certeza que deseja promover este usuário a administrador?',
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'admin'});
    }
  }

  // Função para rebaixar um admin a usuário
  Future<void> _demoteUser(String uid) async {
    final confirm = await _showConfirmationDialog(
      title: 'Rebaixar Admin',
      content: 'Tem certeza que deseja rebaixar este administrador a usuário comum?',
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'user'});
    }
  }

  // Função para deletar um usuário
  Future<void> _deleteUser(String uid) async {
    final confirm = await _showConfirmationDialog(
      title: 'Excluir Usuário',
      content: 'Atenção! Esta ação é irreversível e irá deletar os dados do usuário do banco de dados. A conta no Firebase Authentication precisará ser removida manualmente ou via Cloud Functions.',
      confirmText: 'Excluir',
      isDestructive: true,
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    }
  }

  // Dialog de confirmação genérico
  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    String confirmText = 'Confirmar',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmText,
              style: TextStyle(color: isDestructive ? AppColors.danger : AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por e-mail',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum usuário encontrado.'));
                }

                var users = snapshot.data!.docs;
                if (_searchQuery.isNotEmpty) {
                  users = users.where((doc) {
                    final email = (doc.data() as Map<String, dynamic>)['email']?.toString().toLowerCase() ?? '';
                    return email.contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final String email = userData['email'] ?? 'E-mail não encontrado';
                    final String role = userData['role'] ?? 'user';
                    final String uid = userDoc.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(email),
                        subtitle: Text('Cargo: $role', style: TextStyle(color: role == 'admin' ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'promote') _promoteUser(uid);
                            if (value == 'demote') _demoteUser(uid);
                            if (value == 'delete') _deleteUser(uid);
                          },
                          itemBuilder: (context) => [
                            if (role == 'user')
                              const PopupMenuItem(
                                value: 'promote',
                                child: Text('Promover a Admin'),
                              ),
                            if (role == 'admin')
                              const PopupMenuItem(
                                value: 'demote',
                                child: Text('Rebaixar a Usuário'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Excluir Usuário', style: TextStyle(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}