import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

class LikesVisibilityPage extends ConsumerWidget {
  const LikesVisibilityPage({super.key, required this.currentValue});

  final String currentValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.textPrimary;
    final subColor = isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary;

    final options = [
      ('everyone', l10n.everyone),
      ('onlyMe', l10n.onlyMe),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1720) : AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.likesVisibilityTitle,
          style: font(color: isDark ? AppColors.white : AppColors.navy, fontSize: 18.0, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Text(
              l10n.likesVisibilityDesc,
              style: font(color: subColor, fontSize: 14),
            ),
          ),
          ...options.map((option) {
            final isSelected = option.$1 == currentValue;
            return ListTile(
              title: Text(
                option.$2,
                style: font(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.navy, size: 22)
                  : Icon(Icons.circle_outlined, color: subColor, size: 22),
              onTap: () async {
                final uid = ref.read(authStateProvider).valueOrNull?.uid;
                if (uid == null) return;
                await FirestoreService().updateUser(uid, {'likesVisibility': option.$1});
                ref.invalidate(currentUserProvider);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
