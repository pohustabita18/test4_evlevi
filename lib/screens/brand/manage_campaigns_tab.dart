import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_input.dart';
import 'campaign_applications_screen.dart';

class ManageCampaignsTab extends StatefulWidget {
  @override
  _ManageCampaignsTabState createState() => _ManageCampaignsTabState();
}

class _ManageCampaignsTabState extends State<ManageCampaignsTab> {
  final DatabaseService _dbService = DatabaseService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String _campaignCategory = "Fashion";
  final List<String> _categories = [
    'Fashion',
    'Food',
    'Makeup',
    'Tehnologie',
    'Altele',
  ];

  List<Uint8List> _selectedImagesBytes = [];
  bool _isUploadingImages = false;

  void _showCampaignDialog(
    BuildContext context, {
    String? id,
    String? title,
    String? desc,
    double? budget,
    String? minFollowers, // 🔴 NOU
    String? deliverables, // 🔴 NOU
    String? deadline,
    String? currentCategory,
    String? productCategory,
    List<dynamic>? existingImages,
  }) {
    final titleCtrl = TextEditingController(text: title);
    final descCtrl = TextEditingController(text: desc);
    final budgetCtrl = TextEditingController(text: budget?.toString() ?? '');
    final minFollowersCtrl = TextEditingController(
      text: minFollowers ?? '',
    ); // 🔴 NOU
    final deliverablesCtrl = TextEditingController(
      text: deliverables ?? '',
    ); // 🔴 NOU
    final deadlineCtrl = TextEditingController(text: deadline);
    final productCategoryCtrl = TextEditingController(
      text: productCategory ?? '',
    );

    _selectedImagesBytes = [];
    List<String> imageUrlsList = List<String>.from(existingImages ?? []);

    if (currentCategory != null) {
      _campaignCategory = currentCategory;
    } else {
      _campaignCategory = "Fashion";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(id == null ? 'Creează Campanie' : 'Modifică Campanie'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomInput(label: 'Titlu Campanie', controller: titleCtrl),
                  CustomInput(
                    label: 'Descriere Campanie',
                    controller: descCtrl,
                  ),
                  CustomInput(
                    label: 'Categoria de produs (ex: Hanorace, Telefoane)',
                    controller: productCategoryCtrl,
                  ),
                  CustomInput(
                    label: 'Buget (RON)',
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                  ),

                  // 🔴 NOU: Câmpuri specifice cerute în imagine
                  CustomInput(
                    label: 'Minim Urmăritori (ex: 10,000)',
                    controller: minFollowersCtrl,
                  ),
                  CustomInput(
                    label:
                        'Livrabile (ex: 1 Video Reels + 3 Stories TikTok/Insta)',
                    controller: deliverablesCtrl,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownButtonFormField<String>(
                      value: _campaignCategory,
                      decoration: InputDecoration(
                        labelText: 'Nișă Campanie',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => _campaignCategory = val!),
                    ),
                  ),

                  CustomInput(label: 'Termen Limită', controller: deadlineCtrl),

                  SizedBox(height: 10),

                  ElevatedButton.icon(
                    icon: Icon(Icons.add_a_photo),
                    label: Text('Adaugă Fotografii Produs'),
                    onPressed: () async {
                      try {
                        final ImagePicker picker = ImagePicker();
                        final List<XFile> images = await picker
                            .pickMultiImage();

                        if (images.isNotEmpty) {
                          List<Uint8List> temporaryBytes = [];
                          for (var img in images) {
                            var bytes = await img.readAsBytes();
                            temporaryBytes.add(bytes);
                          }

                          setDialogState(() {
                            _selectedImagesBytes.addAll(temporaryBytes);
                          });
                        }
                      } catch (e) {
                        print("Eroare la selectare imagini: $e");
                      }
                    },
                  ),

                  if (_selectedImagesBytes.isNotEmpty)
                    Container(
                      height: 80,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImagesBytes.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.memory(
                              _selectedImagesBytes[index],
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),

                  _isUploadingImages ? LinearProgressIndicator() : Container(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Anulează'),
            ),
            ElevatedButton(
              onPressed: _isUploadingImages
                  ? null
                  : () async {
                      setDialogState(() => _isUploadingImages = true);

                      try {
                        for (int i = 0; i < _selectedImagesBytes.length; i++) {
                          String base64String = base64Encode(
                            _selectedImagesBytes[i],
                          );
                          imageUrlsList.add(base64String);
                        }

                        var data = {
                          'brandId': uid,
                          'title': titleCtrl.text,
                          'description': descCtrl.text,
                          'productCategory': productCategoryCtrl.text,
                          'budget': double.tryParse(budgetCtrl.text) ?? 0.0,
                          'minFollowers': minFollowersCtrl.text, // 🔴 NOU
                          'deliverables': deliverablesCtrl.text, // 🔴 NOU
                          'category': _campaignCategory,
                          'deadline': deadlineCtrl.text,
                          'imageUrls': imageUrlsList,
                          'status': 'active',
                        };

                        if (id == null) {
                          await _dbService.createCampaign(data);
                        } else {
                          await _dbService.updateCampaign(id, data);
                        }

                        Navigator.pop(context);
                      } catch (e) {
                        print("Eroare la salvare: $e");
                      } finally {
                        setDialogState(() => _isUploadingImages = false);
                      }
                    },
              child: Text('Salvează'),
            ),
          ],
        ),
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
              List<dynamic> imgs = data['imageUrls'] ?? [];

              return Card(
                margin: EdgeInsets.all(8),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(data['title'] ?? ''),
                      subtitle: Text(
                        'Nișă: ${data['category']} | Urmăritori: ${data['minFollowers'] ?? '-'}\nBuget: ${data['budget']} RON | Termen: ${data['deadline']}',
                      ),
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
                              minFollowers: data['minFollowers'], // 🔴 NOU
                              deliverables: data['deliverables'], // 🔴 NOU
                              deadline: data['deadline'],
                              currentCategory: data['category'],
                              productCategory: data['productCategory'],
                              existingImages: imgs,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _dbService.deleteCampaign(id),
                          ),
                        ],
                      ),
                    ),
                    if (imgs.isNotEmpty)
                      Container(
                        height: 60,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        alignment: Alignment.centerLeft,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: imgs.length,
                          itemBuilder: (context, imgIndex) => Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                base64Decode(imgs[imgIndex]),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
