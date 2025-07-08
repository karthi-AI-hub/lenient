import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onExit;
  final BuildContext parentContext;
  final List<Permission> missingPermissions;
  const PermissionDialog({
    super.key,
    required this.onRetry,
    required this.onExit,
    required this.parentContext,
    required this.missingPermissions,
  });

  Future<void> _requestAllPermissions() async {
    bool granted = true;
    for (final perm in missingPermissions) {
      final status = await perm.request();
      if (!status.isGranted) granted = false;
    }
    if (granted) {
      Navigator.of(parentContext).pop('retry');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 48, color: Color(0xFF22B14C)),
          const SizedBox(height: 16),
          Text(
            'Permissions Required',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: Color(0xFF22B14C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'To use all features, please grant the required permissions.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Color(0xFF222222),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            icon: Icon(Icons.verified_user, color: Colors.white),
            label: Text(
              'Grant All Permissions',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF22B14C),
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _requestAllPermissions,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF22B14C),
              side: BorderSide(color: Color(0xFF22B14C)),
              minimumSize: Size(double.infinity, 48),
              textStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retry'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onExit,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              textStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
} 