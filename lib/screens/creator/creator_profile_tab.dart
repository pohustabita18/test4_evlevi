import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_input.dart';

class CreatorProfileTab extends StatefulWidget {
  @override
  _CreatorProfileTabState createState() => _CreatorProfileTabState();
}

class _CreatorProfileTabState extends State<CreatorProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nicheCtrl = TextEditingController();
  final _platformsCtrl = TextEditingController();
  final _followersCtrl = TextEditingController();
  final _engagementCtrl = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Uint8List? _photoBytes;
  String? _photoBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    DocumentSnapshot doc = await _dbService.getCreatorProfile(uid);

    if (!mounted) return;

    if (doc.exists && doc.data() != null) {
      var data = doc.data() as Map<String, dynamic>;
      _nameCtrl.text = data['name'] ?? '';
      _nicheCtrl.text = data['niche'] ?? '';
      _platformsCtrl.text = data['platformsUsed'] ?? '';
      _followersCtrl.text = (data['followers'] ?? 0).toString();
      _engagementCtrl.text = data['engagement'] ?? '';
      setState(() {
        _photoBase64 = data['photoBase64'];
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
          _photoBytes = bytes;
        });
      }
    } catch (e) {
      print("Eroare la selectare poză profil: $e");
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_photoBytes != null) {
          _photoBase64 = base64Encode(_photoBytes!);
        }

        await _dbService.saveCreatorProfile(uid, {
          'name': _nameCtrl.text,
          'niche': _nicheCtrl.text,
          'platformsUsed': _platformsCtrl.text,
          'followers': int.tryParse(_followersCtrl.text) ?? 0,
          'engagement': _engagementCtrl.text,
          'photoBase64': _photoBase64,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil creator salvat cu succes! 🎉'),
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
                    backgroundImage: _photoBytes != null
                        ? MemoryImage(_photoBytes!)
                        : (_photoBase64 != null
                              ? MemoryImage(base64Decode(_photoBase64!))
                              : null),
                    child: _photoBytes == null && _photoBase64 == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 38,
                            color: Color(0xFF0F172A),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              CustomInput(label: 'Nume Complet', controller: _nameCtrl),
              CustomInput(
                label: 'Nișă Principală (ex: Tech, Food)',
                controller: _nicheCtrl,
              ),
              CustomInput(
                label: 'Platforme folosite (ex: TikTok, Instagram)',
                controller: _platformsCtrl,
              ),
              CustomInput(
                label: 'Număr Urmăritori',
                controller: _followersCtrl,
                keyboardType: TextInputType.number,
              ),
              CustomInput(
                label: 'Engagement Rate (%)',
                controller: _engagementCtrl,
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
              const SizedBox(height: 16),

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
