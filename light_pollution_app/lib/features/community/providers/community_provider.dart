import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/models/notification_model.dart';
import '../models/community_models.dart';

class CommunityState {
  const CommunityState({
    this.posts = const [],
    this.isLoading = false,
  });

  final List<SkyPost> posts;
  final bool isLoading;

  CommunityState copyWith({
    List<SkyPost>? posts,
    bool? isLoading,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final postsStreamProvider = StreamProvider<List<SkyPost>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;
  return firestoreService.postsStream(currentUserId: uid);
});

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class CommunityNotifier extends StateNotifier<CommunityState> {
  CommunityNotifier(this._ref) : super(const CommunityState());

  final Ref _ref;

  FirestoreService get _firestore => _ref.read(firestoreServiceProvider);
  StorageService get _storage => _ref.read(storageServiceProvider);

  /// Trims a post caption down to a short preview string we can embed in
  /// a notification. Keeps things readable on the notifications page.
  String _preview(String caption) {
    final trimmed = caption.trim();
    if (trimmed.length <= 60) return trimmed;
    return '${trimmed.substring(0, 60)}…';
  }

  /// Looks up a cached post first (fast path, avoids a round-trip), then
  /// falls back to Firestore. Returns null if the post or its author are
  /// missing — the caller should simply skip notification creation.
  Future<SkyPost?> _lookupPost(String postId) async {
    final cached = _ref.read(postsStreamProvider).valueOrNull ?? [];
    final hit = cached.where((p) => p.id == postId).firstOrNull;
    if (hit != null) return hit;
    return null;
  }

  Future<void> toggleLike(String postId) async {
    final authState = _ref.read(authStateProvider);
    final uid = authState.valueOrNull?.uid;
    if (uid == null) return;

    // Snapshot the pre-toggle state so we know whether this was a like
    // or an un-like, and create/delete the notification accordingly.
    final post = await _lookupPost(postId);
    final wasLiked = post?.likedBy.contains(uid) ?? false;

    await _firestore.toggleLike(postId, uid);

    if (post == null) return;
    final actor = await _firestore.getUser(uid);
    if (actor == null) return;

    if (!wasLiked) {
      // New like → notify the post author.
      await _firestore.createNotification(
        recipientUid: post.userId,
        actor: actor,
        type: NotificationType.like,
        postId: postId,
        postPreview: _preview(post.caption),
      );
    } else {
      // Un-like → remove the matching notification so the author's list
      // doesn't stay cluttered with notifications for reverted likes.
      await _firestore.deleteNotification(
        recipientUid: post.userId,
        actorUid: uid,
        type: NotificationType.like,
        postId: postId,
      );
    }
  }

  Future<void> addPost({
    required String caption,
    List<File> imageFiles = const [],
    String? location,
    int? bortleClass,
    int? skyQuality,
    String? qualityLabel,
    String? quotedPostId,
  }) async {
    final authState = _ref.read(authStateProvider);
    final uid = authState.valueOrNull?.uid;
    if (uid == null) return;

    // Create post first to get ID
    final postId = await _firestore.createPost({
      'userId': uid,
      'caption': caption,
      'imageAssets': <String>[],
      'imageUrls': <String>[],
      'likedBy': <String>[],
      'bookmarkedBy': <String>[],
      'repostedBy': <String>[],
      'reposts': 0,
      'location': location,
      'bortleClass': bortleClass,
      'skyQuality': skyQuality,
      'qualityLabel': qualityLabel,
      'quotedPostId': quotedPostId,
      'createdAt': DateTime.now(),
    });

    // Upload images to Firebase Storage and persist download URLs
    if (imageFiles.isNotEmpty) {
      try {
        final urls = await _storage.uploadPostImages(imageFiles, postId);
        await _firestore.updatePost(postId, {'imageUrls': urls});
      } catch (e) {
        // Upload failed — roll back the post so the user doesn't see a broken entry
        await _firestore.deletePost(postId);
        rethrow;
      }
    }

    // Quote posts generate a notification for the original author.
    if (quotedPostId != null && quotedPostId.isNotEmpty) {
      final quoted = await _lookupPost(quotedPostId);
      final actor = await _firestore.getUser(uid);
      if (quoted != null && actor != null) {
        await _firestore.createNotification(
          recipientUid: quoted.userId,
          actor: actor,
          type: NotificationType.quote,
          postId: postId, // link to the NEW post (the quote)
          postPreview: _preview(caption),
        );
      }
    }
  }

  Future<void> deletePost(String postId) async {
    // Get post data to find image URLs
    final posts = _ref.read(postsStreamProvider).valueOrNull ?? [];
    final post = posts.where((p) => p.id == postId).firstOrNull;
    if (post != null && post.imageUrls.isNotEmpty) {
      await _storage.deletePostImages(post.imageUrls);
    }
    await _firestore.deletePost(postId);
  }

  Future<void> toggleBookmark(String postId) async {
    final authState = _ref.read(authStateProvider);
    final uid = authState.valueOrNull?.uid;
    if (uid == null) return;
    await _firestore.toggleBookmark(postId, uid);
  }

  Future<void> toggleRepost(String postId) async {
    final authState = _ref.read(authStateProvider);
    final uid = authState.valueOrNull?.uid;
    if (uid == null) return;

    final post = await _lookupPost(postId);
    final wasReposted = post?.repostedBy.contains(uid) ?? false;

    await _firestore.toggleRepost(postId, uid);

    if (post == null) return;
    final actor = await _firestore.getUser(uid);
    if (actor == null) return;

    if (!wasReposted) {
      await _firestore.createNotification(
        recipientUid: post.userId,
        actor: actor,
        type: NotificationType.repost,
        postId: postId,
        postPreview: _preview(post.caption),
      );
    } else {
      await _firestore.deleteNotification(
        recipientUid: post.userId,
        actorUid: uid,
        type: NotificationType.repost,
        postId: postId,
      );
    }
  }

  Future<void> addComment(
    String postId,
    String text, {
    List<File> imageFiles = const [],
  }) async {
    final authState = _ref.read(authStateProvider);
    final uid = authState.valueOrNull?.uid;
    if (uid == null) return;

    // Upload any attached images to Cloudinary first.
    List<String> imageUrls = const [];
    if (imageFiles.isNotEmpty) {
      imageUrls = <String>[];
      for (int i = 0; i < imageFiles.length; i++) {
        final path = 'comments/$postId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await _storage.uploadImage(imageFiles[i], path);
        imageUrls.add(url);
      }
    }

    await _firestore.addComment(postId, {
      'userId': uid,
      'text': text,
      'imageUrls': imageUrls,
      'createdAt': DateTime.now(),
    });
    // Touch the post so the posts stream re-emits and the detail page
    // re-fetches the comments subcollection. Without this the new comment
    // only shows up after a hot reload or full stream refresh.
    await _firestore.updatePost(postId, {'lastCommentAt': DateTime.now()});

    // Notify the post author (skipped automatically when commenter == author).
    final post = await _lookupPost(postId);
    if (post == null) return;
    final actor = await _firestore.getUser(uid);
    if (actor == null) return;
    await _firestore.createNotification(
      recipientUid: post.userId,
      actor: actor,
      type: NotificationType.comment,
      postId: postId,
      postPreview: _preview(post.caption),
      commentText: _preview(text),
    );
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _firestore.deleteComment(postId, commentId);
    // Touch the post so the posts stream re-emits and the detail page
    // re-fetches the comments subcollection.
    await _firestore.updatePost(postId, {'lastCommentAt': DateTime.now()});
  }
}

final communityProvider =
    StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  return CommunityNotifier(ref);
});
