import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    String? minFollowers,
    String? deliverables,
    String? deadline,
    String? currentCategory,
    String? productCategory,
    List<dynamic>? existingImages,
  }) {
    final titleCtrl = TextEditingController(text: title);
    final descCtrl = TextEditingController(text: desc);
    final budgetCtrl = TextEditingController(text: budget?.toString() ?? '');
    final minFollowersCtrl = TextEditingController(text: minFollowers ?? '');
    final deliverablesCtrl = TextEditingController(text: deliverables ?? '');
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            id == null ? 'Creează Campanie 📢' : 'Modifică Campanie 📝',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
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
                  CustomInput(
                    label: 'Minim Urmăritori (ex: 10,000)',
                    controller: minFollowersCtrl,
                  ),
                  CustomInput(
                    label: 'Livrabile (ex: 1 Video Reels + 3 Stories)',
                    controller: deliverablesCtrl,
                  ),
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownButtonFormField<String>(
                      value: _campaignCategory,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Nișă Campanie',
                        labelStyle: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE3F0FF).withOpacity(0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                      ),
                      items: _categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => _campaignCategory = val!),
                    ),
                  ),

                  CustomInput(label: 'Termen Limită', controller: deadlineCtrl),
                  const SizedBox(height: 14),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_a_photo, size: 20),
                    label: const Text('Adaugă Fotografii Produs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE3F0FF), // Soft Ice Blue
                      foregroundColor: const Color(
                        0xFF0F172A,
                      ), // Text Deep Navy
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
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
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImagesBytes.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _selectedImagesBytes[index],
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_isUploadingImages)
                    const LinearProgressIndicator(color: Color(0xFF0F172A)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
              ),
              child: const Text(
                'Anulează',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF0F172A,
                ), // Albastru închis regal
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
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
                          'minFollowers': minFollowersCtrl.text,
                          'deliverables': deliverablesCtrl.text,
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

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        print("Eroare la salvare: $e");
                      } finally {
                        setDialogState(() => _isUploadingImages = false);
                      }
                    },
              child: const Text(
                'Salvează',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
        backgroundColor: const Color(0xFF0F172A), // Deep Navy
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getBrandCampaigns(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
              ),
            );
          }
          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Nu aveți nicio campanie activă.\nApasă pe butonul „+” pentru a crea una!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var data = docs[i].data() as Map<String, dynamic>;
              String id = docs[i].id;
              List<dynamic> imgs = data['imageUrls'] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      title: Text(
                        data['title'] ?? 'Campanie nespecificată',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Nișă: ${data['category']} | Urmăritori: ${data['minFollowers'] ?? '-'}\nBuget: ${data['budget']} RON | Termen: ${data['deadline']}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
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
                            icon: const Icon(
                              Icons.edit_note,
                              color: Color(0xFF0F172A),
                              size: 28,
                            ),
                            onPressed: () => _showCampaignDialog(
                              context,
                              id: id,
                              title: data['title'],
                              desc: data['description'],
                              budget: (data['budget'] as num?)?.toDouble(),
                              minFollowers: data['minFollowers'],
                              deliverables: data['deliverables'],
                              deadline: data['deadline'],
                              currentCategory: data['category'],
                              productCategory: data['productCategory'],
                              existingImages: imgs,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 24,
                            ),
                            onPressed: () => _dbService.deleteCampaign(id),
                          ),
                        ],
                      ),
                    ),
                    if (imgs.isNotEmpty)
                      Container(
                        height: 65,
                        padding: const EdgeInsets.only(
                          left: 16,
                          bottom: 12,
                          right: 16,
                        ),
                        alignment: Alignment.centerLeft,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: imgs.length,
                          itemBuilder: (context, imgIndex) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
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
