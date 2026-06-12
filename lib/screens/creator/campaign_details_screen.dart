import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../shared/chat_screen.dart';

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
    String brandId = campaignData['brandId'] ?? '';

    return Scaffold(
      // Fundalul general Baby Blue se aplică automat din main.dart
      appBar: AppBar(
        title: const Text('Detalii campanie'),
        backgroundColor: const Color(
          0xFFD2E6FF,
        ), // 🔴 NOU: Asortat cu Baby Blue global
        foregroundColor: const Color(0xFF0F172A), // Text titlu albastru închis
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
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
                      // 🖼️ Imaginea mare de Header adaptată cromatic
                      Container(
                        width: double.infinity,
                        height: 230,
                        color: const Color(
                          0xFFE3F0FF,
                        ), // 🔴 NOU: Înlocuit gri-ul cu un Soft Ice Blue curat
                        child: hasImage
                            ? Image.memory(
                                base64Decode(imgs[0]),
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.black26,
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
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                // Tag-ul de Buget proeminent în stil Deep Navy
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0F172A,
                                    ), // 🔴 NOU: Albastru închis regal
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${campaignData['budget']} RON',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Afișare Nume Brand dinamic sub titlu
                            FutureBuilder<DocumentSnapshot>(
                              future: _dbService.getBrandProfile(brandId),
                              builder: (context, brandSnapshot) {
                                String brandName = "Se încarcă brandul...";
                                if (brandSnapshot.hasData &&
                                    brandSnapshot.data!.exists) {
                                  var bData =
                                      brandSnapshot.data!.data()
                                          as Map<String, dynamic>;
                                  brandName =
                                      bData['companyName'] ??
                                      'Brand Nespecificat';
                                }
                                return Row(
                                  children: [
                                    const Icon(
                                      Icons.store,
                                      size: 18,
                                      color: Color(0xFF0F172A),
                                    ), // Iconiță Deep Navy
                                    const SizedBox(width: 8),
                                    Text(
                                      brandName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 6),
                            Text(
                              'Produs vizat: ${campaignData['productCategory'] ?? 'Nespecificat'}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const Divider(height: 30, color: Colors.black12),

                            // Secțiunea Cerințe
                            const Text(
                              'Cerințe 📌',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),

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

                            const Divider(height: 30, color: Colors.black12),

                            // Secțiunea Descriere
                            const Text(
                              'Descriere 📝',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              campaignData['description'] ??
                                  'Nu există o descriere adăugată.',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.45,
                              ),
                            ),

                            const SizedBox(height: 16),
                            Text(
                              'Termen limită aplicație: ${campaignData['deadline'] ?? '-'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🧱 Bara de acțiuni inferioară flotantă (Alb imaculat)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
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
                                backgroundColor: const Color(
                                  0xFF0F172A,
                                ), // 🔴 NOU: Buton mare Deep Navy
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                try {
                                  await _dbService.applyToCampaign({
                                    'campaignId': campaignId,
                                    'creatorId': currentUserId,
                                    'message': '',
                                    'status': 'pending',
                                    'createdAt': Timestamp.now(),
                                  });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Te-ai înscris cu succes în campanie! 🎉',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Eroare la înscriere: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                'Aplică la Campanie',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : _buildStatusWidget(appStatus),
                    ),
                    const SizedBox(width: 12),

                    // 🔴 REPROIECTAT: Butonul de chat asortat cu marginile Deep Navy
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF0F172A),
                        size: 26,
                      ),
                      style: IconButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF0F172A),
                          width: 1.5,
                        ), // Margine Deep Navy subțire
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
          Icon(
            icon,
            size: 22,
            color: const Color(0xFF0F172A),
          ), // 🔴 NOU: Iconițe Deep Navy
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
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
