import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  File? _image;
  String? _logoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    DocumentSnapshot doc = await _dbService.getBrandProfile(uid);
    if (doc.exists && doc.data() != null) {
      var data = doc.data() as Map<String, dynamic>;
      _nameController.text = data['companyName'] ?? '';
      _descController.text = data['description'] ?? '';
      _industryController.text = data['industry'] ?? '';
      _websiteController.text = data['website'] ?? '';
      _budgetController.text = (data['budget'] ?? 0).toString();
      setState(() => _logoUrl = data['logoUrl']);
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
          _logoUrl = await _dbService.uploadImage('logos/$uid.jpg', _image!);
        }
        await _dbService.saveBrandProfile(uid, {
          'companyName': _nameController.text,
          'description': _descController.text,
          'industry': _industryController.text,
          'website': _websiteController.text,
          'budget': double.tryParse(_budgetController.text) ?? 0.0,
          'logoUrl': _logoUrl,
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
                onPanEnd: (details) => _pickImage(),
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (_logoUrl != null ? NetworkImage(_logoUrl!) : null)
                            as ImageProvider?,
                  child: _image == null && _logoUrl == null
                      ? Icon(Icons.add_a_photo, size: 40)
                      : null,
                ),
              ),
              SizedBox(height: 15),
              CustomInput(label: 'Nume Companie', controller: _nameController),
              CustomInput(label: 'Descriere', controller: _descController),
              CustomInput(
                label: 'Domeniu de Activitate',
                controller: _industryController,
              ),
              CustomInput(label: 'Website', controller: _websiteController),
              CustomInput(
                label: 'Buget Disponibil (€)',
                controller: _budgetController,
                keyboardType: TextInputType.number,
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
