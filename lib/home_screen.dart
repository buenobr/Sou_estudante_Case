// =================================================================================
// ARQUIVO: lib/home_screen.dart (CORRIGIDO PARA MANTER A POSIÇÃO DA ROLAGEM)
// =================================================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';

import 'login_screen.dart';
import 'add_promotion_screen.dart';
import 'promotion_detail_screen.dart';
import 'app_colors.dart';
import 'favorites_screen.dart';
import 'admin_trash_screen.dart';
import 'admin_approval_screen.dart';
import 'settings_screen.dart';
import 'ad_helper.dart';
import 'admin_user_management_screen.dart';
import 'admin_reports_screen.dart';

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
  
  final List<BannerAd?> _bannerAds = [];
  final int _adInterval = 3;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _setupUserDataStream(user);
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    for (var ad in _bannerAds) {
      ad?.dispose();
    }
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text.trim()) {
        setState(() {
          _searchQuery = _searchController.text.trim();
        });
      }
    });
  }

  void _loadBannerAd(int adIndex) {
    if (adIndex >= _bannerAds.length || _bannerAds[adIndex] == null) {
      if (_bannerAds.length <= adIndex) {
        setState(() {
          _bannerAds.addAll(List.filled(adIndex - _bannerAds.length + 1, null));
        });
      }

      final banner = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _bannerAds[adIndex] = ad as BannerAd;
              });
            }
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('BannerAd failed to load: $err');
            ad.dispose();
          },
        ),
      );
      banner.load();
    }
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
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao mover para lixeira: $e')));
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
      if (!doc.exists) return;
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
        if (value == 'configuracoes') Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
        if (value == 'gerenciar_usuarios') Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUserManagementScreen()));
        if (value == 'gerenciar_reportes') Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminReportsScreen()));
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'configuracoes', child: ListTile(leading: Icon(Icons.settings), title: Text('Configurações'))),
        const PopupMenuItem<String>(value: 'favoritos', child: ListTile(leading: Icon(Icons.favorite), title: Text('Favoritos'))),
        if (userRole == 'admin') const PopupMenuDivider(),
        if (userRole == 'admin') const PopupMenuItem<String>(value: 'aprovar', child: ListTile(leading: Icon(Icons.playlist_add_check, color: AppColors.price), title: Text('Aprovar Promoções', style: TextStyle(color: AppColors.price)))),
        if (userRole == 'admin') const PopupMenuItem<String>(value: 'gerenciar_usuarios', child: ListTile(leading: Icon(Icons.people, color: AppColors.primary), title: Text('Gerenciar Usuários', style: TextStyle(color: AppColors.primary)))),
        if (userRole == 'admin') const PopupMenuItem<String>(value: 'lixeira', child: ListTile(leading: Icon(Icons.delete_sweep, color: AppColors.danger), title: Text('Lixeira', style: TextStyle(color: AppColors.danger)))),
        if (userRole == 'admin') const PopupMenuItem<String>(value: 'gerenciar_reportes', child: ListTile(leading: Icon(Icons.report, color: Colors.amber), title: Text('Gerenciar Reportes', style: TextStyle(color: Colors.amber)))),
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
    final Brightness brightness = Theme.of(context).brightness;

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
          return ChoiceChip(
            label: Text(filter),
            selected: _selectedFilter == filter,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedFilter = filter);
              }
            },
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: _selectedFilter == filter
                  ? Colors.white
                  : (brightness == Brightness.dark ? Colors.white : Colors.black),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar promoções...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _isSearching = false;
                      });
                    },
                  ),
                ),
                autofocus: true,
              )
            : const Text('Sou Estudante'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          StreamBuilder<DocumentSnapshot>(
            stream: _userDataStream,
            builder: (context, snapshot) {
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
                final docData = userDataSnapshot.data?.data() as Map<String, dynamic>?;
                final userFavorites = (docData?['favorites'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                final userRole = docData?['role'];

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
                    
                    var promotions = promoSnapshot.data!.docs;
                    if (_searchQuery.isNotEmpty) {
                      promotions = promotions.where((promo) {
                        final data = promo.data() as Map<String, dynamic>;
                        final title = (data['title'] ?? '').toString().toLowerCase();
                        final description = (data['description'] ?? '').toString().toLowerCase();
                        final category = (data['category'] ?? '').toString().toLowerCase();
                        final query = _searchQuery.toLowerCase();
                        return title.contains(query) || description.contains(query) || category.contains(query);
                      }).toList();
                    }

                    if (promotions.isEmpty && _searchQuery.isNotEmpty) {
                      return const Center(child: Text('Nenhuma promoção encontrada para sua busca.'));
                    } else if (promotions.isEmpty) {
                      return const Center(child: Text('Nenhuma promoção encontrada.'));
                    }
                    
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final int adCount = promotions.length ~/ _adInterval;
                      if (_bannerAds.length < adCount) {
                        for (int i = _bannerAds.length; i < adCount; i++) {
                          _loadBannerAd(i);
                        }
                      }
                    });
                    
                    final int adCount = promotions.length ~/ _adInterval;

                    return ListView.builder(
                      key: const PageStorageKey<String>('promotionsList'),
                      padding: const EdgeInsets.all(8.0),
                      itemCount: promotions.length + adCount,
                      itemBuilder: (context, index) {
                        if (_adInterval > 0 && (index + 1) % (_adInterval + 1) == 0) {
                          final adIndex = (index + 1) ~/ (_adInterval + 1) - 1;
                          if (adIndex < _bannerAds.length) {
                            final ad = _bannerAds[adIndex];
                            if (ad != null) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                height: ad.size.height.toDouble(),
                                child: AdWidget(ad: ad),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        }

                        final promoIndex = index - (index ~/ (_adInterval + 1));
                        final promo = promotions[promoIndex];
                        final data = promo.data() as Map<String, dynamic>;
                        final String title = data['title'] ?? '';
                        final String link = data['link'] ?? '';
                        final double priceValue = (data['priceValue'] ?? 0.0).toDouble();
                        final String priceType = data['priceType'] ?? 'monetario';
                        final String? imageUrl = data['imageUrl'];
                        final String category = data['category'] ?? '';
                        final bool isFavorited = userFavorites.contains(promo.id);
                        final int likesCount = (data['likedBy'] as List<dynamic>?)?.length ?? 0;

                        String formattedPriceText = '';
                        if (priceValue == 0.0) {
                          formattedPriceText = 'Grátis';
                        } else if (priceType == 'monetario') {
                          formattedPriceText = 'R\$ ${priceValue.toStringAsFixed(2)}';
                        } else {
                          formattedPriceText = '${priceValue.toInt()}% de desconto';
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              horizontalTitleGap: 8.0,
                              leading: Container(width: 80, height: 80, color: Colors.grey[200], child: imageUrl != null ? Image.network(imageUrl, fit: BoxFit.contain, loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()), errorBuilder: (context, error, stackTrace) => const Icon(Icons.error)) : const Icon(Icons.shopping_bag, color: Colors.grey)),
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(category, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(formattedPriceText, style: const TextStyle(color: AppColors.price, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('$likesCount', style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.share, color: Colors.grey), onPressed: () => _sharePromotion(title, link), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                  IconButton(icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border, color: isFavorited ? AppColors.danger : Colors.grey), onPressed: () => _toggleFavorite(promo.id), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                  if (userRole == 'admin') IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => _moveToTrash(context, promo.id), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                ],
                              ),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PromotionDetailScreen(promotionData: data, promotionId: promo.id))),
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