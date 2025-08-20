import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';
import 'app_colors.dart';

class AdminTrashScreen extends StatefulWidget {
  const AdminTrashScreen({super.key});

  @override
  State<AdminTrashScreen> createState() => _AdminTrashScreenState();
}

class _AdminTrashScreenState extends State<AdminTrashScreen> {
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
          ad.dispose();
        },
      ),
    )..load();
  }

  Future<void> _restorePromotion(String docId) async {
    await FirebaseFirestore.instance.collection('promotions').doc(docId).update({'status': 'pending'});
  }

  Future<void> _deletePermanently(BuildContext context, String docId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Permanentemente'),
        content: const Text('Esta ação não pode ser desfeita. Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('promotions').doc(docId).delete();
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lixeira')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('promotions').where('status', isEqualTo: 'deleted').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('A lixeira está vazia.'));
                
                final promotions = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: promotions.length,
                  itemBuilder: (context, index) {
                    final promo = promotions[index];
                    final data = promo.data() as Map<String, dynamic>;
                    return Card(
                      key: ValueKey(promo.id),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.restore, color: AppColors.price), onPressed: () => _restorePromotion(promo.id)),
                            IconButton(icon: const Icon(Icons.delete_forever, color: AppColors.danger), onPressed: () => _deletePermanently(context, promo.id)),
                          ],
                        ),
                      ),
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
