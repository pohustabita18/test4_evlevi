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
      // Fundalul se preia automat ca Baby Blue din main.dart
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getBrandCampaigns(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var campaigns = snapshot.data!.docs;

          if (campaigns.isEmpty) {
            return const Center(
              child: Text(
                'Nu aveți nicio campanie creată încă.',
                style: TextStyle(color: Colors.black87, fontSize: 15),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ExpansionTile(
                      iconColor: const Color(
                        0xFF0F172A,
                      ), // 🔴 NOU: Săgeata devine albastru închis
                      collapsedIconColor: const Color(0xFF0F172A),
                      title: Text(
                        campData['title'] ?? 'Campanie',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Produs vizat: ${campData['productCategory'] ?? 'General'}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      // 🔴 REPROIECTAT: Badge-ul de înscrieri asortat cu tema închisă
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: totalApps > 0
                              ? const Color(0xFF0F172A)
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
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ]
                          : apps.map((appDoc) {
                              var appData =
                                  appDoc.data() as Map<String, dynamic>;
                              String appId = appDoc.id;
                              String creatorId = appData['creatorId'] ?? '';
                              String status = appData['status'] ?? 'pending';
                              String chatId = "${campaignId}_$creatorId";

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
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    // 🔴 REPROIECTAT: Fundal Soft Ice Blue asortat excelent cu Baby Blue
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFE3F0FF),
                                      borderRadius: BorderRadius.circular(14),
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
                                                color: Colors
                                                    .black, // Scris negru curat
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
                                                            : const Color(
                                                                0xFF0F172A,
                                                              ), // 🔴 NOU: Schimbat în Deep Navy
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
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
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
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
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
                                                    fontWeight: FontWeight.bold,
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
