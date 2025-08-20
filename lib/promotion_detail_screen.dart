import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'app_colors.dart';
import 'report_problem_screen.dart';

class PromotionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> promotionData;
  final String promotionId;
  const PromotionDetailScreen({super.key, required this.promotionData, required this.promotionId});

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _likes = 0;
  int _dislikes = 0;
  bool _isLiked = false;
  bool _isDisliked = false;

  @override
  void initState() {
    super.initState();
    _loadReactionStatus();
  }

  Future<void> _loadReactionStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final promoRef = _firestore.collection('promotions').doc(widget.promotionId);
    final promoDoc = await promoRef.get();

    if (promoDoc.exists) {
      final data = promoDoc.data();
      final List<String> likedBy = List<String>.from(data?['likedBy'] ?? []);
      final List<String> dislikedBy = List<String>.from(data?['dislikedBy'] ?? []);

      setState(() {
        _likes = likedBy.length;
        _dislikes = dislikedBy.length;
        _isLiked = likedBy.contains(user.uid);
        _isDisliked = dislikedBy.contains(user.uid);
      });
    }
  }

  Future<void> _toggleReaction(bool isLike) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para reagir!')),
      );
      return;
    }

    final promoRef = _firestore.collection('promotions').doc(widget.promotionId);

    _firestore.runTransaction((transaction) async {
      final freshPromoDoc = await transaction.get(promoRef);
      if (!freshPromoDoc.exists) return;

      List<String> currentLikedBy = List<String>.from(freshPromoDoc.data()?['likedBy'] ?? []);
      List<String> currentDislikedBy = List<String>.from(freshPromoDoc.data()?['dislikedBy'] ?? []);

      if (isLike) {
        if (currentLikedBy.contains(user.uid)) {
          currentLikedBy.remove(user.uid);
          _isLiked = false;
        } else {
          currentLikedBy.add(user.uid);
          _isLiked = true;
          if (currentDislikedBy.contains(user.uid)) {
            currentDislikedBy.remove(user.uid);
            _isDisliked = false;
          }
        }
      } else {
        if (currentDislikedBy.contains(user.uid)) {
          currentDislikedBy.remove(user.uid);
          _isDisliked = false;
        } else {
          currentDislikedBy.add(user.uid);
          _isDisliked = true;
          if (currentLikedBy.contains(user.uid)) {
            currentLikedBy.remove(user.uid);
            _isLiked = false;
          }
        }
      }

      transaction.update(promoRef, {
        'likedBy': currentLikedBy,
        'dislikedBy': currentDislikedBy,
      });

      if (mounted) {
        setState(() {
          _likes = currentLikedBy.length;
          _dislikes = currentDislikedBy.length;
        });
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar reação: $error')),
        );
      }
    });
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    if (urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum link disponível para esta promoção.')),
      );
      return;
    }

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

  Future<void> _addComment() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para comentar!')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O comentário não pode ser vazio.')),
      );
      return;
    }

    try {
      final String authorName = user.displayName ?? user.email?.split('@')[0] ?? 'Usuário Anônimo';
      final String authorEmail = user.email ?? 'email@anonimo.com';

      await _firestore
          .collection('promotions')
          .doc(widget.promotionId)
          .collection('comments')
          .add({
        'text': _commentController.text.trim(),
        'authorId': user.uid,
        'authorName': authorName,
        'authorEmail': authorEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar comentário: $e')),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId, String authorId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isAdmin = await _checkIfUserIsAdmin(user.uid);

    if (user.uid == authorId || isAdmin) {
      final bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir Comentário'),
          content: const Text('Tem certeza que deseja excluir este comentário?'),
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
          await _firestore
              .collection('promotions')
              .doc(widget.promotionId)
              .collection('comments')
              .doc(commentId)
              .delete();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao excluir comentário: $e')),
            );
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você não tem permissão para excluir este comentário.')),
        );
      }
    }
  }

  Future<bool> _checkIfUserIsAdmin(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists && doc.data()?['role'] == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.promotionData['title'] ?? 'Sem título';
    final double priceValue = (widget.promotionData['priceValue'] ?? 0.0).toDouble();
    final String priceType = widget.promotionData['priceType'] ?? 'monetario';
    final String? imageUrl = widget.promotionData['imageUrl'];
    final String category = widget.promotionData['category'] ?? 'Sem categoria';
    final String link = widget.promotionData['link'] ?? '';
    final String description = widget.promotionData['description'] ?? 'Sem descrição.';

    final user = _auth.currentUser;
    final bool canCommentAndReact = user != null && !user.isAnonymous;

    String formattedPriceText = '';
    if (priceValue == 0.0) {
      formattedPriceText = 'Grátis';
    } else if (priceType == 'monetario') {
      formattedPriceText = 'R\$ ${priceValue.toStringAsFixed(2)}';
    } else {
      formattedPriceText = '${priceValue.toInt()}% de desconto';
    }

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
                  Text(formattedPriceText, style: const TextStyle(fontSize: 22, color: AppColors.price, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  if (link.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.link),
                        label: const Text('Abrir Link'),
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
                  if (canCommentAndReact)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                                color: _isLiked ? AppColors.primary : Colors.grey,
                              ),
                              onPressed: () => _toggleReaction(true),
                            ),
                            Text('$_likes'),
                          ],
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isDisliked ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                                color: _isDisliked ? AppColors.danger : Colors.grey,
                              ),
                              onPressed: () => _toggleReaction(false),
                            ),
                            Text('$_dislikes'),
                          ],
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.report_problem_outlined, color: Colors.amber),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportProblemScreen(
                                      promotionId: widget.promotionId,
                                      promotionTitle: title,
                                      promotionLink: link,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Text('Reportar'),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  if (description.isNotEmpty) ...[
                    const Text('Descrição', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
                  ],
                  const SizedBox(height: 32),
                  const Text('Comentários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (canCommentAndReact)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: 'Adicionar um comentário...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addComment,
                            child: const Text('Comentar'),
                          ),
                        ],
                      ),
                    ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('promotions')
                        .doc(widget.promotionId)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro ao carregar comentários: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Seja o primeiro a comentar!'),
                        );
                      }

                      final comments = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final commentDoc = comments[index];
                          final commentData = commentDoc.data() as Map<String, dynamic>;
                          final String commentText = commentData['text'] ?? 'Comentário vazio';
                          final String authorName = commentData['authorName'] ?? 'Anônimo';
                          final String authorId = commentData['authorId'] ?? '';
                          final Timestamp? timestamp = commentData['timestamp'] as Timestamp?;
                          
                          String formattedTime = '';
                          if (timestamp != null) {
                            final dateTime = timestamp.toDate();
                            formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
                          }

                          return FutureBuilder<bool>(
                            future: _checkIfUserIsAdmin(user?.uid ?? ''),
                            builder: (context, adminSnapshot) {
                              final bool currentUserIsAdmin = adminSnapshot.data ?? false;
                              final bool canDelete = user != null && (user.uid == authorId || currentUserIsAdmin);

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                child: ListTile(
                                  title: Text(commentText),
                                  subtitle: Text('Por $authorName em $formattedTime'),
                                  trailing: canDelete
                                      ? IconButton(
                                          icon: const Icon(Icons.delete_forever, color: AppColors.danger),
                                          onPressed: () => _deleteComment(commentDoc.id, authorId),
                                        )
                                      : null,
                                ),
                              );
                            }
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}