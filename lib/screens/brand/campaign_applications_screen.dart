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
      appBar: AppBar(title: Text('Aplicații: $campaignTitle')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getApplicationsForCampaign(campaignId),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          var apps = snapshot.data!.docs;

          if (apps.isEmpty)
            return Center(
              child: Text('Nu există aplicații pentru această campanie.'),
            );

          return ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, i) {
              var appData = apps[i].data() as Map<String, dynamic>;
              String appId = apps[i].id;
              String creatorId = appData['creatorId'] ?? '';
              String status = appData['status'] ?? 'pending';

              // Folosim FutureBuilder pentru a lua numele și detaliile creatorului din profilul său
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
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            creatorName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Mesaj: "${appData['message']}"',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Status curent: ${status.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: status == 'accepted'
                                  ? Colors.green
                                  : (status == 'rejected'
                                        ? Colors.red
                                        : Colors.orange),
                            ),
                          ),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Buton Chat direct
                              TextButton.icon(
                                icon: Icon(Icons.chat, color: Colors.indigo),
                                label: Text('Chat'),
                                onPressed: () {
                                  // Generăm un ID unic pentru chat format din ID campanie + ID creator
                                  String chatId = "${campaignId}_$creatorId";
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        chatId: chatId,
                                        recipientName: creatorName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Spacer(),
                              if (status == 'pending') ...[
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () =>
                                      _dbService.updateApplicationStatus(
                                        appId,
                                        'accepted',
                                      ),
                                  child: Text('Acceptă'),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _dbService.updateApplicationStatus(
                                        appId,
                                        'rejected',
                                      ),
                                  child: Text('Respinge'),
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
}
