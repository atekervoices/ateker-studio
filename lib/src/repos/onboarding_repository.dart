import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class OnboardingRepository extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _onboardingCompleteKey = 'ONBOARDING_COMPLETE_V1';
  static const _ageKey = 'ONBOARDING_AGE';
  static const _genderKey = 'ONBOARDING_GENDER';
  static const _languageKey = 'ONBOARDING_LANGUAGE';
  static const _dialectKey = 'ONBOARDING_DIALECT';

  bool _isComplete = false;
  String _age = '';
  String _gender = '';
  String _language = '';
  String _dialect = '';

  bool get isComplete => _isComplete;
  String get age => _age;
  String get gender => _gender;
  String get language => _language;
  String get dialect => _dialect;

  Future<void> initFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    _age = prefs.getString(_ageKey) ?? '';
    _gender = prefs.getString(_genderKey) ?? '';
    _language = prefs.getString(_languageKey) ?? '';
    _dialect = prefs.getString(_dialectKey) ?? '';
    notifyListeners();
  }

  Future<void> saveProfile({
    required String age,
    required String gender,
    required String language,
    required String dialect,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _age = age;
    _gender = gender;
    _language = language;
    _dialect = dialect;
    _isComplete = true;
    await prefs.setString(_ageKey, age);
    await prefs.setString(_genderKey, gender);
    await prefs.setString(_languageKey, language);
    await prefs.setString(_dialectKey, dialect);
    await prefs.setBool(_onboardingCompleteKey, true);
    await _saveProfileToCloud();
    notifyListeners();
  }

  Future<void> _saveProfileToCloud() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'onboarding': {
          'age': _age,
          'gender': _gender,
          'language': _language,
          'dialect': _dialect,
          'completedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      // Keep onboarding usable even before Firestore is provisioned.
      debugPrint('Skipping onboarding cloud sync: ${e.code} ${e.message}');
    }
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    _isComplete = false;
    _age = '';
    _gender = '';
    _language = '';
    _dialect = '';
    await prefs.remove(_onboardingCompleteKey);
    await prefs.remove(_ageKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_languageKey);
    await prefs.remove(_dialectKey);
    notifyListeners();
  }
}
