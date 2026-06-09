import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import 'campaign_details_screen.dart'; // 🔴 NOU: Importul noului ecran de detalii

class BrowseCampaignsTab extends StatefulWidget {
  @override
  _BrowseCampaignsTabState createState() => _BrowseCampaignsTabState();
}

class _BrowseCampaignsTabState extends State<BrowseCampaignsTab> {
  final DatabaseService _dbService = DatabaseService();
  String _searchQuery = "";
  double _minBudget = 0.0;
  String _selectedCategory = "Toate";

  final List<String> _categories = [
    'Toate',
    'Fashion',
    'Food',
    'Makeup',
    'Tehnologie',
    'Altele',
  ];
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Câmp de căutare
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Caută după titlu...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // Selector Orizontal de Categorii (Stil chips ca în imaginea ta)
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, idx) {
                bool isSelected = _selectedCategory == _categories[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(_categories[idx]),
                    selected: isSelected,
                    selectedColor: Colors.purple[800],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    onSelected: (val) {
                      if (val)
                        setState(() => _selectedCategory = _categories[idx]);
                    },
                  ),
                );
              },
            ),
          ),

          // Slider pentru Buget
          Slider(
            value: _minBudget,
            min: 0,
            max: 25000,
            divisions: 50,
            activeColor: Colors.purple[800],
            label: 'Buget minim: ${_minBudget.toInt()} lei',
            onChanged: (val) => setState(() => _minBudget = val),
          ),

          // Grid/Listă de Campanii Recomandate
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getAllCampaigns(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String title = (data['title'] ?? '').toString().toLowerCase();
                  double budget = (data['budget'] as num?)?.toDouble() ?? 0.0;
                  String category = (data['category'] ?? 'Altele').toString();

                  bool matchesSearch = title.contains(_searchQuery);
                  bool matchesBudget = budget >= _minBudget;
                  bool matchesCategory =
                      _selectedCategory == "Toate" ||
                      category == _selectedCategory;

                  return matchesSearch && matchesBudget && matchesCategory;
                }).toList();

                if (docs.isEmpty)
                  return Center(child: Text('Nu s-a găsit nicio campanie.'));

                return GridView.builder(
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        2, // Două elemente pe rând exact ca în imagine
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    String campaignId = docs[i].id;
                    List<dynamic> imgs = data['imageUrls'] ?? [];

                    return InkWell(
                      // 🔴 NOU: Când creatorul apasă pe un card, este trimis pe ecranul complet de Detalii!
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CampaignDetailsScreen(
                              campaignId: campaignId,
                              campaignData: data,
                              currentUserId: currentUserId,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imaginea miniaturală din card
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: imgs.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        child: Image.memory(
                                          base64Decode(imgs[0]),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        Icons.image,
                                        color: Colors.grey[400],
                                      ),
                              ),
                            ),
                            // Detaliile scurte de sub imagine
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title'] ?? 'Campanie',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Produs: ${data['productCategory'] ?? 'General'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${data['budget']} RON',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.purple[900],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
