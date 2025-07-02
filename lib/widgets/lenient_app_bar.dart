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
      title: Padding(
        padding: const EdgeInsets.only(left: 24, top: 12, bottom: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 48,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
      toolbarHeight: 72,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
} 