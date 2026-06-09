import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  File? _image;
  String? _photoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    DocumentSnapshot doc = await _dbService.getCreatorProfile(uid);
    if (doc.exists && doc.data() != null) {
      var data = doc.data() as Map<String, dynamic>;
      _nameCtrl.text = data['name'] ?? '';
      _nicheCtrl.text = data['niche'] ?? '';
      _platformsCtrl.text = data['platformsUsed'] ?? '';
      _followersCtrl.text = (data['followers'] ?? 0).toString();
      _engagementCtrl.text = data['engagement'] ?? '';
      setState(() => _photoUrl = data['photoUrl']);
    }
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (_image != null) {
          _photoUrl = await _dbService.uploadImage(
            'creators/$uid.jpg',
            _image!,
          );
        }
        await _dbService.saveCreatorProfile(uid, {
          'name': _nameCtrl.text,
          'niche': _nicheCtrl.text,
          'platformsUsed': _platformsCtrl.text,
          'followers': int.tryParse(_followersCtrl.text) ?? 0,
          'engagement': _engagementCtrl.text,
          'photoUrl': _photoUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil salvat!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
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
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (_photoUrl != null ? NetworkImage(_photoUrl!) : null)
                            as ImageProvider?,
                  child: _image == null && _photoUrl == null
                      ? Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              SizedBox(height: 15),
              CustomInput(label: 'Nume Complet', controller: _nameCtrl),
              CustomInput(
                label: 'Nișă (ex: Tech, Fashion)',
                controller: _nicheCtrl,
              ),
              CustomInput(
                label: 'Platforme folosite (ex: TikTok, Insta)',
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
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      child: Text('Salvează Profilul'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
