import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import 'package:light_pollution_app/core/l10n/bortle_l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../community/pages/compose_post_page.dart';
import '../models/analysis_result.dart';
import '../providers/analysis_provider.dart';
import '../widgets/analysis_result_card.dart';
import '../widgets/brightness_histogram.dart';

// Dark colors for the detection/camera page
class _DetectColors {
  static const background = AppColors.dark;
  static const surface = Color(0xFF1A2633);
  static const accent = Color(0xFF4D759E);
  static const textMuted = Color(0xFF8899AA);
  static const textLight = Color(0xFFCCDDEE);
}

class AnalysisPage extends ConsumerWidget {
  const AnalysisPage({super.key});

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);

    return Theme(
      data: AppTheme.darkTheme(Localizations.localeOf(context)),
      child: Scaffold(
        backgroundColor: _DetectColors.background,
        body: SafeArea(
          child: switch (state.status) {
            AnalysisStatus.idle => _buildIdleState(context, ref),
            AnalysisStatus.analyzing => _buildAnalyzingState(context, state),
            AnalysisStatus.done => _buildResultsState(context, ref, state),
            AnalysisStatus.error => _buildErrorState(context, ref, state),
          },
        ),
      ),
    );
  }

  Widget _buildIdleState(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);

    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.expand_less, color: _DetectColors.textMuted, size: 28),
            ],
          ),
        ),

        // Main viewfinder area
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _DetectColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/logo.svg',
                    height: 220,
                    colorFilter: ColorFilter.mode(
                      AppColors.white.withValues(alpha: 0.85),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.pollutionDetection,
                    style: font(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.takeOrUploadPhoto,
                    textAlign: TextAlign.center,
                    style: font(
                      color: _DetectColors.textLight.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Bottom controls - camera style
        Padding(
          padding: const EdgeInsets.only(bottom: 32, left: 40, right: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Gallery button
              GestureDetector(
                onTap: () => ref.read(analysisProvider.notifier).pickFromGallery(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _DetectColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _DetectColors.textMuted, width: 1),
                  ),
                  child: Icon(Icons.photo_library, color: _DetectColors.textLight, size: 22),
                ),
              ),

              // Big PHOTO capture button
              GestureDetector(
                onTap: _isDesktop
                    ? () => ref.read(analysisProvider.notifier).pickFromGallery()
                    : () => ref.read(analysisProvider.notifier).takePhoto(),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.photoButton,
                      style: font(
                        color: _DetectColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Placeholder for symmetry
              const SizedBox(width: 48, height: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingState(BuildContext context, AnalysisState state) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);

    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.expand_less, color: _DetectColors.textMuted, size: 28),
            ],
          ),
        ),

        // Image preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _DetectColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (state.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(state.imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _DetectColors.accent),
                        const SizedBox(height: 16),
                        Text(
                          l10n.analyzing,
                          style: font(color: AppColors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildResultsState(BuildContext context, WidgetRef ref, AnalysisState state) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final result = state.result!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        // Top bar with close
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(analysisProvider.notifier).reset(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _DetectColors.surface,
                  ),
                  child: const Icon(Icons.close, color: AppColors.white, size: 20),
                ),
              ),
              const Spacer(),
              Icon(Icons.expand_less, color: _DetectColors.textMuted, size: 28),
              const Spacer(),
              const SizedBox(width: 36),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                // Image + Result overlay
                SizedBox(
                  height: screenHeight * 0.5,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _DetectColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (state.imagePath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              File(state.imagePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        // Gradient overlay for readability
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.dark.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                        // Result overlay
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(
                                  l10n.skyQualityLabel,
                                  style: font(
                                    color: _DetectColors.textLight.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${result.pollutionLevel}%',
                                  style: font(
                                    color: AppColors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  result.localizedQualityLabel(l10n),
                                  style: font(
                                    color: result.pollutionColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Stargazing verdict
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: result.isGoodForStargazing
                                        ? const Color(0xFF1B5E20).withValues(alpha: 0.6)
                                        : const Color(0xFFB71C1C).withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: result.isGoodForStargazing
                                          ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                                          : const Color(0xFFF44336).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        result.isGoodForStargazing ? Icons.star : Icons.star_border,
                                        color: result.isGoodForStargazing
                                            ? const Color(0xFFFFD54F)
                                            : const Color(0xFFEF9A9A),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          result.localizedStargazingVerdict(l10n),
                                          style: font(
                                            color: AppColors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Bortle scale bar (1-9)
                                _BortleScaleBar(
                                  bortleValue: result.bortleClass.value,
                                ),
                                const SizedBox(height: 16),
                                // Share as Post button
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ComposePostPage(
                                            initialImage: File(state.imagePath!),
                                            analysisResult: result,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.share, size: 18),
                                    label: Text(
                                      l10n.shareAsPost,
                                      style: font(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF4D759E),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Re-examine button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => ref.read(analysisProvider.notifier).reset(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.white,
                                      side: const BorderSide(color: AppColors.navy),
                                    ),
                                    child: Text(
                                      l10n.reExamine,
                                      style: font(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Model classification card
                if (result.mlClassification != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _ModelClassificationCard(
                      classification: result.mlClassification!,
                      l10n: l10n,
                    ),
                  ),

                // Bottom detail section
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AnalysisResultCard(result: result),
                      const SizedBox(height: 8),
                      BrightnessHistogram(histogram: result.metrics.brightnessHistogram),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, AnalysisState state) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);

    return Column(
      children: [
        // Top bar with close
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(analysisProvider.notifier).reset(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _DetectColors.surface,
                  ),
                  child: const Icon(Icons.close, color: AppColors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    l10n.analysisFailed,
                    style: font(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage ?? l10n.unknownError,
                    textAlign: TextAlign.center,
                    style: font(
                      color: _DetectColors.textLight.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => ref.read(analysisProvider.notifier).reset(),
                    child: Text(
                      l10n.reExamine,
                      style: font(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModelClassificationCard extends StatelessWidget {
  const _ModelClassificationCard({
    required this.classification,
    required this.l10n,
  });

  final MlClassificationResult classification;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final winner = classification.winnerClass;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DetectColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            l10n.modelClassification,
            style: font(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          // Three class bars
          _ClassBar(
            label: l10n.lowPollution,
            subtitle: 'Bortle 1-3',
            probability: classification.lowProb,
            color: const Color(0xFF4CAF50),
            isWinner: winner == MlPollutionClass.low,
            icon: Icons.star,
          ),
          const SizedBox(height: 10),
          _ClassBar(
            label: l10n.moderatePollution,
            subtitle: 'Bortle 4-6',
            probability: classification.moderateProb,
            color: const Color(0xFFFFB300),
            isWinner: winner == MlPollutionClass.moderate,
            icon: Icons.star_half,
          ),
          const SizedBox(height: 10),
          _ClassBar(
            label: l10n.highPollution,
            subtitle: 'Bortle 7-9',
            probability: classification.highProb,
            color: const Color(0xFFF44336),
            isWinner: winner == MlPollutionClass.high,
            icon: Icons.star_border,
          ),

          const SizedBox(height: 14),

          // Winner summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _winnerColor(winner).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _winnerColor(winner).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _winnerIcon(winner),
                  color: _winnerColor(winner),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_winnerLabel(winner)} — ${l10n.confidence}: ${(classification.winnerConfidence * 100).toStringAsFixed(1)}%',
                    style: font(
                      color: _winnerColor(winner),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _winnerColor(MlPollutionClass cls) {
    switch (cls) {
      case MlPollutionClass.low: return const Color(0xFF4CAF50);
      case MlPollutionClass.moderate: return const Color(0xFFFFB300);
      case MlPollutionClass.high: return const Color(0xFFF44336);
    }
  }

  IconData _winnerIcon(MlPollutionClass cls) {
    switch (cls) {
      case MlPollutionClass.low: return Icons.star;
      case MlPollutionClass.moderate: return Icons.star_half;
      case MlPollutionClass.high: return Icons.star_border;
    }
  }

  String _winnerLabel(MlPollutionClass cls) {
    switch (cls) {
      case MlPollutionClass.low: return l10n.lowPollution;
      case MlPollutionClass.moderate: return l10n.moderatePollution;
      case MlPollutionClass.high: return l10n.highPollution;
    }
  }
}

class _ClassBar extends StatelessWidget {
  const _ClassBar({
    required this.label,
    required this.subtitle,
    required this.probability,
    required this.color,
    required this.isWinner,
    required this.icon,
  });

  final String label;
  final String subtitle;
  final double probability;
  final Color color;
  final bool isWinner;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final percent = (probability * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$label ($subtitle)',
                style: font(
                  color: isWinner ? AppColors.white : _DetectColors.textMuted,
                  fontSize: 12,
                  fontWeight: isWinner ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: font(
                color: isWinner ? color : _DetectColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: probability,
              backgroundColor: AppColors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                isWinner ? color : color.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BortleScaleBar extends StatelessWidget {
  const _BortleScaleBar({required this.bortleValue});

  final int bortleValue;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    // Position: bortle 1 = left (0.0), bortle 9 = right (1.0)
    final position = (bortleValue - 1) / 8.0;

    return Column(
      children: [
        // Gradient bar with indicator
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final indicatorX = (position * barWidth).clamp(8.0, barWidth - 8.0);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gradient bar
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 10,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4CAF50), // Low (green)
                            Color(0xFF8BC34A),
                            Color(0xFFFFEB3B), // Moderate (yellow)
                            Color(0xFFFF9800),
                            Color(0xFFF44336), // High (red)
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Indicator dot
                  Positioned(
                    left: indicatorX - 8,
                    top: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        border: Border.all(color: _DetectColors.surface, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // Labels: 1-9 with Low/Moderate/High
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1', style: font(color: const Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.w600)),
                Text('Low', style: font(color: _DetectColors.textMuted, fontSize: 9)),
              ],
            ),
            Column(
              children: [
                Text('5', style: font(color: const Color(0xFFFFEB3B), fontSize: 11, fontWeight: FontWeight.w600)),
                Text('Moderate', style: font(color: _DetectColors.textMuted, fontSize: 9)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('9', style: font(color: const Color(0xFFF44336), fontSize: 11, fontWeight: FontWeight.w600)),
                Text('High', style: font(color: _DetectColors.textMuted, fontSize: 9)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
