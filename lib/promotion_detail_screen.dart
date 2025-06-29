// =================================================================================
// 4. ARQUIVO: lib/promotion_detail_screen.dart (CORRIGIDO)
// =================================================================================
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';

class PromotionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> promotionData;
  const PromotionDetailScreen({super.key, required this.promotionData});

  // CORREÇÃO: Função mais robusta para abrir links
  Future<void> _launchURL(BuildContext context, String urlString) async {
    if (urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum link disponível para esta promoção.')),
      );
      return;
    }

    // Adiciona http:// se não tiver um esquema, para garantir que seja uma URL válida
    if (!urlString.toLowerCase().startsWith('http://') && !urlString.toLowerCase().startsWith('https://')) {
      urlString = 'https://$urlString';
    }

    final Uri? url = Uri.tryParse(urlString);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = promotionData['title'] ?? 'Sem título';
    final double price = (promotionData['price'] ?? 0.0).toDouble();
    final String? imageUrl = promotionData['imageUrl'];
    final String category = promotionData['category'] ?? 'Sem categoria';
    final String link = promotionData['link'] ?? '';
    final String description = promotionData['description'] ?? 'Sem descrição.';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    color: Colors.grey[200],
                    width: double.infinity,
                    height: 250,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error, color: Colors.grey, size: 50)),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('R\$ ${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, color: AppColors.price, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  if (link.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.link),
                        label: const Text('Abrir Link'),
                        // CORREÇÃO: Passando o context para a função
                        onPressed: () => _launchURL(context, link),
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (description.isNotEmpty) ...[
                    const Text('Descrição', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}