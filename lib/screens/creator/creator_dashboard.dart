import 'package:flutter/material.dart';
import 'browse_campaigns_tab.dart';
import 'creator_profile_tab.dart';
import 'my_applications_tab.dart'; // 🔴 NOU: Importul paginii noi

class CreatorDashboard extends StatefulWidget {
  @override
  _CreatorDashboardState createState() => _CreatorDashboardState();
}

class _CreatorDashboardState extends State<CreatorDashboard> {
  int _currentIndex = 0;

  // 🔴 NOU: Am adăugat MyApplicationsTab() în mijlocul listei de tab-uri
  final List<Widget> _tabs = [
    BrowseCampaignsTab(),
    MyApplicationsTab(),
    CreatorProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NetCreator - Creator')),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explorează',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'Aplicații',
          ), // 🔴 NOU
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
