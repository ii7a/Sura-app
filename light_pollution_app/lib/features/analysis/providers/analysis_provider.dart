import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/bortle_scale.dart';
import '../models/analysis_result.dart';
import '../services/image_analysis_service.dart';
import '../services/bortle_classifier.dart';
import '../services/ml_analysis_service.dart';
import '../services/dart_ml_service.dart';

enum AnalysisStatus { idle, analyzing, done, error }

class AnalysisState {
  const AnalysisState({
    this.status = AnalysisStatus.idle,
    this.result,
    this.imagePath,
    this.errorMessage,
  });

  final AnalysisStatus status;
  final AnalysisResult? result;
  final String? imagePath;
  final String? errorMessage;

  AnalysisState copyWith({
    AnalysisStatus? status,
    AnalysisResult? result,
    String? imagePath,
    String? errorMessage,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      result: result ?? this.result,
      imagePath: imagePath ?? this.imagePath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  AnalysisNotifier() : super(const AnalysisState());

  final _picker = ImagePicker();
  final _pixelService = ImageAnalysisService();
  final _classifier = BortleClassifier();
  final _mlService = MlAnalysisService();
  final _dartMlService = DartMlService();

  Future<void> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
    );
    if (picked != null) {
      await _analyzeImage(picked.path);
    }
  }

  Future<void> takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
    );
    if (picked != null) {
      await _analyzeImage(picked.path);
    }
  }

  Future<void> _analyzeImage(String path) async {
    state = AnalysisState(
      status: AnalysisStatus.analyzing,
      imagePath: path,
    );

    try {
      // Run Dart ML, TFLite ML, and pixel analysis in parallel
      final futures = await Future.wait([
        _dartMlService.analyzeImage(path),
        _mlService.analyzeImage(path),
        _pixelService.analyzeImage(path),
      ]);

      final dartMlScore = futures[0] as int;
      final tfliteScore = futures[1] as int;
      final metrics = futures[2] as AnalysisMetrics;

      // Prefer Dart ML (works on all platforms), fall back to TFLite
      final mlScore = dartMlScore >= 0 ? dartMlScore : tfliteScore;

      // Get heuristic score (old system was 0=clean, 100=polluted)
      // We need to invert it: new scale is 0=polluted, 100=clean
      final heuristicResult = _classifier.classify(metrics, path);
      final heuristicScore = 100 - heuristicResult.pollutionLevel;

      // If ML model unavailable (-1), use heuristic only
      int hybridScore;
      if (mlScore < 0) {
        hybridScore = heuristicScore.clamp(0, 100);
      } else {
        hybridScore = ((mlScore * 0.7) + (heuristicScore * 0.3))
            .round()
            .clamp(0, 100);
      }

      // Hard caps for non-stargazing conditions:

      // 1. Obviously daytime (very bright)
      if (metrics.meanBrightness > 0.45) {
        hybridScore = hybridScore.clamp(0, 5);
      }
      // 2. Sunset/twilight: warm orange light (low blue) with bright spots
      else if (metrics.blueRatio < 0.25 && metrics.brightPixelRatio > 0.02) {
        hybridScore = hybridScore.clamp(0, 10);
      }
      // 3. Moderate brightness with warm tones → twilight
      else if (metrics.meanBrightness > 0.30 && metrics.blueRatio < 0.28) {
        hybridScore = hybridScore.clamp(0, 15);
      }
      // 4. High brightness but neutral/blue color → overcast or bright sky
      else if (metrics.meanBrightness > 0.35) {
        hybridScore = hybridScore.clamp(0, 20);
      }

      // Map hybrid score to Bortle (inverted: 100=Bortle1, 0=Bortle9)
      final bortleValue = (((100 - hybridScore) / 100.0) * 8 + 1)
          .round()
          .clamp(1, 9);
      final bortleClass = BortleClass.fromValue(bortleValue);

      // Get 3-class classification from TFLite model.
      // If TFLite didn't run (e.g. simulator), derive from final score.
      var classification = _mlService.lastClassification;
      if (classification == null && mlScore >= 0) {
        // Derive classification from hybrid score
        if (hybridScore >= 60) {
          classification = MlClassificationResult(
            highProb: 0.05,
            lowProb: 0.80,
            moderateProb: 0.15,
          );
        } else if (hybridScore >= 30) {
          classification = MlClassificationResult(
            highProb: 0.15,
            lowProb: 0.15,
            moderateProb: 0.70,
          );
        } else {
          classification = MlClassificationResult(
            highProb: 0.75,
            lowProb: 0.05,
            moderateProb: 0.20,
          );
        }
      }

      final result = AnalysisResult(
        skyQuality: hybridScore,
        bortleClass: bortleClass,
        metrics: metrics,
        imagePath: path,
        mlScore: mlScore < 0 ? null : mlScore,
        heuristicScore: heuristicScore,
        mlClassification: classification,
      );

      state = AnalysisState(
        status: AnalysisStatus.done,
        result: result,
        imagePath: path,
      );
    } catch (e) {
      state = AnalysisState(
        status: AnalysisStatus.error,
        imagePath: path,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const AnalysisState();
  }

  @override
  void dispose() {
    _mlService.dispose();
    super.dispose();
  }
}

final analysisProvider =
    StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier();
});
