// =================================================================================
// 4. ARQUIVO: lib/favorites_screen.dart (VERSÃO FINAL)
// =================================================================================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'promotion_detail_screen.dart';
import 'ad_helper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  Future<List<String>> _getFavoriteIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return [];
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()!.containsKey('favorites')) {
      final List<dynamic> rawFavorites = doc.data()!['favorites'];
      return rawFavorites.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
    }
    return [];
  }

  Future<List<DocumentSnapshot>> _getFavoritePromotionsInBatches(List<String> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    final List<DocumentSnapshot> promotions = [];
    const batchSize = 10;
    for (var i = 0; i < ids.length; i += batchSize) {
      final batchIds = ids.sublist(i, i + batchSize > ids.length ? ids.length : i + batchSize);
      if (batchIds.isNotEmpty) {
        final querySnapshot = await FirebaseFirestore.instance.collection('promotions').where(FieldPath.documentId, whereIn: batchIds).get();
        promotions.addAll(querySnapshot.docs);
      }
    }
    return promotions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Favoritos')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _getFavoriteIds(),
              builder: (context, idSnapshot) {
                if (idSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (idSnapshot.hasError) return const Center(child: Text('Erro ao carregar IDs dos favoritos.'));
                if (!idSnapshot.hasData || idSnapshot.data!.isEmpty) return const Center(child: Text('Você ainda não favoritou nenhuma promoção.'));
                
                final favoriteIds = idSnapshot.data!;

                return FutureBuilder<List<DocumentSnapshot>>(
                  future: _getFavoritePromotionsInBatches(favoriteIds),
                  builder: (context, promoSnapshot) {
                    if (promoSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (promoSnapshot.hasError) {
                      debugPrint("ERRO AO BUSCAR PROMOÇÕES FAVORITAS: ${promoSnapshot.error}");
                      return const Center(child: Text('Erro ao carregar as promoções favoritas.'));
                    }
                    if (!promoSnapshot.hasData || promoSnapshot.data!.isEmpty) return const Center(child: Text('Nenhuma promoção favorita encontrada.'));

                    final promotions = promoSnapshot.data!;
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: promotions.length,
                      itemBuilder: (context, index) {
                        final data = promotions[index].data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'Sem Título';
                        final category = data['category'] ?? 'Sem Categoria';
                        final price = (data['price'] ?? 0.0).toDouble();
                        final imageUrl = data['imageUrl'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: ListTile(
                            leading: Container(width: 80, height: 80, color: Colors.grey[200], child: imageUrl != null ? Image.network(imageUrl, fit: BoxFit.contain) : const Icon(Icons.shopping_bag)),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('$category - R\$ ${price.toStringAsFixed(2)}'),
                            // LINHA ALTERADA: Passando 'promotionId'
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PromotionDetailScreen(promotionData: data, promotionId: promotions[index].id))),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
        ],
      ),
    );
  }
}