import 'package:flutter/material.dart';
import 'lenient_snackbar.dart';

class LenientRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? successMessage;

  const LenientRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.successMessage,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF7ED957),
      backgroundColor: Colors.white,
      displacement: 32,
      strokeWidth: 3,
      onRefresh: () async {
        await onRefresh();
        if (successMessage != null) {
          LenientSnackbar.showSuccess(context, successMessage!);
        }
      },
      child: child,
    );
  }
} 