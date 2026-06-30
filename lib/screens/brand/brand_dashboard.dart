import 'package:flutter/material.dart';
import 'brand_applications_tab.dart';
import 'brand_profile_tab.dart';
import 'manage_campaigns_tab.dart';

class BrandDashboard extends StatefulWidget {
  @override
  _BrandDashboardState createState() => _BrandDashboardState();
}

class _BrandDashboardState extends State<BrandDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    ManageCampaignsTab(),
    BrandApplicationsTab(),
    BrandProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NetCreator - Brand'),
        backgroundColor: const Color(0xFFD2E6FF), // Asortat cu Baby Blue global
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),

        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0F172A),
        unselectedItemColor:
            Colors.black38, // Pictogramele inactive devin gri-negru discret
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center),
            label: 'Campanii',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_ind_outlined),
            label: 'Aplicații',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
