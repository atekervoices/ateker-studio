// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'phrase.dart';

final class PhrasesRepository extends ChangeNotifier {
  static const lastRecordedPhraseIndexKey = 'LAST_RECORDED_PHRASE_INDEX_KEY';
  static const recordedPhraseIndicesKey = 'RECORDED_PHRASE_INDICES_V1';

  final List<Phrase> _phrases = [];
  int _currentPhraseIndex = 0;
  final Set<int> _recordedPhraseIndices = <int>{};
  Future<void>? _loadingFuture;

  UnmodifiableListView<Phrase> get phrases => UnmodifiableListView(_phrases);
  int get currentPhraseIndex => _currentPhraseIndex;
  int get recordedCount => _recordedPhraseIndices.length;
  bool isRecorded(int phraseIndex) => _recordedPhraseIndices.contains(phraseIndex);
  Phrase? get currentPhrase =>
      _currentPhraseIndex < 0 || _currentPhraseIndex >= _phrases.length
          ? null
          : _phrases[_currentPhraseIndex];

  /// Initialises phrases. On the first call it loads from Firestore
  /// (admin-created prompts with kind == 'text'). Subsequent calls reuse the
  /// same in-flight future so the data is only fetched once.
  Future<void> initFromAssetFile() {
    _loadingFuture ??= _loadPhrases();
    return _loadingFuture!;
  }

  Future<void> _loadPhrases() async {
    final prefs = await SharedPreferences.getInstance();

    // Restore saved progress.
    _currentPhraseIndex = prefs.getInt(lastRecordedPhraseIndexKey) ?? 0;
    final recordedRaw = prefs.getString(recordedPhraseIndicesKey);
    _recordedPhraseIndices.clear();
    if (recordedRaw != null && recordedRaw.isNotEmpty) {
      final decoded = jsonDecode(recordedRaw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is int) _recordedPhraseIndices.add(item);
        }
      }
    }

    // Load from Firestore admin_prompts (kind == 'text')
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('admin_prompts')
          .where('kind', isEqualTo: 'text')
          .get();

      // Sort client-side by createdAt (oldest first) — avoids a composite index.
      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return aTime.compareTo(bTime);
        });

      final phrasesList = <Phrase>[];
      for (var i = 0; i < docs.length; i++) {
        final data = docs[i].data();
        final text = (data['text'] as String?) ?? '';
        if (text.isNotEmpty) {
          phrasesList.add(Phrase(index: i, text: text));
        }
      }
      developer.log(
          'PhrasesRepository: loaded ${phrasesList.length} phrases from Firestore');
      reset(updatedPhrases: phrasesList);
    } catch (e) {
      developer.log('PhrasesRepository: Firestore error: $e');
    }
  }

  Future<void> markRecorded(int phraseIndex) async {
    if (_recordedPhraseIndices.add(phraseIndex)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          recordedPhraseIndicesKey, jsonEncode(_recordedPhraseIndices.toList()));
      notifyListeners();
    }
  }

  Future<void> unmarkRecorded(int phraseIndex) async {
    if (_recordedPhraseIndices.remove(phraseIndex)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          recordedPhraseIndicesKey, jsonEncode(_recordedPhraseIndices.toList()));
      notifyListeners();
    }
  }

  Future<int> getLastRecordedPhraseIndex() async {
    return (await SharedPreferences.getInstance())
            .getInt(lastRecordedPhraseIndexKey) ??
        0;
  }

  void reset({required List<Phrase> updatedPhrases}) {
    _phrases.clear();
    _phrases.addAll(updatedPhrases);
    jumpToPhrase(updatedPhraseIndex: _currentPhraseIndex);
    notifyListeners();
  }

  Future<void> jumpToPhrase({required int updatedPhraseIndex}) async {
    if (_currentPhraseIndex == updatedPhraseIndex) {
      return;
    }
    _currentPhraseIndex = updatedPhraseIndex;
    var prefs = await SharedPreferences.getInstance();
    prefs.setInt(lastRecordedPhraseIndexKey, _currentPhraseIndex);
    notifyListeners();
  }

  Future<void> moveToNextPhrase() async {
    jumpToPhrase(updatedPhraseIndex: currentPhraseIndex + 1);
  }

  Future<void> moveToPreviousPhrase() async {
    jumpToPhrase(updatedPhraseIndex: currentPhraseIndex - 1);
  }
}
