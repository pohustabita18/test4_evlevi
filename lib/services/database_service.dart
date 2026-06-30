import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(String path, File imageFile) async {
    Reference ref = _storage.ref().child(path);
    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> saveBrandProfile(String uid, Map<String, dynamic> data) async {
    await _db
        .collection('brand_profiles')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getBrandProfile(String uid) async {
    return await _db.collection('brand_profiles').doc(uid).get();
  }

  Future<void> saveCreatorProfile(String uid, Map<String, dynamic> data) async {
    await _db
        .collection('creator_profiles')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getCreatorProfile(String uid) async {
    return await _db.collection('creator_profiles').doc(uid).get();
  }

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

  Stream<QuerySnapshot> getCampaignApplications(String campaignId) {
    return _db
        .collection('applications')
        .where('campaignId', isEqualTo: campaignId)
        .snapshots();
  }

  Future<void> updateApplicationStatus(String id, String status) async {
    await _db.collection('applications').doc(id).update({'status': status});
  }

  Stream<QuerySnapshot> getAllUsers() {
    return _db.collection('users').snapshots();
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
    await _db.collection('brand_profiles').doc(uid).delete();
    await _db.collection('creator_profiles').doc(uid).delete();
  }

  Stream<QuerySnapshot> getApplicationsForCampaign(String campaignId) {
    return _db
        .collection('applications')
        .where('campaignId', isEqualTo: campaignId)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getApplicationForCampaignAndCreator(
    String campaignId,
    String creatorId,
  ) {
    return _db
        .collection('applications')
        .where('campaignId', isEqualTo: campaignId)
        .where('creatorId', isEqualTo: creatorId)
        .snapshots();
  }

  Future<String> uploadBytes(String path, Uint8List bytes) async {
    Reference ref = _storage.ref().child(path);
    UploadTask uploadTask = ref.putData(bytes);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Stream<QuerySnapshot> getCreatorApplications(String creatorId) {
    return _db
        .collection('applications')
        .where('creatorId', isEqualTo: creatorId)
        .snapshots();
  }

  Future<void> markChatAsRead(String chatId, String role) async {
    try {
      if (role == 'Brand') {
        await _db.collection('chats').doc(chatId).set({
          'unreadByBrand': false,
        }, SetOptions(merge: true));
      } else if (role == 'Creator') {
        await _db.collection('chats').doc(chatId).set({
          'unreadByCreator': false,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Avertisment la marcarea chatului ca citit: $e");
    }
  }

  Stream<DocumentSnapshot> getChatDocument(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots();
  }

  Future<void> applyToCampaign(Map<String, dynamic> data) async {
    await _db.collection('applications').add(data);

    String campaignId = data['campaignId'] ?? '';
    String creatorId = data['creatorId'] ?? '';
    String message = data['message'] ?? '';
    String chatId = "${campaignId}_$creatorId";

    if (message.trim().isNotEmpty) {
      await sendMessage(chatId, creatorId, message, "Creator");
    }
  }

  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text,
    String senderRole,
  ) async {
    if (text.trim().isEmpty) return;

    List<String> parts = chatId.split('_');
    String campaignId = parts[0];
    String creatorId = parts[1];

    var campDoc = await _db.collection('campaigns').doc(campaignId).get();
    String brandId = campDoc.exists ? (campDoc.data()?['brandId'] ?? '') : '';

    Timestamp currentTime = Timestamp.now();

    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': currentTime,
    });

    await _db.collection('chats').doc(chatId).set({
      'lastMessage': text.trim(),
      'lastMessageTime':
          currentTime, // 🔴 FIX: Înlocuit FieldValue.serverTimestamp()
      'unreadByBrand': senderRole == 'Creator',
      'unreadByCreator': senderRole == 'Brand',
      'campaignId': campaignId,
      'creatorId': creatorId,
      'brandId': brandId,
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getBrandChats(String brandId) {
    return _db
        .collection('chats')
        .where('brandId', isEqualTo: brandId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}
