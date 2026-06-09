import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/brand/brand_dashboard.dart';
import 'screens/creator/creator_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Aici am adăugat configurația ta web exactă din consolă
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB-BhIIk60e_vY_uTUke76t678y_O5FLNU",
      authDomain: "flutter-test4-9849c.firebaseapp.com",
      projectId: "flutter-test4-9849c",
      storageBucket: "flutter-test4-9849c.firebasestorage.app",
      messagingSenderId: "141870563500",
      appId: "1:141870563500:web:2978a8d837a3b545ca9f09",
      measurementId: "G-H96N4JBWEN",
    ),
  );

  runApp(NetCreatorApp());
}

class NetCreatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Corectat din BuildConlext
    return MaterialApp(
      title: 'NetCreator', // Corectat din lille
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<String>(
            future: _auth.getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              String role = roleSnapshot.data ?? 'Creator';
              if (role == 'Brand') return BrandDashboard();
              if (role == 'Admin') return AdminDashboard();
              return CreatorDashboard();
            },
          );
        }
        return LoginScreen();
      },
    );
  }
}
