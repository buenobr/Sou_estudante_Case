// =================================================================================
// 5. ARQUIVO: lib/home_screen.dart (MUDANÇA CRÍTICA)
// =================================================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import 'login_screen.dart';
import 'add_promotion_screen.dart';
import 'promotion_detail_screen.dart';
import 'app_colors.dart';
import 'favorites_screen.dart';
import 'admin_trash_screen.dart';
import 'admin_approval_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final List<String> _filters = ['Destaques', 'Software', 'Cursos', 'Produtos', 'Viagens'];
  String _selectedFilter = 'Destaques';
  Stream<DocumentSnapshot>? _userDataStream;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Ouve as mudanças de autenticação para reconfigurar o stream de dados do usuário
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _setupUserDataStream(user);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupUserDataStream(User? user) {
    if (user != null && !user.isAnonymous) {
      setState(() {
        _userDataStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
      });
    } else {
      setState(() {
        _userDataStream = null;
      });
    }
  }

  Future<void> _moveToTrash(BuildContext context, String docId) async {
    final bool? confirm = await showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Mover para Lixeira'), content: const Text('Tem certeza? A promoção ficará oculta para os usuários.'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar'))]));
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('promotions').doc(docId).update({'status': 'deleted'});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao mover para lixeira: $e')));
      }
    }
  }

  void _sharePromotion(String title, String link) {
    Share.share('Olha essa promoção que eu encontrei: $title\n\n$link');
  }

  void _toggleFavorite(String promoId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faça login para favoritar promoções!')));
      return;
    }
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    userRef.get().then((doc) {
      if (!doc.exists) return; // Não faz nada se o documento do usuário não existir
      final favorites = List<String>.from(doc.data()?['favorites'] ?? []);
      if (favorites.contains(promoId)) {
        userRef.update({'favorites': FieldValue.arrayRemove([promoId])});
      } else {
        userRef.update({'favorites': FieldValue.arrayUnion([promoId])});
      }
    });
  }

  Widget _buildUserMenu(User? user, DocumentSnapshot? userData) {
    if (user == null || user.isAnonymous) {
      return TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())), child: const Text('Login / Cadastrar', style: TextStyle(color: Colors.white)));
    }
    
    final userRole = userData?['role'];

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'sair') FirebaseAuth.instance.signOut();
        if (value == 'favoritos') Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
        if (value == 'lixeira') Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminTrashScreen()));
        if (value == 'aprovar') Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminApprovalScreen()));
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'configuracoes', child: ListTile(leading: Icon(Icons.settings), title: Text('Configurações'))),
        const PopupMenuItem<String>(value: 'favoritos', child: ListTile(leading: Icon(Icons.favorite), title: Text('Favoritos'))),
        if (userRole == 'admin') const PopupMenuItem<String>(value: 'aprovar', child: ListTile(leading: Icon(Icons.playlist_add_check, color: AppColors.price), title: Text('Aprovar Promoções', style: TextStyle(color: AppColors.price)))),
        if (userRole == 'admin') const PopupMenuItem<String>(value: 'lixeira', child: ListTile(leading: Icon(Icons.delete_sweep, color: AppColors.danger), title: Text('Lixeira', style: TextStyle(color: AppColors.danger)))),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'sair', child: ListTile(leading: Icon(Icons.exit_to_app), title: Text('Sair'))),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          child: user.photoURL == null ? Text(user.email?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: AppColors.primary)) : null,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          return ChoiceChip(label: Text(filter), selected: _selectedFilter == filter, onSelected: (selected) { if (selected) setState(() => _selectedFilter = filter); }, selectedColor: AppColors.primary, labelStyle: TextStyle(color: _selectedFilter == filter ? Colors.white : Colors.black));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promoções'),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: _userDataStream,
            builder: (context, snapshot) {
              // Adicionamos uma verificação se o documento do usuário existe
              if (snapshot.hasData && !snapshot.data!.exists && user != null && !user.isAnonymous) {
                // Se o usuário está logado mas não tem doc, pode ser um loading ou erro.
                // Aqui, apenas mostramos o menu anônimo para evitar crash.
                return _buildUserMenu(null, null);
              }
              return _buildUserMenu(user, snapshot.data);
            }
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _userDataStream,
              builder: (context, userDataSnapshot) {
                // CORREÇÃO: Verifica se o documento do usuário existe antes de ler os dados
                final docExists = userDataSnapshot.hasData && userDataSnapshot.data!.exists;
                final userFavorites = docExists ? List<String>.from(userDataSnapshot.data!['favorites'] ?? []) : <String>[];
                final userRole = docExists ? userDataSnapshot.data!['role'] : null;

                return StreamBuilder<QuerySnapshot>(
                  stream: () {
                    Query query = FirebaseFirestore.instance.collection('promotions').where('status', isEqualTo: 'approved');
                    if (_selectedFilter != 'Destaques') {
                      query = query.where('category', isEqualTo: _selectedFilter);
                    }
                    return query.orderBy('createdAt', descending: true).snapshots();
                  }(),
                  builder: (context, promoSnapshot) {
                    if (promoSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (promoSnapshot.hasError) {
                      debugPrint("ERRO DO FIRESTORE: ${promoSnapshot.error}");
                      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Erro ao carregar promoções.', textAlign: TextAlign.center)));
                    }
                    if (!promoSnapshot.hasData || promoSnapshot.data!.docs.isEmpty) return const Center(child: Text('Nenhuma promoção encontrada.'));
                    final promotions = promoSnapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: promotions.length,
                      itemBuilder: (context, index) {
                        final promo = promotions[index];
                        final data = promo.data() as Map<String, dynamic>;
                        final String title = data['title'] ?? '';
                        final String link = data['link'] ?? '';
                        final double price = (data['price'] ?? 0.0).toDouble();
                        final String? imageUrl = data['imageUrl'];
                        final String category = data['category'] ?? '';
                        final bool isFavorited = userFavorites.contains(promo.id);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: Container(width: 80, height: 80, color: Colors.grey[200], child: imageUrl != null ? Image.network(imageUrl, fit: BoxFit.contain, loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()), errorBuilder: (context, error, stackTrace) => const Icon(Icons.error)) : const Icon(Icons.shopping_bag, color: Colors.grey)),
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 4), Text(category, style: const TextStyle(color: AppColors.primary, fontSize: 12)), const SizedBox(height: 4), Text('R\$ ${price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.price, fontWeight: FontWeight.bold))]),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.share, color: Colors.grey), onPressed: () => _sharePromotion(title, link)),
                                  IconButton(icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border, color: isFavorited ? AppColors.danger : Colors.grey), onPressed: () => _toggleFavorite(promo.id)),
                                  if (userRole == 'admin') IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => _moveToTrash(context, promo.id)),
                                ],
                              ),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PromotionDetailScreen(promotionData: data))),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
      floatingActionButton: user != null && !user.isAnonymous ? FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPromotionScreen())), child: const Icon(Icons.add)) : null,
    );
  }
}