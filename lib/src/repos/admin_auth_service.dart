import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  bool _isLoading = true;
  String? _error;
  bool _disposed = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  AdminAuthService() {
    // Listen to auth state changes and enforce admin domain
    _auth.authStateChanges().listen((User? user) async {
      if (user != null && user.email != null && !user.email!.endsWith('@atekervoices.com')) {
        developer.log('Non-admin user detected in state change, signing out: ${user.email}');
        await _auth.signOut();
        _user = null;
      } else {
        _user = user;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      
      // Admin authorization check: must have @atekervoices.com domain
      if (user != null && user.email != null && !user.email!.endsWith('@atekervoices.com')) {
        await _auth.signOut();
        _user = null;
        _error = 'Invalid email or password. Please try again.';
        notifyListeners();
        return false;
      }

      _user = user;
      _error = null;
      developer.log('Admin signed in: ${_user?.email}');
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error = 'No admin account found with this email.';
          break;
        case 'wrong-password':
          _error = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          _error = 'Invalid email address format.';
          break;
        case 'user-disabled':
          _error = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          _error = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-credential':
          _error = 'Invalid email or password. Please try again.';
          break;
        default:
          _error = 'Authentication failed: ${e.message}';
      }
      developer.log('Auth error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      developer.log('Auth error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      developer.log('Sign out error: $e');
    }
  }
}
