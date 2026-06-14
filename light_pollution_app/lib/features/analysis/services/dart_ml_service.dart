import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'ml_weights.dart';

/// Pure-Dart neural network inference for sky quality prediction.
///
/// Uses pre-trained weights exported from Python (no native dependencies).
/// Works on all platforms: iOS, macOS, Windows, web.
/// Input: image path → extracts 20 features → feedforward NN → score 0-100.
class DartMlService {
  /// Analyze a sky image and return a quality score (0-100).
  /// 0 = heavy light pollution, 100 = pristine dark sky.
  Future<int> analyzeImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) return -1;

    image = img.copyResize(image, width: 100, height: 100);

    final features = _extractFeatures(image);
    if (features == null) return -1;

    final normalized = _normalize(features);
    final score = _forward(normalized);

    return (score * 100).round().clamp(0, 100);
  }

  List<double>? _extractFeatures(img.Image image) {
    try {
      final pixels = image.width * image.height;
      final brightnesses = List<double>.filled(pixels, 0);
      double totalBrightRatio = 0, totalDarkRatio = 0, totalVeryDarkRatio = 0;
      double totalMidRatio = 0;
      double totalBlueRatio = 0, totalRedRatio = 0, totalOrangeRatio = 0;
      double totalColorTemp = 0;
      int idx = 0;

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toDouble() / 255.0;
          final g = pixel.g.toDouble() / 255.0;
          final b = pixel.b.toDouble() / 255.0;

          final brightness = 0.299 * r + 0.587 * g + 0.114 * b;
          brightnesses[idx++] = brightness;

          if (brightness > 0.6) totalBrightRatio += 1;
          if (brightness < 0.15) totalDarkRatio += 1;
          if (brightness < 0.05) totalVeryDarkRatio += 1;
          if (brightness > 0.2 && brightness < 0.5) totalMidRatio += 1;

          final sum = r + g + b + 1e-7;
          totalBlueRatio += b / sum;
          totalRedRatio += r / sum;
          totalOrangeRatio += (r * 0.7 + g * 0.3) / sum;
          totalColorTemp += b - r;
        }
      }

      final n = pixels.toDouble();

      // Basic stats
      double meanBright = 0;
      for (final b in brightnesses) {
        meanBright += b;
      }
      meanBright /= n;

      final sorted = List<double>.from(brightnesses)..sort();
      final medianBright = sorted[sorted.length ~/ 2];

      double sumSqDiff = 0;
      for (final b in brightnesses) {
        sumSqDiff += (b - meanBright) * (b - meanBright);
      }
      final stdBright = sqrt(sumSqDiff / n);

      final minBright = sorted.first;
      final maxBright = sorted.last;
      final p90 = sorted[(n * 0.9).toInt().clamp(0, pixels - 1)];
      final p10 = sorted[(n * 0.1).toInt().clamp(0, pixels - 1)];

      // Uniformity
      final uniformity = 1.0 - min(stdBright * 3, 1.0);

      // Histogram (8 bins)
      final hist = List<double>.filled(8, 0);
      for (final b in brightnesses) {
        final bin = (b * 8).toInt().clamp(0, 7);
        hist[bin] += 1;
      }
      for (int i = 0; i < 8; i++) {
        hist[i] /= n;
      }

      return [
        meanBright,
        medianBright,
        stdBright,
        totalBrightRatio / n,
        totalDarkRatio / n,
        totalVeryDarkRatio / n,
        totalMidRatio / n,
        totalBlueRatio / n,
        totalRedRatio / n,
        totalOrangeRatio / n,
        totalColorTemp / n,
        uniformity,
        p90,
        p10,
        minBright,
        maxBright,
        hist[0],
        hist[1],
        hist[6],
        hist[7],
      ];
    } catch (_) {
      return null;
    }
  }

  List<double> _normalize(List<double> features) {
    final means = MlWeights.featureMeans;
    final stds = MlWeights.featureStds;
    return List.generate(
      features.length,
      (i) => (features[i] - means[i]) / stds[i],
    );
  }

  double _forward(List<double> input) {
    // Layer 1: input → hidden1 (ReLU)
    final h1 = _denseRelu(
      input,
      MlWeights.w1,
      MlWeights.b1,
      MlWeights.inputSize,
      MlWeights.hidden1Size,
    );

    // Layer 2: hidden1 → hidden2 (ReLU)
    final h2 = _denseRelu(
      h1,
      MlWeights.w2,
      MlWeights.b2,
      MlWeights.hidden1Size,
      MlWeights.hidden2Size,
    );

    // Layer 3: hidden2 → output (Sigmoid)
    final out = _denseSigmoid(
      h2,
      MlWeights.w3,
      MlWeights.b3,
      MlWeights.hidden2Size,
      1,
    );

    return out[0];
  }

  List<double> _denseRelu(
    List<double> input,
    List<double> weights,
    List<double> bias,
    int inSize,
    int outSize,
  ) {
    final output = List<double>.filled(outSize, 0);
    for (int j = 0; j < outSize; j++) {
      double sum = bias[j];
      for (int i = 0; i < inSize; i++) {
        sum += input[i] * weights[i * outSize + j];
      }
      output[j] = sum > 0 ? sum : 0; // ReLU
    }
    return output;
  }

  List<double> _denseSigmoid(
    List<double> input,
    List<double> weights,
    List<double> bias,
    int inSize,
    int outSize,
  ) {
    final output = List<double>.filled(outSize, 0);
    for (int j = 0; j < outSize; j++) {
      double sum = bias[j];
      for (int i = 0; i < inSize; i++) {
        sum += input[i] * weights[i * outSize + j];
      }
      output[j] = 1.0 / (1.0 + exp(-sum.clamp(-500, 500)));
    }
    return output;
  }
}
