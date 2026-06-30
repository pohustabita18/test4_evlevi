import 'package:flutter/material.dart';
import 'browse_campaigns_tab.dart';
import 'creator_profile_tab.dart';
import 'my_applications_tab.dart';

class CreatorDashboard extends StatefulWidget {
  @override
  _CreatorDashboardState createState() => _CreatorDashboardState();
}

class _CreatorDashboardState extends State<CreatorDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    BrowseCampaignsTab(),
    MyApplicationsTab(),
    CreatorProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NetCreator - Creator'),
        backgroundColor: const Color(0xFFD2E6FF),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),

        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0F172A),
        unselectedItemColor: Colors.black38,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explorează',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'Aplicații',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
