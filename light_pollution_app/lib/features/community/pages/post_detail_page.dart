import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import '../widgets/reply_card.dart';
import '../widgets/verified_badge.dart';
import 'fullscreen_image_page.dart';
import 'compose_post_page.dart';
import 'user_profile_page.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentController = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _pendingImages = [];
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickCommentImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (picked != null) {
        setState(() => _pendingImages.add(File(picked.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _removePendingImage(int index) {
    setState(() => _pendingImages.removeAt(index));
  }

  void _showRepostSheet(BuildContext context, WidgetRef ref, SkyPost post) {
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
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSub(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.repeat,
                  color: post.isReposted
                      ? const Color(0xFF00BA7C)
                      : AppColors.text(context)),
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
                ref.read(communityProvider.notifier).toggleRepost(post.id);
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

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _pendingImages.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await ref.read(communityProvider.notifier).addComment(
            widget.postId,
            text,
            imageFiles: List.of(_pendingImages),
          );
      _commentController.clear();
      _pendingImages.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send comment: $e')),
        );
      }
    }
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _confirmDeleteComment(PostComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(communityProvider.notifier).deleteComment(widget.postId, comment.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final postsAsync = ref.watch(postsStreamProvider);
    final posts = postsAsync.valueOrNull ?? [];
    final post = posts.where((p) => p.id == widget.postId).firstOrNull;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (post == null) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: CircularProgressIndicator(color: AppColors.navy)),
      );
    }

    final isCurrentUser = post.userId == uid;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.icon(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post', style: font(color: AppColors.text(context), fontSize: 18.0, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Post content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User header — tappable to open profile
                      GestureDetector(
                        onTap: () => Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(builder: (_) => UserProfilePage(user: post.user)),
                        ),
                        child: Row(
                        children: [
                          isCurrentUser
                              ? _CurrentUserAvatar(user: post.user)
                              : _UserAvatar(user: post.user),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        post.user.name,
                                        style: font(color: AppColors.text(context), fontSize: 16.0, fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (post.user.isVerified) ...[
                                      const SizedBox(width: 4),
                                      VerifiedBadge(size: 16, isAdmin: post.user.isAdmin),
                                    ],
                                  ],
                                ),
                                Text(post.user.username, style: font(color: AppColors.textSecondary, fontSize: 14.0)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ),
                      const SizedBox(height: 14),

                      // Caption
                      Text(
                        post.caption,
                        style: font(color: AppColors.text(context), fontSize: 16.0, height: 1.5),
                      ),

                      // Sky analysis result card
                      if (post.skyQuality != null) ...[
                        const SizedBox(height: 12),
                        _PostDetailAnalysisCard(
                          skyQuality: post.skyQuality!,
                          bortleClass: post.bortleClass,
                          qualityLabel: post.qualityLabel,
                        ),
                      ],

                      // Images
                      if (post.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FullscreenImagePage(imageUrls: post.imageUrls),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SmartImage(
                              url: post.imageUrls.first,
                              width: double.infinity,
                              height: 250,
                            ),
                          ),
                        ),
                      ] else if (post.imageFiles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FullscreenImagePage(imageFiles: post.imageFiles),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              post.imageFiles.first as File,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 250,
                            ),
                          ),
                        ),
                      ] else if (post.imageAssets.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _SkyPlaceholder(asset: post.imageAssets.first),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Time + location
                      Row(
                        children: [
                          Text(post.timeAgo, style: font(color: AppColors.textHint, fontSize: 13.0)),
                          if (post.location != null) ...[
                            Text(' · ', style: font(color: AppColors.textHint, fontSize: 13.0)),
                            Icon(Icons.location_on, size: 14, color: AppColors.textHint),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                post.location!,
                                style: font(color: AppColors.textHint, fontSize: 13.0),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),

                      // Stats row
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            if (post.likes > 0) ...[
                              Text('${post.likes}', style: font(color: AppColors.text(context), fontSize: 14.0, fontWeight: FontWeight.w700)),
                              Text(' Likes', style: font(color: AppColors.textSecondary, fontSize: 14.0)),
                              const SizedBox(width: 16),
                            ],
                            if (post.reposts > 0) ...[
                              Text('${post.reposts}', style: font(color: AppColors.text(context), fontSize: 14.0, fontWeight: FontWeight.w700)),
                              Text(' Reposts', style: font(color: AppColors.textSecondary, fontSize: 14.0)),
                              const SizedBox(width: 16),
                            ],
                            if (post.comments.isNotEmpty) ...[
                              Text('${post.comments.length}', style: font(color: AppColors.text(context), fontSize: 14.0, fontWeight: FontWeight.w700)),
                              Text(' Comments', style: font(color: AppColors.textSecondary, fontSize: 14.0)),
                            ],
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Comment
                            IconButton(
                              icon: Icon(Icons.chat_bubble_outline,
                                  color: AppColors.textSub(context), size: 22),
                              onPressed: () {
                                // Scroll down to comment input
                              },
                            ),
                            // Repost
                            IconButton(
                              icon: Icon(Icons.repeat,
                                  color: post.isReposted
                                      ? const Color(0xFF00BA7C)
                                      : AppColors.textSub(context),
                                  size: 22),
                              onPressed: () => _showRepostSheet(context, ref, post),
                            ),
                            // Like
                            IconButton(
                              icon: Icon(
                                post.isLiked ? Icons.favorite : Icons.favorite_border,
                                color: post.isLiked ? Colors.redAccent : AppColors.textSub(context),
                                size: 22,
                              ),
                              onPressed: () => ref.read(communityProvider.notifier).toggleLike(post.id),
                            ),
                            // Bookmark
                            IconButton(
                              icon: Icon(
                                post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                color: post.isBookmarked ? AppColors.navy : AppColors.textSub(context),
                                size: 22,
                              ),
                              onPressed: () => ref.read(communityProvider.notifier).toggleBookmark(post.id),
                            ),
                            // Share
                            IconButton(
                              icon: Icon(Icons.ios_share_outlined,
                                  color: AppColors.textSub(context), size: 22),
                              onPressed: () {
                                SharePlus.instance.share(ShareParams(
                                  text: '${post.caption}\n\n— ${post.user.name} on SURA',
                                ));
                              },
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),
                    ],
                  ),
                ),

                // Comments
                if (post.comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(l10n.noCommentsYet, style: font(color: AppColors.textHint, fontSize: 14.0)),
                    ),
                  )
                else
                  ...post.comments.map((comment) => ReplyCard(
                        comment: comment,
                        canDelete: comment.userId == uid,
                        onDelete: () => _confirmDeleteComment(comment),
                      )),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // Comment input bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 8, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              border: Border(top: BorderSide(color: AppColors.div(context))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pending image previews
                if (_pendingImages.isNotEmpty) ...[
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pendingImages.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _pendingImages[index],
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removePendingImage(index),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    _CurrentUserAvatar(user: currentUser, radius: 16, fontSize: 10),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _isSending ? null : _pickCommentImage,
                      icon: Icon(Icons.image_outlined,
                          color: AppColors.icon(context), size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: font(fontSize: 14.0, color: AppColors.text(context)),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: l10n.addComment,
                          hintStyle: font(color: AppColors.hint(context), fontSize: 14.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.card(context),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _isSending ? null : _sendComment,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.send, color: AppColors.icon(context), size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentUserAvatar extends StatelessWidget {
  const _CurrentUserAvatar({required this.user, this.radius = 22, this.fontSize = 14});
  final MockUser? user;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final initialsText = Text(
      user?.avatarInitials ?? '?',
      style: AppFonts.style(context)(color: AppColors.white, fontSize: fontSize, fontWeight: FontWeight.w700),
    );
    final fallbackAvatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      child: initialsText,
    );
    final avatarUrl = user?.avatarUrl;
    if (avatarUrl == null) return fallbackAvatar;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.navy,
      child: ClipOval(
        child: SmartImage(
          url: avatarUrl,
          width: radius * 2,
          height: radius * 2,
          fallback: initialsText,
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});
  final MockUser user;

  @override
  Widget build(BuildContext context) {
    if (user.avatarUrl != null) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.navy,
        child: ClipOval(
          child: SmartImage(url: user.avatarUrl!, width: 44, height: 44,
            fallback: Text(user.avatarInitials, style: AppFonts.style(context)(color: AppColors.white, fontSize: 14.0, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.navy,
      child: Text(user.avatarInitials, style: AppFonts.style(context)(color: AppColors.white, fontSize: 14.0, fontWeight: FontWeight.w700)),
    );
  }
}


class _SkyPlaceholder extends StatelessWidget {
  const _SkyPlaceholder({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF0a0a2e), const Color(0xFF1a1a4e), const Color(0xFF0d0d1a)],
        ),
      ),
    );
  }
}

class _PostDetailAnalysisCard extends StatelessWidget {
  const _PostDetailAnalysisCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                '$skyQuality',
                style: font(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (qualityLabel != null)
                  Text(
                    qualityLabel!,
                    style: font(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (bortleClass != null)
                  Text(
                    'Bortle $bortleClass',
                    style: font(
                      color: AppColors.textSub(context),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            _isGood ? Icons.star : Icons.star_border,
            color: _isGood ? const Color(0xFFFFD54F) : AppColors.textSub(context),
            size: 22,
          ),
        ],
      ),
    );
  }
}
