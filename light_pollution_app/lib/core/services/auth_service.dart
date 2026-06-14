import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final normalizedEmail = email.trim().toLowerCase();
    final initials = name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    final isAdmin = _adminEmails.contains(normalizedEmail);
    final isBootstrapVerified = _bootstrapVerifiedEmails.contains(normalizedEmail);

    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'username': '@$username',
      'avatarInitials': initials,
      'bio': '',
      'isVerified': isAdmin || isBootstrapVerified,
      'isAdmin': isAdmin,
      'avatarUrl': null,
      'bannerUrl': null,
      'phone': null,
      'email': normalizedEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  /// Admin emails — full access plus the verified badge. Reserved for the
  /// official Sura account only.
  static const _adminEmails = {'suraappsa@gmail.com'};

  /// Seed list of emails that start out verified. Everyone else gets
  /// verified only when an admin flips `isVerified` in the Firestore console.
  static const _bootstrapVerifiedEmails = {'maiali66m@gmail.com', 'suraappsa@gmail.com'};

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final normalizedEmail = email.trim().toLowerCase();
    final uid = credential.user!.uid;
    // Always backfill the email on the user doc so trip creators can see
    // the contact email of people who booked their trips. This also
    // migrates pre-existing users who signed up before the field existed.
    try {
      final updates = <String, dynamic>{'email': normalizedEmail};
      if (_bootstrapVerifiedEmails.contains(normalizedEmail)) {
        updates['isVerified'] = true;
        updates['isAdmin'] = _adminEmails.contains(normalizedEmail);
      }
      await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
    } catch (_) {}

    return credential;
  }

  /// Call on app startup to keep the user doc in sync with the signed-in
  /// Firebase Auth user — backfills the `email` field for legacy users and
  /// re-applies verified/admin flags for the bootstrap list.
  Future<void> ensurePremiumStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('ensurePremiumStatus: no user logged in');
      return;
    }
    final email = user.email?.trim().toLowerCase() ?? '';
    debugPrint('ensurePremiumStatus: email=$email, uid=${user.uid}');
    final updates = <String, dynamic>{};
    if (email.isNotEmpty) updates['email'] = email;
    if (_bootstrapVerifiedEmails.contains(email)) {
      updates['isVerified'] = true;
      updates['isAdmin'] = _adminEmails.contains(email);
    }
    if (updates.isEmpty) return;
    await _firestore.collection('users').doc(user.uid).set(updates, SetOptions(merge: true));
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
