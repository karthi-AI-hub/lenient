import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9FB),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 32),
          _DownloadCard(title: 'Form 1'),
          const SizedBox(height: 16),
          _DownloadCard(title: 'Form 2'),
          const SizedBox(height: 16),
          _DownloadCard(title: 'Form 3'),
        ],
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final String title;
  const _DownloadCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1.5,
      color: Colors.white,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SvgPicture.asset(
              'assets/file-icon.svg',
              height: 28,
              width: 28,
              color: const Color(0xFF2F2F2F),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: const Color(0xFF222222),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Container(
            height: 56,
            width: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF7ED957),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/fill-download-icon.svg',
                height: 28,
                width: 28,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 