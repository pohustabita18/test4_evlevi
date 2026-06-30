import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class AdminDashboard extends StatelessWidget {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panou Administrator 🛡️'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => AuthService().signOut(),
            ),
          ],

          bottom: const TabBar(
            labelColor: Color(0xFF0F172A), // Culoarea tab-ului activ
            unselectedLabelColor: Colors.black54, // Culoarea tab-ului inactiv
            indicatorColor: Color(0xFF0F172A), // Linia de dedesubt
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Utilizatori'),
              Tab(text: 'Toate Campaniile'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _dbService.getAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nu există utilizatori înregistrați.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),

                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE3F0FF),
                          child: Icon(Icons.person, color: Color(0xFF0F172A)),
                        ),
                        title: Text(
                          data['email'] ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Rol: ${data['role']}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _dbService.deleteUser(docs[i].id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            StreamBuilder<QuerySnapshot>(
              stream: _dbService.getAllCampaigns(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nu există campanii active.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE3F0FF),
                          child: Icon(
                            Icons.business_center,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        title: Text(
                          data['title'] ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Buget: ${data['budget']} lei | ID Brand: ${data['brandId']}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () =>
                              _dbService.deleteCampaign(docs[i].id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
