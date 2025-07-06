import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'form_entry_screen.dart';
import 'package:uuid/uuid.dart';
import '../utils/lenient_snackbar.dart';
import '../utils/lenient_refresh_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Expanded(
            child: LenientRefreshIndicator(
              onRefresh: () async {
                // TODO: Add logic to refresh home screen data from Supabase if needed.
                // LenientSnackbar.showSuccess(context, 'Data refreshed');
              },
              successMessage: null,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _FormCard(title: 'Form 1', onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FormEntryScreen()),
                    );
                  }),
                  const SizedBox(height: 16),
                  _FormCard(title: 'Form 2', onTap: () async {
                    LenientSnackbar.showWarning(context, 'Form 2 is not implemented yet');
                  }),
                  const SizedBox(height: 16),
                  _FormCard(title: 'Form 3', onTap: () async {
                    LenientSnackbar.showWarning(context, 'Form 3 is not implemented yet');
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _FormCard({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1.5,
      color: Colors.white,
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF222222),
            fontFamily: 'Poppins',
          ),
        ),
        trailing: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(3.1416),
          child: SvgPicture.asset(
            'assets/right-arrow-icon.svg',
            height: 24,
            width: 24,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
} 