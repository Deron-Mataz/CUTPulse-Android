import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:google_fonts/google_fonts.dart';
import 'package:cutpulse/screens/home_screen.dart';
import 'package:cutpulse/screens/profile_screen.dart';
import 'package:cutpulse/screens/search_screen.dart';
import 'package:cutpulse/screens/upload_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeScreen(),
      const SearchScreen(),
      const UploadScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 28,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 24,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            if (!isSelected) const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.search, 1),
            _buildNavItem(Icons.add_box_outlined, 2),
            _buildNavItem(Icons.person, 3),
          ],
        ),
      ),
    );
  }
}
