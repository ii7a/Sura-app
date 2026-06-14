import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.textPrimary;
    final subColor = isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary;

    final sections = [
      (l10n.termsSection1Title, l10n.termsSection1Body),
      (l10n.termsSection2Title, l10n.termsSection2Body),
      (l10n.termsSection3Title, l10n.termsSection3Body),
      (l10n.termsSection4Title, l10n.termsSection4Body),
      (l10n.termsSection5Title, l10n.termsSection5Body),
      (l10n.termsSection6Title, l10n.termsSection6Body),
      (l10n.termsSection7Title, l10n.termsSection7Body),
      (l10n.termsSection8Title, l10n.termsSection8Body),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1720) : AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.termsOfServiceTitle,
          style: font(color: isDark ? AppColors.white : AppColors.navy, fontSize: 18.0, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.termsLastUpdated,
            style: font(color: subColor, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ...sections.expand((section) => [
            Text(
              section.$1,
              style: font(color: textColor, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              section.$2,
              style: font(color: textColor, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 20),
          ]),
        ],
      ),
    );
  }
}
