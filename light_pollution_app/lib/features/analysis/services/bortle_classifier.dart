import '../../../core/constants/bortle_scale.dart';
import '../models/analysis_result.dart';

class BortleClassifier {
  /// Maps analysis metrics to a pollution level 0-100 using weighted scoring.
  /// 0 = no light pollution (pristine dark sky)
  /// 100 = maximum light pollution (inner city)
  ///
  /// Weights:
  /// - Mean brightness: 35%
  /// - Bright pixel ratio: 20%
  /// - Dark pixel ratio: 15% (inverse)
  /// - Color shift (orange vs blue): 15%
  /// - Brightness uniformity: 15%
  ///
  /// Additionally applies a cloud/daytime penalty when the image
  /// clearly shows overcast or daytime conditions (not a night sky).
  AnalysisResult classify(AnalysisMetrics metrics, String imagePath) {
    // Mean brightness score: 0 = dark, 1 = bright
    final brightnessScore = metrics.meanBrightness.clamp(0.0, 1.0);

    // Bright pixel ratio score: more bright pixels = more pollution
    final brightScore = metrics.brightPixelRatio.clamp(0.0, 1.0);

    // Dark pixel ratio score: more dark pixels = less pollution (inverted)
    final darkScore = (1.0 - metrics.darkPixelRatio).clamp(0.0, 1.0);

    // Color shift: orange-dominant = pollution, blue-dominant = dark sky
    final colorShift = (metrics.orangeRatio - metrics.blueRatio + 0.5).clamp(0.0, 1.0);

    // Uniformity: low std dev in bright image = uniform light pollution
    final uniformity = metrics.meanBrightness > 0.3
        ? (1.0 - metrics.brightnessStdDev).clamp(0.0, 1.0)
        : metrics.brightnessStdDev.clamp(0.0, 1.0);

    // Weighted composite score (0.0 to 1.0)
    final rawScore = (brightnessScore * 0.35 +
            brightScore * 0.20 +
            darkScore * 0.15 +
            colorShift * 0.15 +
            uniformity * 0.15)
        .clamp(0.0, 1.0);

    // === Environment detection: sunset, clouds, daytime ===
    double envPenalty = 0.0;

    // 1. Sunset / warm light detection:
    //    A natural dark sky has blue ratio ~0.33 (neutral).
    //    Sunset/city glow shifts it toward orange (blue < 0.27).
    //    Stars photo: blue ~0.35, sunset: blue ~0.21
    if (metrics.blueRatio < 0.27) {
      final warmth = ((0.27 - metrics.blueRatio) / 0.10).clamp(0.0, 1.0);
      envPenalty += warmth * 0.6;

      // If also has scattered bright pixels → definitely sunset/city lights
      if (metrics.brightPixelRatio > 0.02) {
        envPenalty += 0.3;
      }
    }

    // 2. High brightness → daytime or heavy twilight
    if (metrics.meanBrightness > 0.30) {
      final excess = ((metrics.meanBrightness - 0.30) / 0.20).clamp(0.0, 1.0);
      envPenalty += excess * 0.7;
    }

    // 3. Cloud/overcast: high gray ratio + moderate brightness
    if (metrics.grayPixelRatio > 0.30 && metrics.meanBrightness > 0.20) {
      final excess = ((metrics.grayPixelRatio - 0.30) / 0.30).clamp(0.0, 1.0);
      envPenalty += excess * 0.4;
    }

    // 4. Hard floor for obviously daytime images
    if (metrics.meanBrightness > 0.45) {
      envPenalty = envPenalty < 0.85 ? 0.85 : envPenalty;
    }

    envPenalty = envPenalty.clamp(0.0, 1.0);

    // Apply penalty: push score toward 1.0 (maximum pollution / worst sky)
    final adjustedScore =
        (rawScore + envPenalty * (1.0 - rawScore)).clamp(0.0, 1.0);

    // Map to 0-100 pollution level
    final pollutionLevel = (adjustedScore * 100).round().clamp(0, 100);

    // Also map to Bortle for reference
    final bortleValue = (adjustedScore * 8 + 1).round().clamp(1, 9);
    final bortleClass = BortleClass.fromValue(bortleValue);

    return AnalysisResult(
      skyQuality: pollutionLevel,
      bortleClass: bortleClass,
      metrics: metrics,
      imagePath: imagePath,
    );
  }
}
