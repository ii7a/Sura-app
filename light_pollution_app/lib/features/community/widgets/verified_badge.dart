import 'package:flutter/material.dart';

/// Verified badge icon.
/// Gold for admin accounts, blue for premium accounts.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 16, this.isAdmin = false});

  final double size;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      color: isAdmin ? const Color(0xFFFFD700) : const Color(0xFF1DA1F2),
      size: size,
    );
  }
}
