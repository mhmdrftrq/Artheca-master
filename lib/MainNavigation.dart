import 'package:flutter/material.dart';
import 'package:artheca/Layout/ExplorePage.dart';
import 'package:artheca/Layout/HomePage.dart';
import 'package:artheca/Layout/BookmarkPage.dart'; // Tetap di-import
import 'package:artheca/Layout/ProfilePage.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    HomePage(onViewAll: () {
      setState(() => _selectedIndex = 1);
    }),
    const ExplorePage(),
    const BookmarkPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, 0),
          _navItem(Icons.explore_outlined, 1),
          _navItem(Icons.bookmark_border_rounded, 2), // Ikon Bookmark
          _navItem(Icons.person_outline_rounded, 3),   // Ikon Profile
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50, // Dikecilkan dikit karena sekarang ada 4 menu
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFAC9362) : const Color(0xFF757575),
              size: 22,
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFAC9362)
                ),
              ),
          ],
        ),
      ),
    );
  }
}