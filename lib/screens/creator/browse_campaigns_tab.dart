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
          // 🔍 Câmp de căutare stilizat
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              style: const TextStyle(
                color: Colors.black,
              ), // Scris complet negru la tastare
              decoration: InputDecoration(
                labelText: 'Caută după titlu...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0F172A)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF0F172A),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

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

                    selectedColor: const Color(0xFF0F172A),
                    backgroundColor: const Color(0xFFE3F0FF),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedCategory = _categories[idx]);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 🎚️ Slider pentru buget adaptat temei
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Slider(
              value: _minBudget,
              min: 0,
              max: 25000,
              divisions: 50,
              activeColor: const Color(
                0xFF0F172A,
              ), // 🔴 NOU: Albastru închis regal
              inactiveColor: const Color(0xFFE3F0FF),
              label: 'Buget minim: ${_minBudget.toInt()} lei',
              onChanged: (val) => setState(() => _minBudget = val),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getCreatorApplications(currentUserId),
              builder: (context, appSnapshot) {
                if (!appSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0F172A),
                      ),
                    ),
                  );
                }

                final Set<String> appliedCampaignIds = appSnapshot.data!.docs
                    .map(
                      (doc) =>
                          (doc.data() as Map<String, dynamic>)['campaignId']
                              as String,
                    )
                    .toSet();

                return StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getAllCampaigns(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0F172A),
                          ),
                        ),
                      );
                    }

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
                      bool isNewCampaign = !appliedCampaignIds.contains(doc.id);

                      return matchesSearch &&
                          matchesBudget &&
                          matchesCategory &&
                          isNewCampaign;
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'Nicio campanie nouă momentan sau ai aplicat deja la toate opțiunile disponibile! 🎉',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.74,
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
                            elevation: 1,
                            shadowColor: const Color(
                              0xFF0F172A,
                            ).withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
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
                                          const Icon(
                                            Icons.storefront,
                                            size: 16,
                                            color: Color(0xFF0F172A),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              brandName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Color(
                                                  0xFF0F172A,
                                                ), // Text Deep Navy
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),

                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    color: const Color(0xFFF0F4F8),
                                    child: imgs.isNotEmpty
                                        ? Image.memory(
                                            base64Decode(imgs[0]),
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.image,
                                            color: Colors.black26,
                                            size: 32,
                                          ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(10.0),
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
                                          color: Colors.black,
                                        ), // Text complet negru
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Produs: ${data['productCategory'] ?? 'General'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE3F0FF),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${data['budget']} RON',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF0F172A),
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
