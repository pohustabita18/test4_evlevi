import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../shared/chat_screen.dart';

class MyApplicationsTab extends StatefulWidget {
  @override
  _MyApplicationsTabState createState() => _MyApplicationsTabState();
}

class _MyApplicationsTabState extends State<MyApplicationsTab> {
  final DatabaseService _dbService = DatabaseService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String _selectedFilter = 'Toate';

  final List<String> _filters = [
    'Toate',
    'În așteptare',
    'Acceptat',
    'Respins',
  ];

  String _mapFilterToStatus(String filter) {
    if (filter == 'În așteptare') return 'pending';
    if (filter == 'Acceptat') return 'accepted';
    if (filter == 'Respins') return 'rejected';
    return 'all';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundalul general Baby Blue se aplică automat din main.dart
      body: Column(
        children: [
          // 🏷️ Bare de filtre sus stilizată uniform
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, idx) {
                bool isSelected = _selectedFilter == _filters[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(_filters[idx]),
                    selected: isSelected,
                    // 🔴 REPROIECTAT: Culorile filtrelor asortate cu restul aplicației
                    selectedColor: const Color(0xFF0F172A), // Deep Navy
                    backgroundColor: const Color(0xFFE3F0FF), // Soft Ice Blue
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedFilter = _filters[idx]);
                    },
                  ),
                );
              },
            ),
          ),

          // Lista de aplicații trimise
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getCreatorApplications(currentUserId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0F172A),
                      ),
                    ),
                  );
                }

                String targetStatus = _mapFilterToStatus(_selectedFilter);
                var apps = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return targetStatus == 'all' ||
                      data['status'] == targetStatus;
                }).toList();

                if (apps.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Nu ai nicio aplicație în această categorie.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, i) {
                    var appData = apps[i].data() as Map<String, dynamic>;
                    String campaignId = appData['campaignId'] ?? '';
                    String status = appData['status'] ?? 'pending';
                    String chatId = "${campaignId}_$currentUserId";

                    // Luăm detaliile campaniei din Firestore
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('campaigns')
                          .doc(campaignId)
                          .get(),
                      builder: (context, campSnapshot) {
                        String campTitle = "Se încarcă campania...";
                        String campBudget = "-";

                        if (campSnapshot.hasData && campSnapshot.data!.exists) {
                          var cData =
                              campSnapshot.data!.data() as Map<String, dynamic>;
                          campTitle = cData['title'] ?? 'Fără titlu';
                          campBudget = '${cData['budget'] ?? 0} RON';
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ), // Card rotunjit premium la 24px
                          elevation: 1,
                          shadowColor: const Color(
                            0xFF0F172A,
                          ).withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 4.0,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                campTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Buget: $campBudget\nMesaj trimis: "${appData['message']?.isEmpty ?? true ? 'Fără mesaj text' : appData['message']}"',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildStatusBadge(status),
                                  const SizedBox(width: 8),

                                  // 🔴 REPROIECTAT: Ascultare live pentru mesaje necitite de la Brand la Creator
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
                                            chatData['unreadByCreator'] ??
                                            false;
                                      }

                                      return Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              hasUnread
                                                  ? Icons.mark_chat_unread
                                                  : Icons.chat_bubble_outline,
                                              color: hasUnread
                                                  ? Colors.red
                                                  : const Color(
                                                      0xFF0F172A,
                                                    ), // Albastru închis asortat
                                              size: 26,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ChatScreen(
                                                    chatId: chatId,
                                                    recipientName:
                                                        "Suport: $campTitle",
                                                    senderRole:
                                                        "Creator", // 🔴 REPARAT: Trimitem corect rolul de Creator
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
                                                backgroundColor: Colors.red,
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Stilizare capsulă status uniformă
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
        border: Border.all(color: color.withOpacity(0.4), width: 1),
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
