import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';

enum PlaceholderTitle { search, chat }

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.titleKey, required this.icon});

  final PlaceholderTitle titleKey;
  final IconData icon;

  String _localizedTitle(AppLocalizations l10n) {
    switch (titleKey) {
      case PlaceholderTitle.search:
        return l10n.navSearch;
      case PlaceholderTitle.chat:
        return l10n.navChat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final title = _localizedTitle(l10n);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: font(
            color: AppColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.navy.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              l10n.comingSoon,
              style: font(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.underDevelopment(title),
              style: font(
                color: AppColors.textHint,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
