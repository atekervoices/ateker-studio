import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final class AuthRepository extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      await _ensureUserDocument(
        uid: userCredential.user?.uid,
        email: email,
        displayName: displayName,
      );
      
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseAuthException(e);
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureUserDocument(
        uid: _auth.currentUser?.uid,
        email: _auth.currentUser?.email ?? email,
        displayName: _auth.currentUser?.displayName,
      );
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseAuthException(e);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // TODO: Implement Google Sign-In properly
      throw AuthException(
        message: 'Google Sign-In not yet implemented',
        code: 'google_sign_in_not_implemented',
      );
    } catch (e) {
      throw AuthException(message: e.toString(), code: 'google_sign_in_failed');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseAuthException(e);
    }
  }

  Future<void> _ensureUserDocument({
    required String? uid,
    required String email,
    required String? displayName,
  }) async {
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'displayName': displayName ?? '',
        'lastSignInAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      // Do not block login/signup if Firestore is not configured yet.
      debugPrint('Skipping user profile sync: ${e.code} ${e.message}');
    }
  }
}

class AuthException implements Exception {
  final String message;
  final String code;

  AuthException({required this.message, required this.code});

  factory AuthException.fromFirebaseAuthException(FirebaseAuthException e) {
    return AuthException(
      message: e.message ?? 'Unknown authentication error',
      code: e.code,
    );
  }

  @override
  String toString() => message;
}
