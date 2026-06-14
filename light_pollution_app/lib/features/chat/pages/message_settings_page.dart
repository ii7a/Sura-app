import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community/pages/blocked_users_page.dart';
import '../../settings/pages/dm_settings_page.dart';

/// Hub shown when the gear icon on the Messages inbox is tapped. Currently
/// exposes DM-privacy only, but is laid out as a list so future toggles
/// (read receipts, quality filter) can slot in without rework.
class MessageSettingsPage extends ConsumerWidget {
  const MessageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    final bgColor = isDark ? const Color(0xFF0E1720) : AppColors.white;
    final cardColor = isDark ? const Color(0xFF1A2530) : AppColors.cardBg;
    final textColor = isDark ? AppColors.white : AppColors.textPrimary;
    final subColor = isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary;
    final divColor = isDark ? const Color(0xFF2A3540) : AppColors.divider;

    final dmSetting = currentUser?.dmSetting ?? 'everyone';
    String dmSubtitle;
    switch (dmSetting) {
      case 'followers':
        dmSubtitle = l10n.followersOnly;
        break;
      case 'none':
        dmSubtitle = l10n.noOne;
        break;
      default:
        dmSubtitle = l10n.everyone;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.directMessages,
          style: font(
            color: isDark ? AppColors.white : AppColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Container(
            color: cardColor,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DmSettingsPage(currentValue: dmSetting),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: subColor, size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.directMessages,
                            style: font(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dmSubtitle,
                            style: font(color: subColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: subColor),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, indent: 56, color: divColor),
          Container(
            color: cardColor,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BlockedUsersPage(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.block, color: subColor, size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Blocked accounts',
                        style: font(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: subColor),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, indent: 56, color: divColor),
        ],
      ),
    );
  }
}
