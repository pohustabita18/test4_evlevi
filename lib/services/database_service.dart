import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- IMAGINI (Storage) ---
  Future<String> uploadImage(String path, File imageFile) async {
    Reference ref = _storage.ref().child(path);
    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // --- BRAND PROFILES ---
  Future<void> saveBrandProfile(String uid, Map<String, dynamic> data) async {
    await _db
        .collection('brand_profiles')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getBrandProfile(String uid) async {
    return await _db.collection('brand_profiles').doc(uid).get();
  }

  // --- CREATOR PROFILES ---
  Future<void> saveCreatorProfile(String uid, Map<String, dynamic> data) async {
    await _db
        .collection('creator_profiles')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getCreatorProfile(String uid) async {
    return await _db.collection('creator_profiles').doc(uid).get();
  }

  // --- CAMPAIGNS (CRUD) ---
  Future<void> createCampaign(Map<String, dynamic> data) async {
    await _db.collection('campaigns').add(data);
  }

  Future<void> updateCampaign(String id, Map<String, dynamic> data) async {
    await _db.collection('campaigns').doc(id).update(data);
  }

  Future<void> deleteCampaign(String id) async {
    await _db.collection('campaigns').doc(id).delete();
  }

  Stream<QuerySnapshot> getBrandCampaigns(String brandId) {
    return _db
        .collection('campaigns')
        .where('brandId', isEqualTo: brandId)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllCampaigns() {
    return _db.collection('campaigns').snapshots();
  }

  // --- APPLICATIONS ---
  Future<void> applyToCampaign(Map<String, dynamic> data) async {
    await _db.collection('applications').add(data);
  }

  Stream<QuerySnapshot> getCampaignApplications(String campaignId) {
    return _db
        .collection('applications')
        .where('campaignId', isEqualTo: campaignId)
        .snapshots();
  }

  Future<void> updateApplicationStatus(String id, String status) async {
    await _db.collection('applications').doc(id).update({'status': status});
  }

  // --- ADMIN ---
  Stream<QuerySnapshot> getAllUsers() {
    return _db.collection('users').snapshots();
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
    await _db.collection('brand_profiles').doc(uid).delete();
    await _db.collection('creator_profiles').doc(uid).delete();
  }
  // --- ADAUGĂ ACESTE METODE ÎN CLASA DATABASE_SERVICE ---

  // Ia toate aplicațiile trimise pentru o anumită campanie (folosit de Brand)
  Stream<QuerySnapshot> getApplicationsForCampaign(String campaignId) {
    return _db
        .collection('applications')
        .where('campaignId', isEqualTo: campaignId)
        .snapshots();
  }

  // Trimite un mesaj în chat
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    if (text.trim().isEmpty) return;

    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Actualizăm și documentul principal de chat pentru istoric/sortare ulterioară
    await _db.collection('chats').doc(chatId).set({
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Ascultă mesajele în timp real dintr-o conversație
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true) // Cele mai noi mesaje jos
        .snapshots();
  }
}
