import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import 'dm_settings_page.dart';
import 'likes_visibility_page.dart';
import 'notification_settings_page.dart';
import 'terms_page.dart';
import 'privacy_policy_page.dart';
import '../../community/pages/blocked_users_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = ref.read(themeProvider.notifier);
    final locale = ref.watch(localeProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    final bgColor = isDark ? const Color(0xFF0E1720) : AppColors.white;
    final cardColor = isDark ? const Color(0xFF1A2530) : AppColors.cardBg;
    final textColor = isDark ? AppColors.white : AppColors.textPrimary;
    final subColor = isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary;
    final divColor = isDark ? const Color(0xFF2A3540) : AppColors.divider;

    // Read settings from user model (with defaults)
    final isPrivate = currentUser?.isPrivate ?? false;
    final pushNotif = currentUser?.pushNotifications ?? true;
    final emailNotif = currentUser?.emailNotifications ?? false;
    final dmSetting = currentUser?.dmSetting ?? 'everyone';
    final likesVis = currentUser?.likesVisibility ?? 'everyone';
    final locationInfo = currentUser?.locationInfo ?? true;

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

    String likesSubtitle;
    switch (likesVis) {
      case 'onlyMe':
        likesSubtitle = l10n.onlyMe;
        break;
      default:
        likesSubtitle = l10n.everyone;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.settingsPrivacy,
          style: font(color: isDark ? AppColors.white : AppColors.navy, fontSize: 18.0, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // ── Appearance ──
          _SectionHeader(title: l10n.appearance, font: font, color: subColor),
          _SettingsTile(
            icon: Icons.dark_mode,
            title: l10n.darkMode,
            subtitle: isDark ? l10n.on : l10n.off,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Switch.adaptive(
              value: isDark,
              activeThumbColor: AppColors.navy,
              onChanged: (_) => themeNotifier.toggleDarkMode(),
            ),
          ),
          Divider(height: 1, indent: 56, color: divColor),
          _SettingsTile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: locale.languageCode == 'ar' ? l10n.arabic : l10n.english,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Icon(Icons.chevron_right, color: subColor),
            onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
          ),

          const SizedBox(height: 20),

          // ── Account ──
          _SectionHeader(title: l10n.account, font: font, color: subColor),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: l10n.email,
            subtitle: firebaseUser?.email ?? l10n.notSet,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
          ),
          Divider(height: 1, indent: 56, color: divColor),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: l10n.changePassword,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Icon(Icons.chevron_right, color: subColor),
            onTap: () => _showChangePassword(context, font, isDark, l10n),
          ),
          Divider(height: 1, indent: 56, color: divColor),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: l10n.privateAccount,
            subtitle: l10n.privateAccountDesc,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Switch.adaptive(
              value: isPrivate,
              activeThumbColor: AppColors.navy,
              onChanged: (_) => _updateSetting(ref, 'isPrivate', !isPrivate),
            ),
          ),

          const SizedBox(height: 20),

          // ── Notifications ──
          _SectionHeader(title: l10n.notifications, font: font, color: subColor),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: l10n.pushNotifications,
            subtitle: l10n.pushNotificationsDesc,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Switch.adaptive(
              value: pushNotif,
              activeThumbColor: AppColors.navy,
              onChanged: (_) => _updateSetting(ref, 'pushNotifications', !pushNotif),
            ),
          ),
          Divider(height: 1, indent: 56, color: divColor),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: l10n.emailNotifications,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Switch.adaptive(
              value: emailNotif,
              activeThumbColor: AppColors.navy,
              onChanged: (_) => _updateSetting(ref, 'emailNotifications', !emailNotif),
            ),
          ),
          Divider(height: 1, indent: 56, color: divColor),
          // Opens the detailed notification-preferences screen (types,
          // cosmic filters, city targeting).
          _SettingsTile(
            icon: Icons.tune,
            title: l10n.notificationSettings,
            subtitle: l10n.notificationSettingsDesc,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Privacy ──
          _SectionHeader(title: l10n.privacy, font: font, color: subColor),
          _SettingsTile(
            icon: Icons.chat_bubble_outline,
            title: l10n.directMessages,
            subtitle: dmSubtitle,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Icon(Icons.chevron_right, color: subColor),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DmSettingsPage(currentValue: dmSetting),
                ),
              );
            },
          ),
          Divider(height: 1, indent: 56, color: divColor),
          _SettingsTile(
            icon: Icons.visibility_outlined,
            title: l10n.whoCanSeeYourLikes,
            subtitle: likesSubtitle,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Icon(Icons.chevron_right, color: subColor),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LikesVisibilityPage(currentValue: likesVis),
                ),
              );
            },
          ),
          Divider(height: 1, indent: 56, color: divColor),
          _SettingsTile(
            icon: Icons.location_off_outlined,
            title: l10n.locationInformation,
            subtitle: l10n.locationInfoDesc,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Switch.adaptive(
              value: locationInfo,
              activeThumbColor: AppColors.navy,
              onChanged: (_) => _updateSetting(ref, 'locationInfo', !locationInfo),
            ),
          ),
          Divider(height: 1, indent: 56, color: divColor),
          _SettingsTile(
            icon: Icons.block,
            title: 'Blocked accounts',
            subtitle: 'Manage who you\'ve blocked',
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Icon(Icons.chevron_right, color: subColor),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BlockedUsersPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Data & Storage ──
          _SectionHeader(title: l10n.dataStorage, font: font, color: subColor),
          _SettingsTile(
            icon: Icons.storage_outlined,
            title: l10n.clearCache,
            subtitle: l10n.clearCacheDesc,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Icon(Icons.chevron_right, color: subColor),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.cacheCleared), backgroundColor: AppColors.navy),
              );
            },
          ),

          const SizedBox(height: 20),

          // ── About ──
          _SectionHeader(title: l10n.about, font: font, color: subColor),
          _SettingsTile(
            icon: Icons.info_outline,
            title: l10n.appVersion,
            subtitle: '1.0.0',
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
          ),
          Divider(height: 1, indent: 56, color: divColor),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: l10n.termsOfService,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Icon(Icons.chevron_right, color: subColor),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsPage()),
              );
            },
          ),
          Divider(height: 1, indent: 56, color: divColor),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            font: font,
            textColor: textColor,
            subColor: subColor,
            cardColor: cardColor,
            trailing: Icon(Icons.chevron_right, color: subColor),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            },
          ),

          const SizedBox(height: 30),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true)
                      .pushNamedAndRemoveUntil('/login', (_) => false);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text(l10n.logout, style: font(color: Colors.red, fontSize: 16.0, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _updateSetting(WidgetRef ref, String field, dynamic value) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    await FirestoreService().updateUser(uid, {field: value});
    ref.invalidate(currentUserProvider);
  }

  void _showChangePassword(BuildContext context, dynamic font, bool isDark, AppLocalizations l10n) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2530) : AppColors.white,
        title: Text(l10n.changePassword, style: font(fontWeight: FontWeight.w700, fontSize: 18.0)),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(hintText: l10n.enterNewPassword),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () async {
              final password = controller.text.trim();
              if (password.length < 6) return;
              try {
                await FirebaseAuth.instance.currentUser?.updatePassword(password);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.passwordUpdated), backgroundColor: AppColors.navy),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedUpdate(e.toString()))),
                  );
                }
              }
            },
            child: Text(l10n.update),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.font, required this.color});
  final String title;
  final dynamic font;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(title, style: font(color: color, fontSize: 13.0, fontWeight: FontWeight.w600)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.font,
    required this.textColor,
    required this.subColor,
    required this.cardColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final dynamic font;
  final Color textColor;
  final Color subColor;
  final Color cardColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: subColor, size: 22),
      title: Text(title, style: font(color: textColor, fontSize: 15.0, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: font(color: subColor, fontSize: 12.0))
          : null,
      trailing: trailing,
      onTap: onTap,
      tileColor: cardColor.withValues(alpha: 0.0),
    );
  }
}
