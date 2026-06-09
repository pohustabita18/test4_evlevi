import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import 'campaign_details_screen.dart';

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
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // Selector de categorii (Chips)
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
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

          // Slider pentru buget
          Slider(
            value: _minBudget,
            min: 0,
            max: 25000,
            divisions: 50,
            activeColor: Colors.purple[800],
            label: 'Buget minim: ${_minBudget.toInt()} lei',
            onChanged: (val) => setState(() => _minBudget = val),
          ),

          // 🔴 GRID-UL DE CAMPANII CU FILTRARE SUPLEMENTARĂ
          Expanded(
            // Pasul 1: Ascultăm aplicațiile trimise deja de acest creator
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getCreatorApplications(currentUserId),
              builder: (context, appSnapshot) {
                if (!appSnapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                // Creăm un Set cu toate ID-urile campaniilor la care s-a aplicat deja
                final Set<String> appliedCampaignIds = appSnapshot.data!.docs
                    .map(
                      (doc) =>
                          (doc.data() as Map<String, dynamic>)['campaignId']
                              as String,
                    )
                    .toSet();

                // Pasul 2: Ascultăm toate campaniile din platformă
                return StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getAllCampaigns(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    // Filtrăm campaniile direct în memorie înainte de a genera GridView-ul
                    var docs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String title = (data['title'] ?? '')
                          .toString()
                          .toLowerCase();
                      double budget =
                          (data['budget'] as num?)?.toDouble() ?? 0.0;
                      String category = (data['category'] ?? 'Altele')
                          .toString();

                      bool matchesSearch = title.contains(_searchQuery);
                      bool matchesBudget = budget >= _minBudget;
                      bool matchesCategory =
                          _selectedCategory == "Toate" ||
                          category == _selectedCategory;

                      // 🔴 CONDIȚIA CONCRETĂ: Permitem afișarea DOAR dacă ID-ul NU se află în set-ul de aplicații trimise
                      bool isNewCampaign = !appliedCampaignIds.contains(doc.id);

                      return matchesSearch &&
                          matchesBudget &&
                          matchesCategory &&
                          isNewCampaign;
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Felicitări! Ai aplicat la toate campaniile disponibile sau nu există noutăți.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        var data = docs[i].data() as Map<String, dynamic>;
                        String campaignId = docs[i].id;
                        List<dynamic> imgs = data['imageUrls'] ?? [];
                        String brandId = data['brandId'] ?? '';

                        return InkWell(
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
                                // Afișare Nume Brand sus pe card
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: FutureBuilder<DocumentSnapshot>(
                                    future: _dbService.getBrandProfile(brandId),
                                    builder: (context, brandSnapshot) {
                                      String brandName = "Se încarcă...";
                                      if (brandSnapshot.hasData &&
                                          brandSnapshot.data!.exists) {
                                        var bData =
                                            brandSnapshot.data!.data()
                                                as Map<String, dynamic>;
                                        brandName =
                                            bData['companyName'] ??
                                            'Brand Anonim';
                                      }
                                      return Row(
                                        children: [
                                          Icon(
                                            Icons.storefront,
                                            size: 16,
                                            color: Colors.purple[800],
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              brandName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.purple[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),

                                // Imaginea produsului
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.grey[100],
                                    child: imgs.isNotEmpty
                                        ? ClipRRect(
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

                                // Detalii inferioare (Titlu, Produs, Buget)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['title'] ?? 'Campanie',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Produs: ${data['productCategory'] ?? 'General'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple[50],
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
