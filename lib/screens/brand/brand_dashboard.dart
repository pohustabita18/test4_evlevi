import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'brand_profile_tab.dart';
import 'manage_campaigns_tab.dart';

class BrandDashboard extends StatefulWidget {
  @override
  _BrandDashboardState createState() => _BrandDashboardState();
}

class _BrandDashboardState extends State<BrandDashboard> {
  int _currentIndex = 0;

  // Am revenit la cele 2 tab-uri inițiale (fără pagina globală de mesaje)
  final List<Widget> _tabs = [ManageCampaignsTab(), BrandProfileTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NetCreato - Brand')),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.purple[900],
        unselectedItemColor: Colors.grey[600],
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center),
            label: 'Campanii',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
