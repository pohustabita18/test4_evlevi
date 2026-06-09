import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_input.dart';
import '../shared/chat_screen.dart';

class BrowseCampaignsTab extends StatefulWidget {
  @override
  _BrowseCampaignsTabState createState() => _BrowseCampaignsTabState();
}

class _BrowseCampaignsTabState extends State<BrowseCampaignsTab> {
  final DatabaseService _dbService = DatabaseService();
  String _searchQuery = "";
  double _minBudget = 0.0;
  String _selectedCategory = "Toate"; // 🔴 NOU: Categoria selectată implicit

  // Lista de categorii cerute
  final List<String> _categories = [
    'Toate',
    'Fashion',
    'Food',
    'Makeup',
    'Tehnologie',
    'Altele',
  ];

  void _applyToCampaignDialog(BuildContext context, String campaignId) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Aplică la campanie'),
        content: CustomInput(label: 'Mesaj pentru brand', controller: msgCtrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbService.applyToCampaign({
                'campaignId': campaignId,
                'creatorId': FirebaseAuth.instance.currentUser!.uid,
                'message': msgCtrl.text,
                'status': 'pending',
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Aplicație trimisă!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Trimite'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Câmpul de căutare text
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Caută după titlu...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // 🔴 NOU: Dropdown pentru selectarea categoriei (Nisă)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                Text(
                  'Categorie: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((String cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategory = val!);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Slider pentru buget (Modificat în LEI și maxim crescut la 25.000)
          Slider(
            value: _minBudget,
            min: 0,
            max: 25000,
            divisions: 50,
            label:
                'Buget minim: ${_minBudget.toInt()} lei', // 🔴 Schimbat în lei
            onChanged: (val) => setState(() => _minBudget = val),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getAllCampaigns(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                // Filtrarea datelor în timp real
                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String title = (data['title'] ?? '').toString().toLowerCase();
                  double budget = (data['budget'] as num?)?.toDouble() ?? 0.0;
                  String category = (data['category'] ?? 'Altele')
                      .toString(); // Luăm categoria din DB

                  bool matchesSearch = title.contains(_searchQuery);
                  bool matchesBudget = budget >= _minBudget;
                  // Verificăm dacă se potrivește categoria sau dacă este selectat "Toate"
                  bool matchesCategory =
                      _selectedCategory == "Toate" ||
                      category == _selectedCategory;

                  return matchesSearch && matchesBudget && matchesCategory;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Nu s-a găsit nicio campanie cu aceste filtre.',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        // 🔴 Schimbat în lei + afișare Categorie
                        subtitle: Text(
                          '${data['description']}\nCategorie: ${data['category'] ?? 'Altele'} | Buget: ${data['budget']} lei\nCriterii: ${data['criteria']}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  _applyToCampaignDialog(context, docs[i].id),
                              child: Text('Aplică'),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.chat, color: Colors.indigo),
                              onPressed: () {
                                String creatorId =
                                    FirebaseAuth.instance.currentUser!.uid;
                                String chatId = "${docs[i].id}_$creatorId";

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      chatId: chatId,
                                      recipientName:
                                          "Suport Brand: ${data['title']}",
                                    ),
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
