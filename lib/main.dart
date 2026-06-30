import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/brand/brand_dashboard.dart';
import 'screens/creator/creator_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB-BhIIk60e_vY_uTUke76t678y_O5FLNU",
        authDomain: "flutter-test4-9849c.firebaseapp.com",
        projectId: "flutter-test4-9849c",
        storageBucket: "flutter-test4-9849c.firebasestorage.app",
        messagingSenderId: "141870563500",
        appId: "1:141870563500:web:31e7e208a5c5f564ca9f09",
        measurementId: "G-T4DWY74TGQ",
      ),
    );
    print(" Firebase s-a inițializat cu succes!");
  } catch (e) {
    print(" AVERTISMENT FIREBASE (Aplicația pornește oricum): $e");
  }

  runApp(NetCreatorApp());
}

class NetCreatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetCreator',
      themeMode: ThemeMode.light, //
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFFD2E6FF), //
        // Stilul barei de sus (AppBar)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD2E6FF),
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: const Color(0xFF0F172A).withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE3F0FF),
          selectedColor: const Color(0xFF0F172A),
          labelStyle: const TextStyle(color: Color(0xFF0F172A)),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),

        // Configurarea formularelor și câmpurilor de text
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          hintStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black12, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black12, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
          ),
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          titleMedium: TextStyle(color: Colors.black),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF0F172A),
          unselectedItemColor: Colors.black38,
          elevation: 10,
        ),
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
