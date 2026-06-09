import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_input.dart';
import 'campaign_applications_screen.dart'; // 🔴 NOU: Importul către ecranul de aplicații

class ManageCampaignsTab extends StatelessWidget {
  final DatabaseService _dbService = DatabaseService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  void _showCampaignDialog(
    BuildContext context, {
    String? id,
    String? title,
    String? desc,
    double? budget,
    String? criteria,
    String? deadline,
  }) {
    final titleCtrl = TextEditingController(text: title);
    final descCtrl = TextEditingController(text: desc);
    final budgetCtrl = TextEditingController(text: budget?.toString() ?? '');
    final criteriaCtrl = TextEditingController(text: criteria);
    final deadlineCtrl = TextEditingController(text: deadline);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Creează Campanie' : 'Modifică Campanie'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomInput(label: 'Titlu', controller: titleCtrl),
              CustomInput(label: 'Descriere', controller: descCtrl),
              CustomInput(
                label: 'Buget (€)',
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
              ),
              CustomInput(label: 'Criterii', controller: criteriaCtrl),
              CustomInput(label: 'Termen Limită', controller: deadlineCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () async {
              var data = {
                'brandId': uid,
                'title': titleCtrl.text,
                'description': descCtrl.text,
                'budget': double.tryParse(budgetCtrl.text) ?? 0.0,
                'criteria': criteriaCtrl.text,
                'deadline': deadlineCtrl.text,
                'status': 'active',
              };
              if (id == null) {
                await _dbService.createCampaign(data);
              } else {
                await _dbService.updateCampaign(id, data);
              }
              Navigator.pop(context);
            },
            child: Text('Salvează'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCampaignDialog(context),
        child: Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getBrandCampaigns(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var data = docs[i].data() as Map<String, dynamic>;
              String id = docs[i].id;
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: Text(
                    'Buget: ${data['budget']}€ | Termen: ${data['deadline']}',
                  ),
                  // 🔴 NOU: Când brandul apasă pe rândul campaniei, deschide aplicațiile primite
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CampaignApplicationsScreen(
                          campaignId: id,
                          campaignTitle: data['title'] ?? 'Campanie',
                        ),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showCampaignDialog(
                          context,
                          id: id,
                          title: data['title'],
                          desc: data['description'],
                          budget: (data['budget'] as num).toDouble(),
                          criteria: data['criteria'],
                          deadline: data['deadline'],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _dbService.deleteCampaign(id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
