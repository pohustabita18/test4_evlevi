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
  String _selectedFilter = 'Toate'; // Filtru curent

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
      body: Column(
        children: [
          // Bare de filtre sus
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              padding: EdgeInsets.symmetric(horizontal: 6),
              itemBuilder: (context, idx) {
                bool isSelected = _selectedFilter == _filters[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(_filters[idx]),
                    selected: isSelected,
                    selectedColor: Colors.purple[800],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
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
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                String targetStatus = _mapFilterToStatus(_selectedFilter);
                var apps = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return targetStatus == 'all' ||
                      data['status'] == targetStatus;
                }).toList();

                if (apps.isEmpty) {
                  return Center(
                    child: Text('Nu ai nicio aplicație în această categorie.'),
                  );
                }

                return ListView.builder(
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
                        String campTitle = "Campanie încărcată...";
                        String campBudget = "-";

                        if (campSnapshot.hasData && campSnapshot.data!.exists) {
                          var cData =
                              campSnapshot.data!.data() as Map<String, dynamic>;
                          campTitle = cData['title'] ?? 'Fără titlu';
                          campBudget = '${cData['budget'] ?? 0} RON';
                        }

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(
                              campTitle,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Buget: $campBudget\nMesajul tău: "${appData['message']}"',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatusBadge(status),
                                SizedBox(width: 8),

                                // 🔴 NOU: StreamBuilder care ascultă notificările de mesaje noi de la Brand
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
                                          false; // Notificare pt creator
                                    }

                                    return Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            hasUnread
                                                ? Icons.mark_chat_unread
                                                : Icons.chat,
                                            color: hasUnread
                                                ? Colors.red
                                                : Colors.indigo,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                  chatId: chatId,
                                                  recipientName:
                                                      "Suport: $campTitle",
                                                  senderRole: '',
                                                  // senderRole removed: not defined in ChatScreen constructor
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        if (hasUnread)
                                          Positioned(
                                            right: 6,
                                            top: 6,
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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    String text = 'În așteptare';
    if (status == 'accepted') {
      color = Colors.green;
      text = 'Acceptat';
    }
    if (status == 'rejected') {
      color = Colors.red;
      text = 'Respins';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          fontSize: 12,
        ),
      ),
    );
  }
}
