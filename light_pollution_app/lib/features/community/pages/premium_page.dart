import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/verified_badge.dart';

/// Read-only info page about the "Verified" status. Admins grant the flag
/// directly in Firestore — this page exists so users understand what
/// verification unlocks; there is no in-app application flow.
class PremiumPage extends ConsumerWidget {
  const PremiumPage({super.key});

  static const _verifiedBlue = Color(0xFF1DA1F2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isVerified = currentUser?.isVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Badge icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _verifiedBlue.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: _verifiedBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.verified, color: _verifiedBlue, size: 48),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              l10n.premiumTitle,
              style: font(
                color: AppColors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.premiumSubtitle,
              style: font(
                color: Colors.white60,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Status banner
            if (isVerified) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _verifiedBlue.withValues(alpha: 0.25),
                      _verifiedBlue.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _verifiedBlue.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const VerifiedBadge(size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.premiumMemberSince,
                            style: font(
                              color: _verifiedBlue,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentUser?.name ?? '',
                            style: font(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.premiumYourBenefits,
                  style: font(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Feature cards
            _FeatureCard(
              accent: _verifiedBlue,
              icon: Icons.explore,
              title: l10n.premiumFeatureTrips,
              description: l10n.premiumFeatureTripsDesc,
              isUnlocked: isVerified,
            ),
            const SizedBox(height: 14),
            _FeatureCard(
              accent: _verifiedBlue,
              icon: Icons.verified,
              title: l10n.premiumFeatureBadge,
              description: l10n.premiumFeatureBadgeDesc,
              isUnlocked: isVerified,
            ),
            const SizedBox(height: 14),
            _FeatureCard(
              accent: _verifiedBlue,
              icon: Icons.bookmark_added,
              title: l10n.premiumFeaturePriority,
              description: l10n.premiumFeaturePriorityDesc,
              isUnlocked: isVerified,
            ),
            const SizedBox(height: 14),
            _FeatureCard(
              accent: _verifiedBlue,
              icon: Icons.auto_awesome,
              title: l10n.premiumFeatureAnalysis,
              description: l10n.premiumFeatureAnalysisDesc,
              isUnlocked: isVerified,
            ),

            // Contact message for non-verified users (no apply button)
            if (!isVerified) ...[
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.info_outline, color: _verifiedBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.premiumContactSupport,
                        style: font(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    this.isUnlocked = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: font(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: font(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            Icon(Icons.check_circle, color: accent, size: 22),
        ],
      ),
    );
  }
}
