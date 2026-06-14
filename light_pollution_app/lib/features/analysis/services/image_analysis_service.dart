import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import '../models/analysis_result.dart';

class ImageAnalysisService {
  static const int _targetWidth = 500;

  Future<AnalysisMetrics> analyzeImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Could not decode image');
    }

    // Downscale for performance
    if (image.width > _targetWidth) {
      image = img.copyResize(image, width: _targetWidth);
    }

    final brightnesses = <double>[];
    final histogram = List<int>.filled(256, 0);
    double totalBrightness = 0;
    int brightPixels = 0;
    int darkPixels = 0;
    int grayPixels = 0;
    double totalBlue = 0;
    double totalOrange = 0;
    double totalR = 0;
    double totalG = 0;
    double totalB = 0;
    int totalPixels = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        // Perceived brightness (luminance)
        final brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
        brightnesses.add(brightness);
        totalBrightness += brightness;

        final binIndex = (brightness * 255).clamp(0, 255).toInt();
        histogram[binIndex]++;

        if (brightness > 0.6) brightPixels++;
        if (brightness < 0.15) darkPixels++;

        // Gray/cloud detection: low-to-moderate saturation + moderate brightness
        // Clouds can be gray (R≈G≈B) or tinted (sunset/twilight clouds)
        final maxC = max(r, max(g, b));
        final minC = min(r, min(g, b));
        final saturation = maxC > 0 ? (maxC - minC) / maxC : 0.0;
        if (saturation < 0.25 && brightness >= 0.12 && brightness <= 0.90) {
          grayPixels++;
        }

        // Color analysis
        final sum = r + g + b;
        if (sum > 0) {
          final blueRatio = b / sum;
          final orangeRatio = (r * 0.7 + g * 0.3) / sum;
          totalBlue += blueRatio;
          totalOrange += orangeRatio;
        }

        totalR += r;
        totalG += g;
        totalB += b;
        totalPixels++;
      }
    }

    final meanBrightness = totalBrightness / totalPixels;

    // Median brightness
    brightnesses.sort();
    final medianBrightness = brightnesses[brightnesses.length ~/ 2];

    // Standard deviation
    double sumSquaredDiff = 0;
    for (final b in brightnesses) {
      sumSquaredDiff += (b - meanBrightness) * (b - meanBrightness);
    }
    final brightnessStdDev = sqrt(sumSquaredDiff / totalPixels);

    return AnalysisMetrics(
      meanBrightness: meanBrightness,
      medianBrightness: medianBrightness,
      brightPixelRatio: brightPixels / totalPixels,
      darkPixelRatio: darkPixels / totalPixels,
      blueRatio: totalBlue / totalPixels,
      orangeRatio: totalOrange / totalPixels,
      brightnessStdDev: brightnessStdDev,
      brightnessHistogram: histogram,
      meanR: totalR / totalPixels,
      meanG: totalG / totalPixels,
      meanB: totalB / totalPixels,
      grayPixelRatio: grayPixels / totalPixels,
    );
  }
}
