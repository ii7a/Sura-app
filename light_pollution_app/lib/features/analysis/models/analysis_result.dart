import 'dart:ui';
import '../../../core/constants/bortle_scale.dart';

class AnalysisMetrics {
  const AnalysisMetrics({
    required this.meanBrightness,
    required this.medianBrightness,
    required this.brightPixelRatio,
    required this.darkPixelRatio,
    required this.blueRatio,
    required this.orangeRatio,
    required this.brightnessStdDev,
    required this.brightnessHistogram,
    this.meanR = 0,
    this.meanG = 0,
    this.meanB = 0,
    this.grayPixelRatio = 0,
  });

  final double meanBrightness;
  final double medianBrightness;
  final double brightPixelRatio;
  final double darkPixelRatio;
  final double blueRatio;
  final double orangeRatio;
  final double brightnessStdDev;
  final List<int> brightnessHistogram; // 256 bins
  final double meanR;
  final double meanG;
  final double meanB;

  /// Ratio of gray (low-saturation, moderate-brightness) pixels.
  /// High values indicate clouds or overcast conditions.
  final double grayPixelRatio;
}

/// Classification result from the Sura 3-class TFLite model.
enum MlPollutionClass { high, low, moderate }

class MlClassificationResult {
  const MlClassificationResult({
    required this.highProb,
    required this.lowProb,
    required this.moderateProb,
  });

  /// Class 0: HIGH light pollution (Bortle 7-9)
  final double highProb;
  /// Class 1: LOW light pollution (Bortle 1-3)
  final double lowProb;
  /// Class 2: Moderate light pollution (Bortle 4-6)
  final double moderateProb;

  MlPollutionClass get winnerClass {
    if (lowProb >= highProb && lowProb >= moderateProb) return MlPollutionClass.low;
    if (moderateProb >= highProb && moderateProb >= lowProb) return MlPollutionClass.moderate;
    return MlPollutionClass.high;
  }

  double get winnerConfidence {
    switch (winnerClass) {
      case MlPollutionClass.high: return highProb;
      case MlPollutionClass.low: return lowProb;
      case MlPollutionClass.moderate: return moderateProb;
    }
  }
}

class AnalysisResult {
  const AnalysisResult({
    required this.skyQuality,
    required this.bortleClass,
    required this.metrics,
    required this.imagePath,
    this.mlScore,
    this.heuristicScore,
    this.mlClassification,
  });

  /// Sky quality score:
  /// 0 = heavy light pollution (worst)
  /// 100 = pristine dark sky (best)
  final int skyQuality;
  final BortleClass bortleClass;
  final AnalysisMetrics metrics;
  final String imagePath;

  /// ML model score (0-100, same scale)
  final int? mlScore;

  /// Heuristic pixel analysis score (0-100, same scale)
  final int? heuristicScore;

  /// 3-class classification from Sura model
  final MlClassificationResult? mlClassification;

  // Keep old name for backward compat in UI
  int get pollutionLevel => skyQuality;

  /// Whether the sky is cloudy or overcast.
  /// Only true when gray/low-saturation pixels indicate actual clouds.
  bool get isCloudy =>
      metrics.grayPixelRatio > 0.15 && metrics.meanBrightness > 0.12;

  String get qualityLabel {
    if (isCloudy && skyQuality < 25) return 'Cloudy / Overcast';
    if (skyQuality >= 90) return 'Pristine Dark Sky';
    if (skyQuality >= 75) return 'Dark Sky';
    if (skyQuality >= 60) return 'Rural Sky';
    if (skyQuality >= 45) return 'Suburban Sky';
    if (skyQuality >= 30) return 'Bright Suburban';
    if (skyQuality >= 15) return 'Urban Sky';
    return 'Inner City Sky';
  }

  // Keep old name for backward compat
  String get pollutionLabel => qualityLabel;

  Color get qualityColor {
    // Green (good/clean) → Red (bad/polluted)
    if (skyQuality >= 90) return const Color(0xFF00C853); // Bright green
    if (skyQuality >= 75) return const Color(0xFF66BB6A); // Green
    if (skyQuality >= 60) return const Color(0xFF8BC34A); // Light green
    if (skyQuality >= 45) return const Color(0xFFFFEB3B); // Yellow
    if (skyQuality >= 30) return const Color(0xFFFF9800); // Orange
    if (skyQuality >= 15) return const Color(0xFFFF5722); // Deep orange
    return const Color(0xFFF44336); // Red
  }

  // Keep old name for backward compat
  Color get pollutionColor => qualityColor;

  /// Stargazing recommendation based on sky quality score.
  String get stargazingVerdict {
    if (skyQuality >= 80) return 'Excellent for stargazing! Milky Way should be visible.';
    if (skyQuality >= 60) return 'Good for stargazing. Many stars and constellations visible.';
    if (skyQuality >= 45) return 'Decent for stargazing. Bright stars and planets visible.';
    if (skyQuality >= 30) return 'Poor for stargazing. Only the brightest stars visible.';
    if (skyQuality >= 15) return 'Very poor for stargazing. Only a few stars visible.';
    if (isCloudy) return 'Not suitable for stargazing. Sky is cloudy or overcast.';
    return 'Not suitable for stargazing. Too much light pollution.';
  }

  /// Icon for stargazing verdict.
  bool get isGoodForStargazing => skyQuality >= 45;
}
