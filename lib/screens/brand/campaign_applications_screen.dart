import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../shared/chat_screen.dart';

class CampaignApplicationsScreen extends StatelessWidget {
  final String campaignId;
  final String campaignTitle;
  final DatabaseService _dbService = DatabaseService();

  CampaignApplicationsScreen({
    required this.campaignId,
    required this.campaignTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundalul general Baby Blue se preia automat din main.dart
      appBar: AppBar(
        title: Text('Aplicații: $campaignTitle'),
        backgroundColor: const Color(
          0xFFD2E6FF,
        ), // 🔴 NOU: Asortat cu Baby Blue global
        foregroundColor: const Color(0xFF0F172A), // Text titlu albastru închis
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getApplicationsForCampaign(campaignId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
              ),
            );
          }
          var apps = snapshot.data!.docs;

          if (apps.isEmpty) {
            return const Center(
              child: Text(
                'Nu există aplicații depuse încă.',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: apps.length,
            itemBuilder: (context, i) {
              var appData = apps[i].data() as Map<String, dynamic>;
              String appId = apps[i].id;
              String creatorId = appData['creatorId'] ?? '';
              String status = appData['status'] ?? 'pending';
              String chatId = "${campaignId}_$creatorId";

              return FutureBuilder<DocumentSnapshot>(
                future: _dbService.getCreatorProfile(creatorId),
                builder: (context, creatorSnapshot) {
                  String creatorName = "Se încarcă...";
                  if (creatorSnapshot.hasData && creatorSnapshot.data!.exists) {
                    var cData =
                        creatorSnapshot.data!.data() as Map<String, dynamic>;
                    creatorName = cData['name'] ?? 'Creator Anonim';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ), // Margini rotunjite la 24px
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                creatorName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black, // Scris negru curat
                                ),
                              ),
                              _buildStatusBadge(
                                status,
                              ), // 🔴 NOU: Ecuson stilizat în loc de text brut
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mesaj: "${appData['message'] ?? 'Fără mesaj atașat.'}"',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(color: Colors.black12),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // 🔴 REPROIECTAT: Monitorizare chat în timp real cu culori asortate temei noi
                              StreamBuilder<DocumentSnapshot>(
                                stream: _dbService.getChatDocument(chatId),
                                builder: (context, chatSnapshot) {
                                  bool hasUnread = false;
                                  if (chatSnapshot.hasData &&
                                      chatSnapshot.data!.exists) {
                                    var chatData =
                                        chatSnapshot.data!.data()
                                            as Map<String, dynamic>;
                                    hasUnread =
                                        chatData['unreadByBrand'] ?? false;
                                  }

                                  return ElevatedButton.icon(
                                    icon: Icon(
                                      hasUnread
                                          ? Icons.mark_chat_unread
                                          : Icons.chat_bubble_outline,
                                      size: 20,
                                    ),
                                    label: Text(
                                      hasUnread ? 'Mesaj nou! 🔴' : 'Chat',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasUnread
                                          ? Colors.red
                                          : const Color(
                                              0xFFE3F0FF,
                                            ), // Soft Ice Blue dacă e citit
                                      foregroundColor: hasUnread
                                          ? Colors.white
                                          : const Color(
                                              0xFF0F172A,
                                            ), // Text Deep Navy
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            chatId: chatId,
                                            recipientName: creatorName,
                                            senderRole: "Brand",
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const Spacer(),
                              if (status == 'pending') ...[
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () =>
                                      _dbService.updateApplicationStatus(
                                        appId,
                                        'accepted',
                                      ),
                                  child: const Text(
                                    'Acceptă',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () =>
                                      _dbService.updateApplicationStatus(
                                        appId,
                                        'rejected',
                                      ),
                                  child: const Text(
                                    'Respinge',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // 🔴 METODĂ NOUĂ: Creează o capsulă vizuală curată pentru statusul aplicației
  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    String text = 'În așteptare';
    if (status == 'accepted') {
      color = Colors.green;
      text = 'Acceptat 🎉';
    }
    if (status == 'rejected') {
      color = Colors.red;
      text = 'Respins ❌';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
