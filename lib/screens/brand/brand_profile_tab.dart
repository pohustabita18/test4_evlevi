import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// 🗑️ Am eliminat importul către main.dart deoarece isDarkModeNotifier nu mai există
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_input.dart';

class BrandProfileTab extends StatefulWidget {
  @override
  _BrandProfileTabState createState() => _BrandProfileTabState();
}

class _BrandProfileTabState extends State<BrandProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _industryController = TextEditingController();
  final _websiteController = TextEditingController();
  final _budgetController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Uint8List? _logoBytes;
  String? _logoBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    DocumentSnapshot doc = await _dbService.getBrandProfile(uid);

    if (!mounted) return;

    if (doc.exists && doc.data() != null) {
      var data = doc.data() as Map<String, dynamic>;
      _nameController.text = data['companyName'] ?? '';
      _descController.text = data['description'] ?? '';
      _industryController.text = data['industry'] ?? '';
      _websiteController.text = data['website'] ?? '';
      _budgetController.text = (data['budget'] ?? 0).toString();

      setState(() {
        _logoBase64 = data['logoBase64'];
      });
    }
  }

  void _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        var bytes = await pickedFile.readAsBytes();
        setState(() {
          _logoBytes = bytes;
        });
      }
    } catch (e) {
      print("Eroare la selectare logo: $e");
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_logoBytes != null) {
          _logoBase64 = base64Encode(_logoBytes!);
        }

        await _dbService.saveBrandProfile(uid, {
          'companyName': _nameController.text,
          'description': _descController.text,
          'industry': _industryController.text,
          'website': _websiteController.text,
          'budget': double.tryParse(_budgetController.text) ?? 0.0,
          'logoBase64': _logoBase64,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil brand salvat cu succes! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Eroare la salvare: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: const Color(0xFFE3F0FF),
                    backgroundImage: _logoBytes != null
                        ? MemoryImage(_logoBytes!)
                        : (_logoBase64 != null
                              ? MemoryImage(base64Decode(_logoBase64!))
                              : null),
                    child: _logoBytes == null && _logoBase64 == null
                        ? const Icon(
                            Icons.add_a_photo,
                            size: 38,
                            color: Color(0xFF0F172A),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              CustomInput(label: 'Nume Companie', controller: _nameController),
              CustomInput(
                label: 'Descriere Brand',
                controller: _descController,
              ),
              CustomInput(
                label: 'Domeniu de Activitate',
                controller: _industryController,
              ),
              CustomInput(label: 'Website', controller: _websiteController),
              CustomInput(
                label: 'Buget Disponibil (lei)',
                controller: _budgetController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0F172A),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _saveProfile,
                      child: const Text(
                        'Salvează Profilul',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              // Secțiune Setări aplicație
              const Padding(
                padding: EdgeInsets.only(top: 30.0),
                child: Divider(color: Colors.black12),
              ),
              const SizedBox(height: 8),
              const Text(
                'Setări aplicație',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(
                height: 16,
              ), // Ajustat spațiul pentru un layout aerisit
              // 🗑️ Containerul complet cu ValueListenableBuilder și SwitchListTile a fost eliminat de aici

              // Butonul de Logout (Deconectare) restructurat
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Deconectare (Logout)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => AuthService().signOut(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
