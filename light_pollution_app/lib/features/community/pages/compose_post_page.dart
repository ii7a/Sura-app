import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reserve/pages/location_picker_page.dart';
import '../../analysis/models/analysis_result.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';

class ComposePostPage extends ConsumerStatefulWidget {
  const ComposePostPage({
    super.key,
    this.quotedPost,
    this.initialImage,
    this.analysisResult,
  });

  final SkyPost? quotedPost;
  final File? initialImage;
  final AnalysisResult? analysisResult;

  @override
  ConsumerState<ComposePostPage> createState() => _ComposePostPageState();
}

class _ComposePostPageState extends ConsumerState<ComposePostPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final List<File> _selectedImages = [];
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _selectedImages.add(widget.initialImage!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _selectedImages.add(File(picked.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (result != null && result.isNotEmpty) {
      final current = _textController.text;
      final location = '\u{1F4CD} $result';
      setState(() {
        _textController.text = current.isEmpty ? location : '$current\n$location';
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      });
    }
  }

  Future<void> _submitPost() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      await ref.read(communityProvider.notifier).addPost(
            caption: text,
            imageFiles: _selectedImages,
            quotedPostId: widget.quotedPost?.id,
            skyQuality: widget.analysisResult?.skyQuality,
            bortleClass: widget.analysisResult?.bortleClass.value,
            qualityLabel: widget.analysisResult?.qualityLabel,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToPost(e.toString()))),
        );
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final currentUserAsync = ref.watch(currentUserProvider);
    final user = currentUserAsync.valueOrNull;
    final hasContent =
        _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: font(
              color: AppColors.white,
              fontSize: 15,
            ),
          ),
        ),
        leadingWidth: 90,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: hasContent && !_isPosting ? _submitPost : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    hasContent ? AppColors.navy : AppColors.navy.withValues(alpha: 0.5),
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      l10n.post,
                      style: font(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Compose area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User avatar
                      _ComposeAvatar(user: user),
                      const SizedBox(width: 12),
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLines: null,
                          style: font(
                            color: AppColors.white,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.whatsHappening,
                            hintStyle: font(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  // Quoted post preview
                  if (widget.quotedPost != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 20, height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.navy,
                                ),
                                child: widget.quotedPost!.user.avatarUrl != null
                                    ? ClipOval(
                                        child: SmartImage(
                                          url: widget.quotedPost!.user.avatarUrl!,
                                          width: 20, height: 20,
                                          fallback: Center(
                                            child: Text(
                                              widget.quotedPost!.user.avatarInitials,
                                              style: font(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          widget.quotedPost!.user.avatarInitials,
                                          style: font(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.quotedPost!.user.name,
                                style: font(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.quotedPost!.user.username,
                                style: font(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.quotedPost!.caption,
                            style: font(color: AppColors.white, fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.quotedPost!.imageUrls.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.quotedPost!.imageUrls.first,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Analysis result card
                  if (widget.analysisResult != null) ...[
                    const SizedBox(height: 16),
                    _AnalysisResultBanner(result: widget.analysisResult!),
                  ],

                  // Selected images preview
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImages[index],
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: AppColors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.dark,
              border: Border(
                top: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  _ToolbarButton(
                    icon: Icons.image_outlined,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  _ToolbarButton(
                    icon: Icons.camera_alt_outlined,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _ToolbarButton(
                    icon: Icons.location_on_outlined,
                    onTap: _openLocationPicker,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Icon(icon, color: Colors.lightBlueAccent, size: 24),
      ),
    );
  }
}

class _ComposeAvatar extends StatelessWidget {
  const _ComposeAvatar({required this.user});
  final MockUser? user;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final initialsText = Text(
      user?.avatarInitials ?? '?',
      style: font(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700),
    );
    const circleBox = BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.navy,
    );

    final avatarUrl = user?.avatarUrl;
    if (avatarUrl == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: circleBox,
        child: Center(child: initialsText),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: circleBox,
      child: ClipOval(
        child: SmartImage(
          url: avatarUrl,
          width: 40,
          height: 40,
          fallback: Center(child: initialsText),
        ),
      ),
    );
  }
}

class _AnalysisResultBanner extends StatelessWidget {
  const _AnalysisResultBanner({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2633),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.qualityColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: result.qualityColor.withValues(alpha: 0.15),
              border: Border.all(color: result.qualityColor, width: 2),
            ),
            child: Center(
              child: Text(
                '${result.skyQuality}',
                style: font(
                  color: result.qualityColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'نتيجة تحليل السماء' : 'Sky Analysis Result',
                  style: font(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.qualityLabel,
                  style: font(
                    color: result.qualityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isArabic ? 'بورتل' : 'Bortle'} ${result.bortleClass.value}',
                  style: font(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Star icon
          Icon(
            result.isGoodForStargazing ? Icons.star : Icons.star_border,
            color: result.isGoodForStargazing
                ? const Color(0xFFFFD54F)
                : AppColors.textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }
}
