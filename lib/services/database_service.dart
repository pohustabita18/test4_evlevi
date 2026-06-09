import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

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

  // Trimite un mesaj în chat (folosit de versiunea care setează și flag-uri de necitit)

  // Ascultă mesajele în timp real dintr-o conversație
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true) // Cele mai noi mesaje jos
        .snapshots();
  }

  // --- ADAUGĂ ACEASTĂ FUNCȚIE ÎN CLASA DATABASE_SERVICE ---
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
  // --- ADAUGĂ ACEASTĂ FUNCȚIE ÎN CLASA DATABASE_SERVICE ---
  // (Asigură-te că ai importul: import 'dart:typed_list'; la începutul fișierului)

  Future<String> uploadBytes(String path, Uint8List bytes) async {
    Reference ref = _storage.ref().child(path);
    UploadTask uploadTask = ref.putData(
      bytes,
    ); // Încarcă datele brute (compatibil Web)
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
  // --- MODIFICĂ SAU ADAUGĂ ACESTE METODE ÎN DATABASE_SERVICE ---

  // Aduce toate aplicațiile trimise de un anumit Creator (ordonate după cele mai noi)
  Stream<QuerySnapshot> getCreatorApplications(String creatorId) {
    return _db
        .collection('applications')
        .where('creatorId', isEqualTo: creatorId)
        .snapshots();
  }

  // Trimite un mesaj în chat și setează notificarea de NE-CITIT în funcție de rol
  // (Removed duplicate simple sendMessage — consolidated implementation lower in file)

  // Șterge notificarea de mesaj necitit când utilizatorul deschide chatul
  // 🔴 ÎNLOCUIEȘTE COMPLET METODA MARKCHATASREAD CU ACEASTA ÎN DATABASE_SERVICE.DART:

  Future<void> markChatAsRead(String chatId, String role) async {
    try {
      if (role == 'Brand') {
        // 🔴 FIX: Schimbat din .update() în .set() cu merge: true pentru a preveni crash-ul
        await _db.collection('chats').doc(chatId).set({
          'unreadByBrand': false,
        }, SetOptions(merge: true));
      } else if (role == 'Creator') {
        // 🔴 FIX: Schimbat din .update() în .set() cu merge: true pentru a preveni crash-ul
        await _db.collection('chats').doc(chatId).set({
          'unreadByCreator': false,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Avertisment la marcarea chatului ca citit: $e");
    }
  }

  // Ascultă un document specific de chat pentru a urmări notificările în timp real
  Stream<DocumentSnapshot> getChatDocument(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots();
  }
  // --- ÎNLOCUIEȘTE SAU ADAUGĂ ACESTE METODE ÎN CLASA DATABASE_SERVICE ---

  // 🔴 ÎNLOCUIEȘTE ACESTE METODE ÎN CLASA DATABASE_SERVICE:

  // Salvare aplicație + generare automată chat stabil
  Future<void> applyToCampaign(Map<String, dynamic> data) async {
    // 1. Salvăm aplicația în colecția ei dedicată
    await _db.collection('applications').add(data);

    // 2. Extragem datele ca să creăm automat și o sesiune de chat stabilă în Inbox
    String campaignId = data['campaignId'] ?? '';
    String creatorId = data['creatorId'] ?? '';
    String message = data['message'] ?? '';
    String chatId = "${campaignId}_$creatorId";

    if (message.trim().isNotEmpty) {
      // Îi trimitem brandului mesajul de aplicație direct în chat-ul lui global
      await sendMessage(chatId, creatorId, message, "Creator");
    }
  }

  // Trimitere mesaj optimizată cu Timestamp stabil (Fără bug-ul de 3 secunde)
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

    // Generăm un timestamp stabil pe loc
    Timestamp currentTime = Timestamp.now(); // 🔴 FIX

    // Adăugăm mesajul în istoric
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': currentTime,
    });

    // Actualizăm documentul principal pentru Inbox
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

  // 🔴 NOU: Aduce toate chaturile care aparțin brandului curent, sortate după cele mai recente
  Stream<QuerySnapshot> getBrandChats(String brandId) {
    return _db
        .collection('chats')
        .where('brandId', isEqualTo: brandId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}
