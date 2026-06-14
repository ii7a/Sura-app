import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_image.dart';
import '../models/community_models.dart';
import '../widgets/verified_badge.dart';

/// Settings entry showing every account the current user has blocked.
/// Each row exposes an Unblock action that removes the entry from the
/// blocker's `users/{uid}/blocked` subcollection.
class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final _firestore = FirestoreService();

  Future<void> _unblock(String myUid, MockUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unblock'),
        content: Text(
            'Unblock ${user.name}? They will be able to message you and see your posts again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _firestore.unblockUser(myUid, user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not unblock: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.icon(context)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Blocked accounts',
          style: font(
            color: AppColors.text(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: myUid == null
          ? Center(
              child: Text(
                'Sign in to manage blocked accounts.',
                style: font(color: AppColors.textSub(context), fontSize: 14),
              ),
            )
          : StreamBuilder<List<String>>(
              stream: _firestore.blockedUidsStream(myUid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final uids = snap.data ?? const <String>[];
                if (uids.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, size: 48, color: AppColors.hint(context)),
                        const SizedBox(height: 12),
                        Text(
                          'No blocked accounts',
                          style: font(color: AppColors.textSub(context), fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return FutureBuilder<List<MockUser?>>(
                  future: Future.wait(uids.map(_firestore.getUser)),
                  builder: (context, usersSnap) {
                    if (!usersSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users = usersSnap.data!.whereType<MockUser>().toList();
                    return ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 76,
                        color: AppColors.div(context),
                      ),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _BlockedTile(
                          user: user,
                          onUnblock: () => _unblock(myUid, user),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class _BlockedTile extends StatelessWidget {
  const _BlockedTile({required this.user, required this.onUnblock});

  final MockUser user;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.navy,
            child: user.avatarUrl != null
                ? ClipOval(
                    child: SmartImage(
                      url: user.avatarUrl!,
                      width: 48,
                      height: 48,
                      fallback: Text(
                        user.avatarInitials,
                        style: font(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Text(
                    user.avatarInitials,
                    style: font(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: font(
                          color: AppColors.text(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 4),
                      VerifiedBadge(size: 16, isAdmin: user.isAdmin),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.username,
                  style: font(color: AppColors.textSub(context), fontSize: 13),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onUnblock,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.navy),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Unblock',
              style: font(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
