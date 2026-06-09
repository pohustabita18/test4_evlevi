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
          title: Text('Panou Administrator 🛡️'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => AuthService().signOut(),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Utilizatori'),
              Tab(text: 'Toate Campaniile'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Listă utilizatori
            StreamBuilder<QuerySnapshot>(
              stream: _dbService.getAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['email'] ?? ''),
                      subtitle: Text('Rol: ${data['role']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _dbService.deleteUser(docs[i].id),
                      ),
                    );
                  },
                );
              },
            ),
            // Listă toate campaniile
            StreamBuilder<QuerySnapshot>(
              stream: _dbService.getAllCampaigns(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['title'] ?? ''),
                      subtitle: Text(
                        'Buget: ${data['budget']}€ | ID Brand: ${data['brandId']}',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _dbService.deleteCampaign(docs[i].id),
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
