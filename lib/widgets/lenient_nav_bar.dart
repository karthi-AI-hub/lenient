import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LenientNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const LenientNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Colors.white,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFB6F5B6), // light green highlight
      unselectedItemColor: Colors.black,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/home-icon.svg',
            color: currentIndex == 0 ? const Color(0xFFB6F5B6) : Colors.black,
            height: 24,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/form-icon.svg',
            color: currentIndex == 1 ? const Color(0xFFB6F5B6) : Colors.black,
            height: 24,
          ),
          label: 'Forms',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/download-icon.svg',
            color: currentIndex == 2 ? const Color(0xFFB6F5B6) : Colors.black,
            height: 24,
          ),
          label: 'Download',
        ),
      ],
    );
  }
} 