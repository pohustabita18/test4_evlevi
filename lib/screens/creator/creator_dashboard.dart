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
      // Fundalul Baby Blue se aplică automat pe Scaffold din tema globală
      appBar: AppBar(
        title: const Text('NetCreator - Creator'),
        backgroundColor: const Color(
          0xFFD2E6FF,
        ), // 🔴 NOU: Asortat perfect cu Baby Blue din fundal
        foregroundColor: const Color(
          0xFF0F172A,
        ), // Text titlu albastru închis regal
        elevation: 0,
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),

        // 🔴 REPROIECTAT: Culorile barei de navigare inferioare pentru Creator
        backgroundColor: Colors.white, // Fundal alb curat pentru meniu
        selectedItemColor: const Color(
          0xFF0F172A,
        ), // Pictograma activă devine albastru închis
        unselectedItemColor:
            Colors.black38, // Pictogramele inactive devin gri-negru discret
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        showUnselectedLabels: true,
        type: BottomNavigationBarType
            .fixed, // Împiedică mișcările ciudate ale iconițelor la apăsare

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
