import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_image.dart';
import '../models/community_models.dart';
import '../pages/compose_post_page.dart';
import '../pages/fullscreen_image_page.dart';
import '../pages/profile_page.dart';
import '../pages/user_profile_page.dart';
import 'verified_badge.dart';

class SkyPostCard extends StatelessWidget {
  const SkyPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    this.onDelete,
    this.onTap,
    this.onRepost,
    this.onBookmark,
    this.quotedPost,
    this.repostedByName,
  });

  final SkyPost post;
  final SkyPost? quotedPost;
  final String? repostedByName;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onRepost;
  final VoidCallback? onBookmark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      color: AppColors.bg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reposted by header
          if (repostedByName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 8, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.repeat, size: 14,
                      color: AppColors.textSub(context)),
                  const SizedBox(width: 6),
                  Text(
                    '$repostedByName reposted',
                    style: AppFonts.style(context)(
                      color: AppColors.textSub(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          // User header
          Padding(
            padding: EdgeInsets.fromLTRB(16, repostedByName != null ? 4 : 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar — tappable to open user profile
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openUserProfile(context, post.user),
                  child: _PostAvatar(user: post.user),
                ),
                const SizedBox(width: 10),
                // Content column (header + caption + images + actions)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Single-line header
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _openUserProfile(context, post.user),
                              child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    post.user.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.style(context)(
                                      color: AppColors.text(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (post.user.isVerified) ...[
                                  const SizedBox(width: 3),
                                  VerifiedBadge(size: 16, isAdmin: post.user.isAdmin),
                                ],
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    post.user.username,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.style(context)(
                                      color: AppColors.textSub(context),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                          Text(
                            ' · ${post.timeAgo}',
                            style: AppFonts.style(context)(
                              color: AppColors.textSub(context),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (onDelete != null)
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: AppColors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  builder: (_) => SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: ListTile(
                                        leading: const Icon(Icons.delete_outline, color: Colors.red),
                                        title: Text(
                                          AppLocalizations.of(context)!.deletePost,
                                          style: AppFonts.style(context)(
                                            color: Colors.red,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          onDelete!();
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Icon(Icons.more_horiz, color: AppColors.textSub(context), size: 18),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Caption
                      Text(
                        post.caption,
                        style: AppFonts.style(context)(
                          color: AppColors.text(context),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),

                      // Sky analysis result card
                      if (post.skyQuality != null) ...[
                        const SizedBox(height: 10),
                        _PostAnalysisCard(
                          skyQuality: post.skyQuality!,
                          bortleClass: post.bortleClass,
                          qualityLabel: post.qualityLabel,
                        ),
                      ],

                      // Images (network URLs, local files, or asset placeholders)
                      if (post.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _NetworkImageSection(imageUrls: post.imageUrls),
                      ] else if (post.imageFiles.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _UserImageSection(imageFiles: post.imageFiles),
                      ] else if (post.imageAssets.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _PostImageSection(imageAssets: post.imageAssets),
                      ],

                      // Quoted post card
                      if (quotedPost != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.textSub(context).withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 18, height: 18,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.navy,
                                    ),
                                    child: quotedPost!.user.avatarUrl != null
                                        ? ClipOval(
                                            child: SmartImage(
                                              url: quotedPost!.user.avatarUrl!,
                                              width: 18, height: 18,
                                              fallback: Center(
                                                child: Text(
                                                  quotedPost!.user.avatarInitials,
                                                  style: AppFonts.style(context)(
                                                    color: AppColors.white, fontSize: 8,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              quotedPost!.user.avatarInitials,
                                              style: AppFonts.style(context)(
                                                color: AppColors.white, fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    quotedPost!.user.name,
                                    style: AppFonts.style(context)(
                                      color: AppColors.text(context),
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    quotedPost!.user.username,
                                    style: AppFonts.style(context)(
                                      color: AppColors.textSecondary, fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '· ${quotedPost!.timeAgo}',
                                    style: AppFonts.style(context)(
                                      color: AppColors.textSecondary, fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                quotedPost!.caption,
                                style: AppFonts.style(context)(
                                  color: AppColors.text(context), fontSize: 14,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (quotedPost!.imageUrls.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    quotedPost!.imageUrls.first,
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

                      // Actions row
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ActionButton(
                              icon: Icons.chat_bubble_outline,
                              color: AppColors.textSub(context),
                              label: formatCount(post.comments.length),
                              onTap: onComment,
                            ),
                            _ActionButton(
                              icon: Icons.repeat,
                              color: post.isReposted
                                  ? const Color(0xFF00BA7C)
                                  : AppColors.textSub(context),
                              label: formatCount(post.reposts),
                              onTap: () => _showRepostSheet(context),
                            ),
                            _ActionButton(
                              icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: post.isLiked ? Colors.redAccent : AppColors.textSecondary,
                              label: formatCount(post.likes),
                              onTap: onLike,
                            ),
                            _ActionButton(
                              icon: post.isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: post.isBookmarked
                                  ? AppColors.navy
                                  : AppColors.textSub(context),
                              label: '',
                              onTap: () => onBookmark?.call(),
                            ),
                            GestureDetector(
                              onTap: () {
                                SharePlus.instance.share(ShareParams(
                                  text: '${post.caption}\n\n— ${post.user.name} on SURA',
                                ));
                              },
                              child: Icon(
                                Icons.ios_share_outlined,
                                color: AppColors.textSub(context),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),
        ],
      ),
    ),
    );
  }

  void _showRepostSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSub(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.repeat,
                color: post.isReposted
                    ? const Color(0xFF00BA7C)
                    : AppColors.text(context),
              ),
              title: Text(
                post.isReposted ? l10n.undoRepost : l10n.repost,
                style: font(
                  color: post.isReposted
                      ? const Color(0xFF00BA7C)
                      : AppColors.text(context),
                  fontSize: 16,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onRepost?.call();
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: AppColors.text(context)),
              title: Text(l10n.quotePost,
                  style: font(color: AppColors.text(context), fontSize: 16)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ComposePostPage(quotedPost: post),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openUserProfile(BuildContext context, MockUser user) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (user.id == currentUid) {
      // Tapping your own avatar/name opens your main profile page.
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    } else {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => UserProfilePage(user: user)),
      );
    }
  }
}

class _PostImageSection extends StatelessWidget {
  const _PostImageSection({required this.imageAssets});

  final List<String> imageAssets;

  @override
  Widget build(BuildContext context) {
    if (imageAssets.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: _SkyImagePlaceholder(imageAsset: imageAssets[0]),
        ),
      );
    }

    // 2 images side by side
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: _SkyImagePlaceholder(imageAsset: imageAssets[0]),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: _SkyImagePlaceholder(imageAsset: imageAssets[1]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          if (label.isNotEmpty && label != '0') ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: AppFonts.style(context)(color: AppColors.textSub(context), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _UserImageSection extends StatelessWidget {
  const _UserImageSection({required this.imageFiles});

  final List<dynamic> imageFiles;

  void _openFullscreen(BuildContext context, {int index = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenImagePage(
          imageFiles: imageFiles,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageFiles.length == 1) {
      return GestureDetector(
        onTap: () => _openFullscreen(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.file(imageFiles[0] as File, fit: BoxFit.cover),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _openFullscreen(context, index: 0),
                child: Image.file(imageFiles[0] as File, fit: BoxFit.cover, height: 200),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => _openFullscreen(context, index: 1),
                child: Image.file(imageFiles[1] as File, fit: BoxFit.cover, height: 200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkImageSection extends StatelessWidget {
  const _NetworkImageSection({required this.imageUrls});

  final List<String> imageUrls;

  void _openFullscreen(BuildContext context, {int index = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenImagePage(
          imageUrls: imageUrls,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => _openFullscreen(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.network(
              imageUrls[0],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.cardBg,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.cardBg,
                  child: const Center(child: Icon(Icons.broken_image, color: AppColors.textHint)),
                );
              },
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _openFullscreen(context, index: 0),
                child: Image.network(imageUrls[0], fit: BoxFit.cover, height: 200),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => _openFullscreen(context, index: 1),
                child: Image.network(
                  imageUrls.length > 1 ? imageUrls[1] : imageUrls[0],
                  fit: BoxFit.cover,
                  height: 200,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkyImagePlaceholder extends StatelessWidget {
  const _SkyImagePlaceholder({required this.imageAsset});

  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForAsset(imageAsset);

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
          ),
        ),
        CustomPaint(painter: _StarsPainter(imageAsset.hashCode)),
      ],
    );
  }

  List<Color> _getColorsForAsset(String asset) {
    switch (asset) {
      case 'milky_way':
        return [const Color(0xFF0a0a2e), const Color(0xFF1a1a4e), const Color(0xFF0d0d1a)];
      case 'desert_stars':
        return [const Color(0xFF000814), const Color(0xFF001d3d), const Color(0xFF1a0a00)];
      case 'orion_nebula':
        return [const Color(0xFF0a0020), const Color(0xFF2d1b69), const Color(0xFF0a0a2e)];
      case 'moon_city':
        return [const Color(0xFF1a1a2e), const Color(0xFF2a2a4e), const Color(0xFF3a3a3a)];
      case 'comparison':
        return [const Color(0xFF0a0a1e), const Color(0xFF1e1e3e), const Color(0xFF2e2e2e)];
      case 'milky_sea':
        return [const Color(0xFF000814), const Color(0xFF003566), const Color(0xFF001d3d)];
      case 'alula_sky':
        return [const Color(0xFF000000), const Color(0xFF0d1b2a), const Color(0xFF0a0a0a)];
      case 'beginner_sky':
        return [const Color(0xFF0f0f2e), const Color(0xFF1e1e4e), const Color(0xFF15152e)];
      default:
        return [const Color(0xFF0a0a2e), const Color(0xFF1a1a3e), const Color(0xFF0d0d1a)];
    }
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.seed);
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    var hash = seed;
    for (int i = 0; i < 50; i++) {
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final x = (hash % size.width.toInt()).toDouble();
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final y = (hash % size.height.toInt()).toDouble();
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final brightness = 0.3 + (hash % 70) / 100.0;
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final radius = 0.5 + (hash % 20) / 15.0;
      paint.color = Colors.white.withValues(alpha: brightness);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    for (int i = 0; i < 4; i++) {
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final x = (hash % size.width.toInt()).toDouble();
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final y = (hash % (size.height * 0.6).toInt()).toDouble();
      paint.color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(Offset(x, y), 2.0, paint);
      paint.color = Colors.white.withValues(alpha: 0.15);
      canvas.drawCircle(Offset(x, y), 5.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Avatar for post authors — loads from user.avatarUrl or falls back to initials.
class _PostAvatar extends StatelessWidget {
  const _PostAvatar({required this.user});
  final MockUser user;

  @override
  Widget build(BuildContext context) {
    if (user.avatarUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.navy,
        child: ClipOval(
          child: SmartImage(
            url: user.avatarUrl!,
            width: 40,
            height: 40,
            fallback: Text(
              user.avatarInitials,
              style: AppFonts.style(context)(
                color: AppColors.white,
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.navy,
      child: Text(
        user.avatarInitials,
        style: AppFonts.style(context)(
          color: AppColors.white,
          fontSize: 13.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PostAnalysisCard extends StatelessWidget {
  const _PostAnalysisCard({
    required this.skyQuality,
    this.bortleClass,
    this.qualityLabel,
  });

  final int skyQuality;
  final int? bortleClass;
  final String? qualityLabel;

  Color get _qualityColor {
    if (skyQuality >= 90) return const Color(0xFF00C853);
    if (skyQuality >= 75) return const Color(0xFF66BB6A);
    if (skyQuality >= 60) return const Color(0xFF8BC34A);
    if (skyQuality >= 45) return const Color(0xFFFFEB3B);
    if (skyQuality >= 30) return const Color(0xFFFF9800);
    if (skyQuality >= 15) return const Color(0xFFFF5722);
    return const Color(0xFFF44336);
  }

  bool get _isGood => skyQuality >= 45;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final color = _qualityColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: Text(
                '$skyQuality',
                style: font(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (qualityLabel != null)
                  Text(
                    qualityLabel!,
                    style: font(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (bortleClass != null)
                  Text(
                    'Bortle $bortleClass',
                    style: font(
                      color: AppColors.textSub(context),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Star
          Icon(
            _isGood ? Icons.star : Icons.star_border,
            color: _isGood ? const Color(0xFFFFD54F) : AppColors.textSub(context),
            size: 20,
          ),
        ],
      ),
    );
  }
}
