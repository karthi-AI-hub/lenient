import 'package:flutter/material.dart';

class LenientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LenientAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF7F9FB),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      centerTitle: true,
      title: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Image.asset(
          'assets/logo.png',
          height: 48,
          fit: BoxFit.contain,
        ),
      ),
      toolbarHeight: 56,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
} 