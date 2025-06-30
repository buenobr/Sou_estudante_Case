// =================================================================================
// NOVO ARQUIVO: lib/admin_reports_screen.dart (CORRIGIDO Overflow)
// =================================================================================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateReportStatus(String reportId, String newStatus) async {
    await _firestore.collection('reports').doc(reportId).update({'status': newStatus});
  }

  Future<void> _deleteReport(String reportId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Reporte'),
        content: const Text('Tem certeza que deseja excluir este reporte permanentemente?'),
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
        await _firestore.collection('reports').doc(reportId).delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir reporte: $e')),
          );
        }
      }
    }
  }

  // Função para abrir links (reutilizada)
  Future<void> _launchURL(BuildContext context, String urlString) async {
    if (urlString.isEmpty) return;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Reportes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('reports').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar reportes: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum problema reportado.'));
          }

          final reports = snapshot.data!.docs;
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final reportDoc = reports[index];
              final data = reportDoc.data() as Map<String, dynamic>;

              final String promotionTitle = data['promotionTitle'] ?? 'Título Desconhecido';
              final String problemDescription = data['problemDescription'] ?? 'Sem descrição';
              final String reportedByUserEmail = data['reportedByUserEmail'] ?? 'Usuário Desconhecido';
              final String promotionLink = data['promotionLink'] ?? '';
              final String status = data['status'] ?? 'pending';
              final Timestamp? timestamp = data['timestamp'] as Timestamp?;

              String formattedTime = '';
              if (timestamp != null) {
                final dateTime = timestamp.toDate();
                formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
              }

              Color statusColor;
              IconData statusIcon;
              switch (status) {
                case 'resolved':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case 'ignored':
                  statusColor = Colors.grey;
                  statusIcon = Icons.info;
                  break;
                default: // pending
                  statusColor = Colors.orange;
                  statusIcon = Icons.warning;
                  break;
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  leading: Icon(statusIcon, color: statusColor),
                  title: Text('Problema na Promoção: $promotionTitle'),
                  subtitle: Text('Reportado por: $reportedByUserEmail em $formattedTime - Status: $status'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Descrição do Problema:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(problemDescription),
                          const SizedBox(height: 8),
                          if (promotionLink.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.link),
                              label: Text('Ver Link da Promoção'),
                              onPressed: () => _launchURL(context, promotionLink),
                            ),
                          const SizedBox(height: 16),
                          // CORREÇÃO AQUI: Usando Expanded para os botões dentro da Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded( // Botão "Marcar como Resolvido"
                                child: ElevatedButton.icon(
                                  onPressed: status != 'resolved' ? () => _updateReportStatus(reportDoc.id, 'resolved') : null,
                                  icon: const Icon(Icons.check),
                                  label: const Text('Resolvido'), // Texto mais curto
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8), // Espaçamento entre os botões
                              Expanded( // Botão "Ignorar"
                                child: ElevatedButton.icon(
                                  onPressed: status != 'ignored' ? () => _updateReportStatus(reportDoc.id, 'ignored') : null,
                                  icon: const Icon(Icons.visibility_off),
                                  label: const Text('Ignorar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8), // Espaçamento entre os botões
                              // O IconButton geralmente não precisa de Expanded se os outros estiverem,
                              // mas pode ser colocado dentro de um Flexible se ainda houver problemas de espaço.
                              IconButton(
                                onPressed: () => _deleteReport(reportDoc.id),
                                icon: const Icon(Icons.delete_forever, color: AppColors.danger),
                                tooltip: 'Excluir Permanentemente',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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