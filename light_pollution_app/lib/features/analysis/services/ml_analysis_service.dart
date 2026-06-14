import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/analysis_result.dart';

/// ML-based sky quality analysis using TensorFlow Lite.
///
/// Uses the Sura 3-class model trained on real sky photos.
/// Output: 3-class softmax [HIGH pollution, LOW pollution, Moderate pollution]
///   Class 0 = HIGH light pollution (Bortle 7-9)
///   Class 1 = LOW light pollution (Bortle 1-3)
///   Class 2 = Moderate light pollution (Bortle 4-6)
///
/// Returns a score from 0 (heavy light pollution) to 100 (pristine dark sky).
class MlAnalysisService {
  Interpreter? _interpreter;
  bool _isLoaded = false;
  bool _loadFailed = false;

  /// Last classification result (3-class probabilities).
  MlClassificationResult? lastClassification;

  /// Load the TFLite model from assets.
  Future<void> loadModel() async {
    if (_isLoaded || _loadFailed) return;

    try {
      _interpreter = await Interpreter.fromAsset('sura_model.tflite');
      _isLoaded = true;
      debugPrint('[Sura ML] Model loaded successfully (3-class)');
    } catch (e) {
      _loadFailed = true;
      debugPrint('[Sura ML] Model load failed: $e');
    }
  }

  /// Preprocess image to float32 array for model input.
  Float32List _preprocessImage(img.Image image) {
    final resized = img.copyResize(image, width: 224, height: 224);
    final input = Float32List(1 * 224 * 224 * 3);
    int idx = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[idx++] = (pixel.r.toDouble() / 127.5) - 1.0;
        input[idx++] = (pixel.g.toDouble() / 127.5) - 1.0;
        input[idx++] = (pixel.b.toDouble() / 127.5) - 1.0;
      }
    }
    return input;
  }

  /// Analyze a sky photo and return a quality score (0-100).
  /// 0 = heavy light pollution, 100 = pristine dark sky.
  /// Returns -1 if ML model is unavailable (caller should use heuristic only).
  Future<int> analyzeImage(String imagePath) async {
    if (!_isLoaded && !_loadFailed) await loadModel();
    if (!_isLoaded) {
      debugPrint('[Sura ML] Model not loaded, skipping classification');
      lastClassification = null;
      return -1;
    }

    try {
      // Read and preprocess image
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Could not decode image');
      }

      final input = _preprocessImage(image);
      final inputTensor = input.reshape([1, 224, 224, 3]);

      // Run inference — 3-class softmax output [1, 3]
      // Create separate inner list to avoid reference sharing
      final output = [List<double>.filled(3, 0.0)];
      _interpreter!.run(inputTensor, output);

      final probs = output[0];
      final highProb = probs[0];    // Class 0: HIGH pollution (Bortle 7-9)
      final lowProb = probs[1];     // Class 1: LOW pollution (Bortle 1-3)
      final modProb = probs[2];     // Class 2: Moderate pollution (Bortle 4-6)

      // Store classification result
      lastClassification = MlClassificationResult(
        highProb: highProb,
        lowProb: lowProb,
        moderateProb: modProb,
      );

      debugPrint('[Sura ML] Probabilities — HIGH: ${highProb.toStringAsFixed(3)}, '
          'LOW: ${lowProb.toStringAsFixed(3)}, MOD: ${modProb.toStringAsFixed(3)}');

      // Map to sky quality score (0-100) using weighted interpolation
      final score = (lowProb * 85 + modProb * 50 + highProb * 15)
          .round()
          .clamp(0, 100);

      // Find winning class for logging
      final maxProb = max(highProb, max(lowProb, modProb));
      String winnerLabel;
      if (maxProb == lowProb) {
        winnerLabel = 'LOW pollution (Bortle 1-3)';
      } else if (maxProb == modProb) {
        winnerLabel = 'MODERATE pollution (Bortle 4-6)';
      } else {
        winnerLabel = 'HIGH pollution (Bortle 7-9)';
      }
      debugPrint('[Sura ML] Winner: $winnerLabel → skyQuality=$score');

      return score;
    } catch (e) {
      debugPrint('[Sura ML] Inference error: $e');
      lastClassification = null;
      return -1;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
