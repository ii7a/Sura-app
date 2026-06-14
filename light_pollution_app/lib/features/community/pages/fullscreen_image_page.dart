import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/smart_image.dart';

/// Full-screen image viewer with pinch-to-zoom and swipe-to-dismiss.
/// Supports network URLs, local files, and multiple images (swipeable).
class FullscreenImagePage extends StatefulWidget {
  const FullscreenImagePage({
    super.key,
    this.imageUrls = const [],
    this.imageFiles = const [],
    this.initialIndex = 0,
  });

  final List<String> imageUrls;
  final List<dynamic> imageFiles;
  final int initialIndex;

  @override
  State<FullscreenImagePage> createState() => _FullscreenImagePageState();
}

class _FullscreenImagePageState extends State<FullscreenImagePage> {
  late PageController _pageController;
  late int _currentIndex;
  late int _totalImages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _totalImages = widget.imageUrls.isNotEmpty
        ? widget.imageUrls.length
        : widget.imageFiles.length;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Swipe-to-dismiss + pinch-to-zoom
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity!.abs() > 300) {
                  _close();
                }
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalImages,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: _buildImage(index),
                    ),
                  );
                },
              ),
            ),

            // Close button (top left)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: GestureDetector(
                onTap: _close,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

            // Page indicator (bottom center) — only if multiple images
            if (_totalImages > 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalImages, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(int index) {
    if (widget.imageUrls.isNotEmpty) {
      return SmartImage(
        url: widget.imageUrls[index],
        width: double.infinity,
        fit: BoxFit.contain,
      );
    } else if (widget.imageFiles.isNotEmpty) {
      final file = widget.imageFiles[index];
      if (file is File) {
        return Image.file(
          file,
          fit: BoxFit.contain,
        );
      }
    }
    return const SizedBox.shrink();
  }
}
