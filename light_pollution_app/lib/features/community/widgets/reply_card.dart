import 'package:flutter/material.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_image.dart';
import '../models/community_models.dart';
import 'verified_badge.dart';

/// Renders a [PostComment] as a post-card–style tile that visually matches
/// [SkyPostCard]. Used on the profile "Replies" tab and in the post detail
/// page so comments look the same everywhere.
class ReplyCard extends StatefulWidget {
  const ReplyCard({
    super.key,
    required this.comment,
    this.onTap,
    this.onDelete,
    this.canDelete = false,
  });

  final PostComment comment;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool canDelete;

  @override
  State<ReplyCard> createState() => _ReplyCardState();
}

class _ReplyCardState extends State<ReplyCard> {
  bool _liked = false;

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete reply',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                widget.onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final comment = widget.comment;
    final user = comment.user;
    final avatarUrl = user.avatarUrl;
    final initialsText = Text(
      user.avatarInitials,
      style: font(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: AppColors.bg(context),
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.navy,
              child: avatarUrl != null
                  ? ClipOval(
                      child: SmartImage(
                        url: avatarUrl,
                        width: 40,
                        height: 40,
                        fallback: initialsText,
                      ),
                    )
                  : initialsText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: name, badge, username, time, 3-dot menu
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          overflow: TextOverflow.ellipsis,
                          style: font(
                            color: AppColors.text(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 3),
                        VerifiedBadge(size: 16, isAdmin: user.isAdmin),
                      ],
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user.username,
                          overflow: TextOverflow.ellipsis,
                          style: font(color: AppColors.textSub(context), fontSize: 13),
                        ),
                      ),
                      Text(' · ${comment.timeAgo}',
                          style: font(color: AppColors.textSub(context), fontSize: 13)),
                      const Spacer(),
                      if (widget.canDelete && widget.onDelete != null)
                        GestureDetector(
                          onTap: _showMenu,
                          child: Icon(Icons.more_horiz,
                              size: 18, color: AppColors.textSub(context)),
                        ),
                    ],
                  ),
                  // Text
                  if (comment.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      comment.text,
                      style: font(
                        color: AppColors.text(context),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                  // Images
                  if (comment.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SmartImage(
                        url: comment.imageUrls.first,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
                  ],
                  // Action row — comment / repost / like / share (UI-only for now)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ReplyActionButton(
                          icon: Icons.chat_bubble_outline,
                          color: AppColors.textSub(context),
                          onTap: widget.onTap ?? () {},
                        ),
                        _ReplyActionButton(
                          icon: Icons.repeat,
                          color: AppColors.textSub(context),
                          onTap: () {},
                        ),
                        _ReplyActionButton(
                          icon: _liked ? Icons.favorite : Icons.favorite_border,
                          color: _liked ? Colors.redAccent : AppColors.textSecondary,
                          onTap: () => setState(() => _liked = !_liked),
                        ),
                        GestureDetector(
                          onTap: () {},
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
    );
  }
}

class _ReplyActionButton extends StatelessWidget {
  const _ReplyActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 18),
    );
  }
}
