import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/brand/brand_dashboard.dart';
import 'screens/creator/creator_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

// Notificator global pentru starea Dark Mode
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔴 FIX: Împachetăm inițializarea în try-catch pentru a opri eroarea de web_entrypoint
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey:
            "AIzaSyB-BhIIk60e_vY_uTuKe76t678y_O5FLNU", // Am asigurat potrivirea caracterelor case-sensitive
        authDomain: "flutter-test4-9849c.firebaseapp.com",
        projectId: "flutter-test4-9849c",
        storageBucket: "flutter-test4-9849c.firebasestorage.app",
        messagingSenderId: "141870563500",
        appId: "1:141870563500:web:2978a8d837a3b545ca9f09",
        measurementId: "G-H96N4JBWEN",
      ),
    );
    print("✅ Firebase s-a inițializat cu succes!");
  } catch (e) {
    print("🔴 AVERTISMENT FIREBASE (Aplicația pornește oricum): $e");
  }

  runApp(NetCreatorApp());
}

class NetCreatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'NetCreator',
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            primarySwatch: Colors.indigo,
            scaffoldBackgroundColor: Colors.white,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.indigo,
            brightness: Brightness.dark,
          ),
          home: AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
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
