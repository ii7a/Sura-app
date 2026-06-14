import 'dart:io';
import 'package:flutter/material.dart';

/// Displays an image from either a local file path or network URL.
/// Local paths start with "/", everything else is treated as a network URL.
class SmartImage extends StatelessWidget {
  const SmartImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('/')) {
      final file = File(url);
      if (!file.existsSync()) return fallback ?? const SizedBox.shrink();
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
    );
  }
}
