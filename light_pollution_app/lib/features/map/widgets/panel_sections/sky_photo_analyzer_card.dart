import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import 'package:light_pollution_app/core/l10n/bortle_l10n.dart';
import '../../../../core/theme/panel_theme.dart';
import '../../../../core/widgets/circular_gauge.dart';
import '../../../analysis/models/analysis_result.dart';
import '../../../analysis/services/image_analysis_service.dart';
import '../../../analysis/services/bortle_classifier.dart';

class SkyPhotoAnalyzerCard extends ConsumerStatefulWidget {
  const SkyPhotoAnalyzerCard({super.key});

  @override
  ConsumerState<SkyPhotoAnalyzerCard> createState() => _SkyPhotoAnalyzerCardState();
}

class _SkyPhotoAnalyzerCardState extends ConsumerState<SkyPhotoAnalyzerCard> {
  bool _expanded = false;
  bool _analyzing = false;
  AnalysisResult? _result;
  String? _imagePath;

  Future<void> _pickAndAnalyze() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
    if (picked == null) return;

    setState(() {
      _analyzing = true;
      _imagePath = picked.path;
    });

    try {
      final service = ImageAnalysisService();
      final classifier = BortleClassifier();
      final metrics = await service.analyzeImage(picked.path);
      final result = classifier.classify(metrics, picked.path);
      setState(() {
        _result = result;
        _analyzing = false;
        _expanded = true;
      });
    } catch (e) {
      setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PanelStyle.cardPadding),
      decoration: PanelStyle.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.camera_alt_outlined, color: PanelColors.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.skyPhotoAnalyzer,
                    style: font(
                      color: PanelColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: PanelColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            if (_result == null && !_analyzing)
              GestureDetector(
                onTap: _pickAndAnalyze,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: PanelColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: PanelColors.accent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: PanelColors.accent, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        l10n.uploadSkyPhoto,
                        style: font(
                          color: PanelColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        l10n.tapToSelect,
                        style: font(
                          color: PanelColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_analyzing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    color: PanelColors.accent,
                    strokeWidth: 2,
                  ),
                ),
              ),
            if (_result != null) ...[
              if (_imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_imagePath!),
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: CircularGauge(
                  value: _result!.skyQuality.toDouble(),
                  maxValue: 100,
                  size: 100,
                  strokeWidth: 8,
                  label: l10n.skyQuality,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                    label: l10n.avgBrightness,
                    value: '${(_result!.metrics.meanBrightness * 100).round()}%',
                  ),
                  _StatChip(
                    label: l10n.darkPixels,
                    value: '${(_result!.metrics.darkPixelRatio * 100).round()}%',
                  ),
                  _StatChip(
                    label: l10n.warmGlow,
                    value: '${(_result!.metrics.orangeRatio * 100).round()}%',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    l10n.skyColor,
                    style: font(
                      color: PanelColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                        255,
                        _result!.metrics.meanR.round().clamp(0, 255),
                        _result!.metrics.meanG.round().clamp(0, 255),
                        _result!.metrics.meanB.round().clamp(0, 255),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: PanelColors.cardBorder),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.bortleValue(_result!.bortleClass.value)} — ${_result!.bortleClass.localizedName(l10n)}',
                    style: font(
                      color: PanelColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _result = null;
                      _imagePath = null;
                    });
                  },
                  child: Text(
                    l10n.analyzeAnotherPhoto,
                    style: font(
                      color: PanelColors.accent,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return Column(
      children: [
        Text(
          value,
          style: font(
            color: PanelColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: font(
            color: PanelColors.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
