import 'package:flutter/material.dart';
import 'brand_applications_tab.dart'; // 🔴 NOU: Importul noii pagini de aplicații
import 'brand_profile_tab.dart';
import 'manage_campaigns_tab.dart';

class BrandDashboard extends StatefulWidget {
  @override
  _BrandDashboardState createState() => _BrandDashboardState();
}

class _BrandDashboardState extends State<BrandDashboard> {
  int _currentIndex = 0;

  // 🔴 NOU: Am integrat BrandApplicationsTab() pe poziția din mijloc
  final List<Widget> _tabs = [
    ManageCampaignsTab(),
    BrandApplicationsTab(),
    BrandProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NetCreator - Brand')),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.purple[900],
        unselectedItemColor: Colors.grey[600],
        items: [
          // Cele 3 butoane din bara de jos
          const BottomNavigationBarItem(
            icon: Icon(Icons.business_center),
            label: 'Campanii',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment_ind_outlined),
            label: 'Aplicații primite',
          ), // 🔴 NOU
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
