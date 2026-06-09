import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../shared/chat_screen.dart';

class BrandApplicationsTab extends StatelessWidget {
  final DatabaseService _dbService = DatabaseService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getBrandCampaigns(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          var campaigns = snapshot.data!.docs;

          if (campaigns.isEmpty) {
            return const Center(
              child: Text('Nu aveți nicio campanie creată încă.'),
            );
          }

          return ListView.builder(
            itemCount: campaigns.length,
            itemBuilder: (context, i) {
              var campData = campaigns[i].data() as Map<String, dynamic>;
              String campaignId = campaigns[i].id;

              return StreamBuilder<QuerySnapshot>(
                stream: _dbService.getApplicationsForCampaign(campaignId),
                builder: (context, appSnapshot) {
                  if (!appSnapshot.hasData) return Container();
                  var apps = appSnapshot.data!.docs;
                  int totalApps = apps.length;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ExpansionTile(
                      title: Text(
                        campData['title'] ?? 'Campanie',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Produs vizat: ${campData['productCategory'] ?? 'General'}',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: totalApps > 0
                              ? Colors.purple[900]
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalApps înscrieri',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      children: apps.isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Nu a aplicat niciun creator la această campanie.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ]
                          : apps.map((appDoc) {
                              var appData =
                                  appDoc.data() as Map<String, dynamic>;
                              String appId = appDoc.id;
                              String creatorId = appData['creatorId'] ?? '';
                              String status = appData['status'] ?? 'pending';
                              String chatId =
                                  "${campaignId}_$creatorId"; // ID-ul unic de chat

                              return FutureBuilder<DocumentSnapshot>(
                                future: _dbService.getCreatorProfile(creatorId),
                                builder: (context, creatorSnapshot) {
                                  String creatorName = "Se încarcă...";
                                  if (creatorSnapshot.hasData &&
                                      creatorSnapshot.data!.exists) {
                                    var cData =
                                        creatorSnapshot.data!.data()
                                            as Map<String, dynamic>;
                                    creatorName =
                                        cData['name'] ?? 'Creator Anonim';
                                  }

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[900]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              creatorName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            _buildStatusBadge(status),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            // 🔴 NOU: StreamBuilder care verifică dacă există mesaje necitite de la Creator
                                            StreamBuilder<DocumentSnapshot>(
                                              stream: _dbService
                                                  .getChatDocument(chatId),
                                              builder: (context, chatSnapshot) {
                                                bool hasUnread = false;
                                                if (chatSnapshot.hasData &&
                                                    chatSnapshot.data!.exists) {
                                                  var chatData =
                                                      chatSnapshot.data!.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  hasUnread =
                                                      chatData['unreadByBrand'] ??
                                                      false;
                                                }

                                                return Stack(
                                                  alignment: Alignment.topRight,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        hasUnread
                                                            ? Icons
                                                                  .mark_chat_unread
                                                            : Icons
                                                                  .chat_bubble_outline,
                                                        color: hasUnread
                                                            ? Colors.red
                                                            : Colors
                                                                  .purple[900],
                                                        size: 26,
                                                      ),
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                ChatScreen(
                                                                  chatId:
                                                                      chatId,
                                                                  recipientName:
                                                                      creatorName,
                                                                  senderRole:
                                                                      "Brand",
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    // Bulă roșie mică de notificare plasată deasupra pictogramei
                                                    if (hasUnread)
                                                      const Positioned(
                                                        right: 4,
                                                        top: 4,
                                                        child: CircleAvatar(
                                                          radius: 5,
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      ),
                                                  ],
                                                );
                                              },
                                            ),
                                            const Spacer(),
                                            if (status == 'pending') ...[
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                                onPressed: () => _dbService
                                                    .updateApplicationStatus(
                                                      appId,
                                                      'accepted',
                                                    ),
                                                child: const Text(
                                                  'Acceptă',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                onPressed: () => _dbService
                                                    .updateApplicationStatus(
                                                      appId,
                                                      'Respinge',
                                                    ),
                                                child: const Text(
                                                  'Respinge',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }).toList(),
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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    String text = 'În așteptare';
    if (status == 'accepted') {
      color = Colors.green;
      text = 'Acceptat 🎉';
    }
    if (status == 'rejected' || status == 'Respinge') {
      color = Colors.red;
      text = 'Respins ❌';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
