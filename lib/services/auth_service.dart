import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
    String role,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return result;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<String> getUserRole(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return (doc.data() as Map<String, dynamic>)['role'] ?? 'Creator';
    }
    return 'Creator';
  }
}
