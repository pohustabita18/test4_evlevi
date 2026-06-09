import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../shared/chat_screen.dart'; // Am scos importul pentru custom_input deoarece nu mai avem nevoie de el

class CampaignDetailsScreen extends StatelessWidget {
  final String campaignId;
  final Map<String, dynamic> campaignData;
  final String currentUserId;
  final DatabaseService _dbService = DatabaseService();

  CampaignDetailsScreen({
    required this.campaignId,
    required this.campaignData,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> imgs = campaignData['imageUrls'] ?? [];
    bool hasImage = imgs.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalii campanie'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getApplicationForCampaignAndCreator(
          campaignId,
          currentUserId,
        ),
        builder: (context, appSnapshot) {
          bool hasApplied =
              appSnapshot.hasData && appSnapshot.data!.docs.isNotEmpty;
          String appStatus = hasApplied
              ? (appSnapshot.data!.docs.first.data()
                        as Map<String, dynamic>)['status'] ??
                    'pending'
              : "none";

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imaginea mare de sus (Header)
                      Container(
                        width: double.infinity,
                        height: 230,
                        color: Colors.grey[200],
                        child: hasImage
                            ? Image.memory(
                                base64Decode(imgs[0]),
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titlu & Tag Buget
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    campaignData['title'] ?? 'Campanie',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[900],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${campaignData['budget']} RON',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 6),
                            Text(
                              'Produs vizat: ${campaignData['productCategory'] ?? 'Nespecificat'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),

                            Divider(height: 30),

                            // Secțiunea Cerințe
                            Text(
                              'Cerințe',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),

                            _buildRequirementRow(
                              Icons.people_alt_outlined,
                              'Minim ${campaignData['minFollowers']?.isEmpty ?? true ? '10,000' : campaignData['minFollowers']} urmăritori',
                            ),

                            _buildRequirementRow(
                              Icons.camera_alt_outlined,
                              campaignData['deliverables']?.isEmpty ?? true
                                  ? '1 Video Reels + 3 Stories TikTok/Insta'
                                  : campaignData['deliverables'],
                            ),

                            _buildRequirementRow(
                              Icons.account_tree_outlined,
                              'Nișa: ${campaignData['category'] ?? 'Fashion / Lifestyle'}',
                            ),

                            Divider(height: 30),

                            // Secțiunea Descriere
                            Text(
                              'Descriere',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              campaignData['description'] ??
                                  'Nu există o descriere adăugată.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),

                            SizedBox(height: 12),
                            Text(
                              'Termen limită aplicație: ${campaignData['deadline'] ?? '-'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bara de acțiuni (Butonul de jos)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: !hasApplied
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[900],
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              // 🔴 MODIFICAT: Trimite direct datele în Firestore la click, fără ferestre secundare
                              onPressed: () async {
                                try {
                                  await _dbService.applyToCampaign({
                                    'campaignId': campaignId,
                                    'creatorId': currentUserId,
                                    'message':
                                        '', // Lăsăm mesajul gol deoarece am eliminat căsuța text
                                    'status': 'pending',
                                    'createdAt':
                                        Timestamp.now(), // Timp stabil pentru a evita bug-ul de dispariție
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Te-ai înscris cu succes în campanie! 🎉',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Eroare la înscriere: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                'Aplica la Campanie',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : _buildStatusWidget(appStatus),
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.purple[900],
                        size: 28,
                      ),
                      style: IconButton.styleFrom(
                        side: BorderSide(
                          color: Colors.purple[900]!.withOpacity(0.3),
                        ),
                        padding: EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        String chatId = "${campaignId}_$currentUserId";
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chatId,
                              recipientName:
                                  "Suport Brand: ${campaignData['title']}",
                              senderRole: "Creator",
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequirementRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.black54),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(String status) {
    Color color;
    String text;
    switch (status) {
      case 'accepted':
        color = Colors.green;
        text = 'Aplicație Acceptată 🎉';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Aplicație Respinsă ❌';
        break;
      default:
        color = Colors.orange;
        text = 'Aplicație în Așteptare ⏳';
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
