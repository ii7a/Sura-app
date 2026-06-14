import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/community/models/community_models.dart';
import '../../features/notifications/models/notification_model.dart';
import '../../features/notifications/models/notification_preferences.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ──────────────────────────────────────────────

  Future<MockUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return MockUser.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Streams the user's notification preferences. Falls back to defaults
  /// when the field hasn't been written yet (e.g. accounts created before
  /// phase B4 landed).
  Stream<NotificationPreferences> notificationPreferencesStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      return NotificationPreferences.fromMap(
        data?['notificationPrefs'] as Map<String, dynamic>?,
      );
    });
  }

  /// Persists a full preferences document. Writing the whole map in one
  /// go keeps the stream consistent — no intermediate partial states.
  Future<void> setNotificationPreferences(
    String uid,
    NotificationPreferences prefs,
  ) async {
    await _db.collection('users').doc(uid).set(
      {'notificationPrefs': prefs.toMap()},
      SetOptions(merge: true),
    );
  }

  /// Returns every user in the `users` collection. Used by the chat
  /// "New Message" picker to show real app users.
  Future<List<MockUser>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => MockUser.fromMap(d.id, d.data())).toList();
  }

  // ── Follow / Unfollow ──────────────────────────────────
  //
  // Relationships are stored as two subcollection docs per edge:
  //   users/{followeeId}/followers/{followerId}  (empty doc)
  //   users/{followerId}/following/{followeeId}  (empty doc)
  // Keeping both sides lets the two "count" streams stay cheap, and the
  // Firestore rules can authorize each doc independently.

  Future<void> followUser(String myUid, String otherUid) async {
    if (myUid == otherUid) return;
    final batch = _db.batch();
    batch.set(
      _db.collection('users').doc(otherUid).collection('followers').doc(myUid),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    batch.set(
      _db.collection('users').doc(myUid).collection('following').doc(otherUid),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    await batch.commit();
  }

  Future<void> unfollowUser(String myUid, String otherUid) async {
    final batch = _db.batch();
    batch.delete(
      _db.collection('users').doc(otherUid).collection('followers').doc(myUid),
    );
    batch.delete(
      _db.collection('users').doc(myUid).collection('following').doc(otherUid),
    );
    await batch.commit();
  }

  /// Streams whether [myUid] currently follows [otherUid].
  Stream<bool> isFollowingStream(String myUid, String otherUid) {
    return _db
        .collection('users')
        .doc(myUid)
        .collection('following')
        .doc(otherUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // ── Block / Unblock ────────────────────────────────────
  //
  // Stored as a single subcollection under the blocker's user doc:
  //   users/{myUid}/blocked/{otherUid}  (empty doc)
  // Reads stay on the blocker's side so other users can't enumerate who
  // has blocked them.

  Future<void> blockUser(String myUid, String otherUid) async {
    if (myUid == otherUid) return;
    await _db
        .collection('users')
        .doc(myUid)
        .collection('blocked')
        .doc(otherUid)
        .set({'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> unblockUser(String myUid, String otherUid) async {
    await _db
        .collection('users')
        .doc(myUid)
        .collection('blocked')
        .doc(otherUid)
        .delete();
  }

  /// Streams whether [myUid] currently blocks [otherUid].
  Stream<bool> isBlockedStream(String myUid, String otherUid) {
    return _db
        .collection('users')
        .doc(myUid)
        .collection('blocked')
        .doc(otherUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Streams whether [otherUid] currently blocks [myUid] — i.e. the
  /// "am I blocked" perspective. Powers the profile screen's
  /// "account unavailable" state. The Firestore rule explicitly allows
  /// the blocked party to read their own entry so this read isn't denied.
  Stream<bool> isBlockedByStream(String myUid, String otherUid) {
    return _db
        .collection('users')
        .doc(otherUid)
        .collection('blocked')
        .doc(myUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Streams the full list of users [myUid] has blocked, newest first.
  Stream<List<String>> blockedUidsStream(String myUid) {
    return _db
        .collection('users')
        .doc(myUid)
        .collection('blocked')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  /// One-shot check used by send-side guards (e.g. preventing a blocked
  /// user from opening a conversation). Looks at both directions so either
  /// party blocking the other halts the action.
  Future<bool> isEitherBlocked(String aUid, String bUid) async {
    final results = await Future.wait([
      _db.collection('users').doc(aUid).collection('blocked').doc(bUid).get(),
      _db.collection('users').doc(bUid).collection('blocked').doc(aUid).get(),
    ]);
    return results.any((d) => d.exists);
  }

  Stream<int> followersCountStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snap) => snap.size);
  }

  Stream<int> followingCountStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snap) => snap.size);
  }

  /// Returns the list of users who follow [userId].
  Future<List<MockUser>> getFollowers(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('followers')
        .get();
    final users = <MockUser>[];
    for (final doc in snap.docs) {
      final u = await getUser(doc.id);
      if (u != null) users.add(u);
    }
    return users;
  }

  /// Returns the list of users that [userId] follows.
  Future<List<MockUser>> getFollowing(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('following')
        .get();
    final users = <MockUser>[];
    for (final doc in snap.docs) {
      final u = await getUser(doc.id);
      if (u != null) users.add(u);
    }
    return users;
  }

  // ── Posts ──────────────────────────────────────────────

  Stream<List<SkyPost>> postsStream({String? currentUserId}) {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final posts = <SkyPost>[];
      // Collect unique user IDs
      final userIds = snapshot.docs.map((d) => d.data()['userId'] as String).toSet();
      // Batch-fetch users
      final usersMap = <String, MockUser>{};
      for (final uid in userIds) {
        if (uid.isEmpty) continue;
        final user = await getUser(uid);
        if (user != null) usersMap[uid] = user;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? '';
        final user = usersMap[userId] ??
            MockUser(
              id: userId,
              name: 'Unknown',
              username: '@unknown',
              avatarInitials: '?',
              bio: '',
            );

        // Fetch comments for this post
        final commentsSnap = await _db
            .collection('posts')
            .doc(doc.id)
            .collection('comments')
            .orderBy('createdAt', descending: false)
            .get();

        final comments = <PostComment>[];
        for (final commentDoc in commentsSnap.docs) {
          final commentData = commentDoc.data();
          final commentUserId = commentData['userId'] as String? ?? '';
          MockUser commentUser;
          if (usersMap.containsKey(commentUserId)) {
            commentUser = usersMap[commentUserId]!;
          } else {
            commentUser = await getUser(commentUserId) ??
                MockUser(
                  id: commentUserId,
                  name: 'Unknown',
                  username: '@unknown',
                  avatarInitials: '?',
                  bio: '',
                );
            usersMap[commentUserId] = commentUser;
          }
          comments.add(PostComment.fromMap(commentDoc.id, commentData, commentUser));
        }

        posts.add(SkyPost.fromMap(doc.id, data, user, comments, currentUserId: currentUserId));
      }
      return posts;
    });
  }

  Future<String> createPost(Map<String, dynamic> data) async {
    final ref = await _db.collection('posts').add(data);
    return ref.id;
  }

  Future<void> deletePost(String postId) async {
    // Delete comments subcollection first
    final comments = await _db.collection('posts').doc(postId).collection('comments').get();
    for (final doc in comments.docs) {
      await doc.reference.delete();
    }
    await _db.collection('posts').doc(postId).delete();
  }

  Future<void> toggleLike(String postId, String userId) async {
    final ref = _db.collection('posts').doc(postId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
    if (likedBy.contains(userId)) {
      // Unlike: drop the user from both the array and the timestamp map.
      await ref.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likes.$userId': FieldValue.delete(),
      });
    } else {
      // Like: add to the array and stamp the moment in the map so the
      // Likes tab can sort by "when I liked it".
      await ref.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likes.$userId': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> toggleBookmark(String postId, String userId) async {
    final ref = _db.collection('posts').doc(postId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final bookmarkedBy = List<String>.from(doc.data()?['bookmarkedBy'] ?? []);
    if (bookmarkedBy.contains(userId)) {
      bookmarkedBy.remove(userId);
    } else {
      bookmarkedBy.add(userId);
    }
    await ref.update({'bookmarkedBy': bookmarkedBy});
  }

  Future<void> toggleRepost(String postId, String userId) async {
    final ref = _db.collection('posts').doc(postId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final repostedBy = List<String>.from(doc.data()?['repostedBy'] ?? []);
    if (repostedBy.contains(userId)) {
      repostedBy.remove(userId);
    } else {
      repostedBy.add(userId);
    }
    await ref.update({'repostedBy': repostedBy});
  }

  // ── Comments ──────────────────────────────────────────

  Future<String> addComment(String postId, Map<String, dynamic> data) async {
    final ref = await _db.collection('posts').doc(postId).collection('comments').add(data);
    return ref.id;
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    await _db.collection('posts').doc(postId).update(data);
  }

  // ── Conversations ──────────────────────────────────────

  /// Returns a stream of conversations for the given user.
  /// Each conversation doc stores participant IDs and the last message info.
  Stream<List<Map<String, dynamic>>> conversationsStream(String userId) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Creates or returns an existing conversation between two users.
  /// When [userId] == [otherUserId] this is a "note to self" conversation —
  /// participants is a single-element set and we need to distinguish it from
  /// regular two-person conversations when reusing an existing doc.
  ///
  /// New conversations are seeded with an `acceptedBy` list. The initiator
  /// is always in it (they obviously consent to the thread they started),
  /// and the recipient is auto-added when they already follow the
  /// initiator — this matches X's "messages from people you follow skip
  /// the Requests folder". Otherwise the recipient sees it as a Message
  /// Request until they explicitly accept.
  Future<String> getOrCreateConversation(String userId, String otherUserId) async {
    final isSelf = userId == otherUserId;

    // Either party blocking the other halts the conversation here. The
    // call site catches and surfaces a friendly message.
    if (!isSelf && await isEitherBlocked(userId, otherUserId)) {
      throw StateError('blocked');
    }

    final existing = await _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      final uniqueParts = participants.toSet();
      if (isSelf) {
        // A self-conversation has only the current user as a participant.
        if (uniqueParts.length == 1 && uniqueParts.contains(userId)) {
          return doc.id;
        }
      } else {
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }
    }

    // Seed acceptedBy: initiator is always in, and the recipient is
    // pre-accepted if they already follow the initiator.
    final acceptedBy = <String>{userId};
    if (!isSelf) {
      final reciprocal = await _db
          .collection('users')
          .doc(otherUserId)
          .collection('following')
          .doc(userId)
          .get();
      if (reciprocal.exists) acceptedBy.add(otherUserId);
    }

    final ref = await _db.collection('conversations').add({
      'participants': isSelf ? [userId] : [userId, otherUserId],
      'acceptedBy': acceptedBy.toList(),
      'lastMessage': '',
      'lastMessageSenderId': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Accepts a pending message request: adds [userId] to the conversation's
  /// `acceptedBy` array so it moves out of the Requests folder.
  Future<void> acceptMessageRequest(String conversationId, String userId) async {
    await _db.collection('conversations').doc(conversationId).update({
      'acceptedBy': FieldValue.arrayUnion([userId]),
    });
  }

  /// Declines a message request by deleting the conversation entirely.
  /// Mirrors X — declined requests don't linger in either user's UI.
  Future<void> declineMessageRequest(String conversationId) async {
    await deleteConversation(conversationId);
  }

  /// Streams messages for a conversation.
  Stream<List<Map<String, dynamic>>> messagesStream(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Sends a message in a conversation. Marks the message as unread so the
  /// recipient's unread indicators light up until they open the chat.
  Future<void> sendMessage(String conversationId, Map<String, dynamic> message) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({...message, 'isRead': false});

    // Update conversation's last message
    await _db.collection('conversations').doc(conversationId).update({
      'lastMessage': message['text'],
      'lastMessageSenderId': message['senderId'],
      'lastMessageAt': message['timestamp'],
    });
  }

  /// Marks every unread message in a conversation as read for [userId].
  /// Only messages the user did NOT send are affected. The server-side
  /// filter is `isRead == false` only; the `senderId != userId` predicate
  /// is applied client-side so we don't need a composite index (and to
  /// avoid Firestore's quirk of dropping docs missing the inequality field).
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    final snap = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();
    final toUpdate = snap.docs.where((d) => d.data()['senderId'] != userId).toList();
    if (toUpdate.isEmpty) return;
    final batch = _db.batch();
    for (final doc in toUpdate) {
      batch.update(doc.reference, {'isRead': true});
    }
    // Touch the parent conversation doc so any listener watching the
    // conversations collection (chat list tiles, Messages-tab badge)
    // re-emits and recomputes the now-zero unread count. Without this,
    // the message subcollection update is invisible to those streams
    // until the app is relaunched.
    batch.update(
      _db.collection('conversations').doc(conversationId),
      {'lastReadAt.$userId': FieldValue.serverTimestamp()},
    );
    await batch.commit();
  }

  /// One-shot unread message count for a conversation. Unread = messages
  /// from the other participant whose `isRead` is false.
  Future<int> getUnreadMessagesCount(String conversationId, String userId) async {
    final snap = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();
    return snap.docs.where((d) => d.data()['senderId'] != userId).length;
  }

  /// Streams the number of conversations that contain at least one unread
  /// message for [userId] (i.e. a message from the other participant with
  /// `isRead == false`). Mirrors X/Twitter, whose Messages tab badge counts
  /// unread *threads*, not unread messages.
  ///
  /// A stale conversation doc with a missing or malformed `participants`
  /// field can make Firestore deny the listen with permission-denied. We
  /// catch that (and any per-doc message read failures) so a single bad
  /// row can't take down the badge for the whole user.
  Stream<int> unreadConversationsCountStream(String userId) async* {
    final convStream = _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .handleError((Object _) {
      // Swallow permission-denied / network errors here — the listener
      // upstream treats the stream as silent rather than crashing the
      // bottom-nav badge.
    });

    await for (final convSnap in convStream) {
      int count = 0;
      for (final convDoc in convSnap.docs) {
        try {
          final msgs = await _db
              .collection('conversations')
              .doc(convDoc.id)
              .collection('messages')
              .where('isRead', isEqualTo: false)
              .get();
          final hasUnread = msgs.docs.any((d) => d.data()['senderId'] != userId);
          if (hasUnread) count++;
        } catch (_) {
          // Skip this conversation on read failure rather than aborting
          // the whole count.
        }
      }
      yield count;
    }
  }

  /// Deletes a conversation and all its messages.
  Future<void> deleteConversation(String conversationId) async {
    // Delete the conversation document. Orphaned messages in the
    // subcollection become inaccessible (rules require the parent
    // conversation to exist and include the caller as a participant).
    // Deleting subcollection docs client-side can hit Firestore
    // get() quota limits in security rules, so we skip that here.
    await _db.collection('conversations').doc(conversationId).delete();
  }

  // ── Notifications ─────────────────────────────────────
  //
  // Stored in a top-level `notifications` collection. Each doc has a
  // `recipientUid` so we can query per-user. Interaction notifications
  // are created as a side-effect of like/repost/comment/follow/quote.

  /// Creates a notification document. Skips creation when actor == recipient
  /// (we don't notify users about their own actions).
  Future<void> createNotification({
    required String recipientUid,
    required MockUser actor,
    required NotificationType type,
    String? postId,
    String? postPreview,
    String? commentText,
  }) async {
    if (actor.id == recipientUid) return;
    if (recipientUid.isEmpty) return;

    final notif = AppNotification(
      id: '',
      recipientUid: recipientUid,
      actorUid: actor.id,
      actorName: actor.name,
      actorUsername: actor.username,
      actorAvatarUrl: actor.avatarUrl,
      actorAvatarInitials: actor.avatarInitials,
      type: type,
      postId: postId,
      postPreview: postPreview,
      commentText: commentText,
    );

    await _db.collection('notifications').add(notif.toMap());
  }

  /// Removes a prior notification (used when a user un-likes or un-reposts).
  /// We de-duplicate by recipient + actor + type + postId.
  Future<void> deleteNotification({
    required String recipientUid,
    required String actorUid,
    required NotificationType type,
    String? postId,
  }) async {
    var q = _db
        .collection('notifications')
        .where('recipientUid', isEqualTo: recipientUid)
        .where('actorUid', isEqualTo: actorUid)
        .where('type', isEqualTo: type.name);
    if (postId != null) {
      q = q.where('postId', isEqualTo: postId);
    }
    final snap = await q.get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    if (snap.docs.isNotEmpty) await batch.commit();
  }

  /// Streams the most recent 50 notifications for a user, newest first.
  Stream<List<AppNotification>> notificationsStream(String uid) {
    return _db
        .collection('notifications')
        .where('recipientUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.id, d.data()))
            .toList());
  }

  /// Unread count for the little red dot/badge on the bell icon.
  Stream<int> unreadNotificationCountStream(String uid) {
    return _db
        .collection('notifications')
        .where('recipientUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Marks a single notification as read.
  Future<void> markNotificationRead(String id) async {
    await _db.collection('notifications').doc(id).update({'read': true});
  }

  /// Marks all a user's notifications as read. Called when the user opens
  /// the notifications page so the badge clears.
  Future<void> markAllNotificationsRead(String uid) async {
    final snap = await _db
        .collection('notifications')
        .where('recipientUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Fans out a cosmic-event notification to every targeted user. The admin
  /// builds one payload, we multiply it into one doc per recipient so the
  /// existing per-user query paths keep working unchanged.
  ///
  /// [city] == null targets every user in the system. When set we also
  /// attempt to match on an explicit `city` field on the user doc first,
  /// and fall back to substring-matching the user's `location` so older
  /// accounts without the new field still get reached.
  ///
  /// Returns the number of recipients actually written (useful for showing
  /// the admin a confirmation like "sent to 42 users").
  Future<int> broadcastCosmicNotification({
    required MockUser admin,
    required String cosmicType,
    required String title,
    required String description,
    String? titleEn,
    String? descriptionEn,
    required DateTime eventDate,
    String? imageUrl,
    String? city, // null = all users
  }) async {
    // Pull user docs directly so we can read the freshly-added
    // `notificationPrefs.city` without having to widen MockUser.
    final userDocs = await _db.collection('users').get();

    final targeted = <MockUser>[];
    for (final doc in userDocs.docs) {
      final data = doc.data();
      final prefs = NotificationPreferences.fromMap(
        data['notificationPrefs'] as Map<String, dynamic>?,
      );
      // Silent users skip entirely — we don't write them a doc just to
      // have it ignored on the client.
      if (!prefs.enabled) continue;
      // City filter: broadcast's `city` must match the user's preferred
      // city, unless either side is empty (meaning "any city").
      if (city != null && city.isNotEmpty) {
        if (prefs.city.isNotEmpty && prefs.city != city) continue;
      }
      targeted.add(MockUser.fromMap(doc.id, data));
    }

    if (targeted.isEmpty) return 0;

    // Chunk batched writes: Firestore caps a batch at 500 operations.
    const chunkSize = 400;
    var written = 0;
    for (var i = 0; i < targeted.length; i += chunkSize) {
      final chunk = targeted.sublist(
        i,
        (i + chunkSize).clamp(0, targeted.length),
      );
      final batch = _db.batch();
      for (final u in chunk) {
        final notif = AppNotification(
          id: '',
          recipientUid: u.id,
          actorUid: admin.id,
          actorName: admin.name,
          actorUsername: admin.username,
          actorAvatarUrl: admin.avatarUrl,
          actorAvatarInitials: admin.avatarInitials,
          type: NotificationType.cosmic,
          cosmicType: cosmicType,
          eventTitle: title,
          eventDescription: description,
          eventTitleEn: titleEn,
          eventDescriptionEn: descriptionEn,
          eventDate: eventDate,
          eventImageUrl: imageUrl,
          eventCity: city,
        );
        batch.set(_db.collection('notifications').doc(), notif.toMap());
      }
      await batch.commit();
      written += chunk.length;
    }
    return written;
  }
}
