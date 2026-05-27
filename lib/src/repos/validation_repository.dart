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
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

/// A single recording submitted by another user that is awaiting quality
/// validation by the current user.
class RecordingToValidate {
  /// Firestore document ID of the recording.
  final String id;

  /// UID of the user who created the recording.
  final String ownerUid;

  /// The text the speaker was asked to read (or describe).
  final String promptText;

  /// Either `'text'` (speech prompt) or `'image'` (image description prompt).
  final String promptType;

  /// Zero-based index of the prompt in the prompt list.
  final int promptIndex;

  /// Firebase Storage path for the audio file (e.g. `recordings/uid/file.wav`).
  final String recordingPath;

  /// When the recording was uploaded.
  final DateTime uploadedAt;

  const RecordingToValidate({
    required this.id,
    required this.ownerUid,
    required this.promptText,
    required this.promptType,
    required this.promptIndex,
    required this.recordingPath,
    required this.uploadedAt,
  });

  factory RecordingToValidate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RecordingToValidate(
      id: doc.id,
      ownerUid: (data['ownerUid'] as String?) ?? '',
      promptText: (data['promptText'] as String?) ?? '',
      promptType: (data['promptType'] as String?) ?? 'text',
      promptIndex: (data['promptIndex'] as int?) ?? 0,
      recordingPath: (data['recordingPath'] as String?) ?? '',
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

/// Manages the queue of recordings that the current user can validate and
/// persists validation decisions to Firestore.
final class ValidationRepository extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final List<RecordingToValidate> _queue = [];
  bool _isLoading = false;
  String? _error;
  int _sessionCount = 0;

  // ── Getters ────────────────────────────────────────────────────────────────

  /// Whether a queue-load operation is in progress.
  bool get isLoading => _isLoading;

  /// Non-null when the last [loadQueue] call failed.
  String? get error => _error;

  /// An unmodifiable view of the recordings currently awaiting validation.
  UnmodifiableListView<RecordingToValidate> get queue =>
      UnmodifiableListView(_queue);

  /// Number of recordings validated since this repository instance was created.
  int get sessionCount => _sessionCount;

  /// The next recording to validate, or `null` when the queue is empty.
  RecordingToValidate? get currentRecording =>
      _queue.isEmpty ? null : _queue.first;

  // ── Public methods ─────────────────────────────────────────────────────────

  /// Fetches up to 30 recordings from Firestore, excludes the current user's
  /// own recordings and recordings they have already validated, then stores the
  /// filtered list in [queue] sorted newest-first by [uploadedAt].
  Future<void> loadQueue() async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      _error = 'You must be signed in to validate recordings.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch up to 30 recordings.
      //    No server-side where-filter is applied here so we avoid requiring a
      //    composite Firestore index; sorting is done client-side instead.
      final recordingsSnap =
          await _firestore.collection('recordings').limit(30).get();

      // Sort descending by uploadedAt (newest first).
      final allDocs = recordingsSnap.docs.toList()
        ..sort((a, b) {
          final aMs =
              (a.data()['uploadedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                  0;
          final bMs =
              (b.data()['uploadedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                  0;
          return bMs.compareTo(aMs);
        });

      // 2. Collect the IDs of recordings this user has already validated.
      final validationsSnap = await _firestore
          .collection('validations')
          .where('validatorUid', isEqualTo: currentUid)
          .get();

      final validatedIds = <String>{
        for (final doc in validationsSnap.docs)
          (doc.data()['recordingId'] as String?) ?? '',
      }..remove(''); // drop any blank sentinel

      // 3. Build the filtered queue:
      //    – exclude the user's own recordings
      //    – exclude recordings they have already reviewed
      final filtered = <RecordingToValidate>[];
      for (final doc in allDocs) {
        final rec = RecordingToValidate.fromFirestore(doc);
        if (rec.ownerUid == currentUid) continue;
        if (validatedIds.contains(rec.id)) continue;
        filtered.add(rec);
      }

      _queue
        ..clear()
        ..addAll(filtered);

      developer.log(
        'ValidationRepository: ${_queue.length} recordings queued for validation.',
      );
    } catch (e, st) {
      developer.log('ValidationRepository.loadQueue error: $e\n$st');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Writes a validation decision document to Firestore and removes the
  /// recording from the local [queue]. Also increments [sessionCount].
  Future<void> submitValidation({
    required String recordingId,
    required String ownerUid,
    required bool isValid,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) throw StateError('Not signed in.');

    await _firestore.collection('validations').add({
      'recordingId': recordingId,
      'ownerUid': ownerUid,
      'validatorUid': currentUid,
      'isValid': isValid,
      'validatedAt': FieldValue.serverTimestamp(),
    });

    _queue.removeWhere((r) => r.id == recordingId);
    _sessionCount++;
    notifyListeners();
  }

  /// Moves the current (first) recording to the end of the queue so the user
  /// can revisit it after reviewing other entries.
  void skipCurrent() {
    if (_queue.isEmpty) return;
    final first = _queue.removeAt(0);
    _queue.add(first);
    notifyListeners();
  }

  /// Downloads audio bytes from Firebase Storage and writes them to a
  /// temporary file (`validate_audio.wav` in the system temp directory).
  ///
  /// Returns the absolute file-system path of the written file.
  ///
  /// Throws on network/storage error or when Storage returns no data.
  Future<String> downloadAudio(String storagePath) async {
    final ref = _storage.ref(storagePath);
    if (kIsWeb) {
      return await ref.getDownloadURL();
    }

    // 15 MB cap – more than enough for a short speech recording.
    final data = await ref.getData(15 * 1024 * 1024);
    if (data == null) {
      throw Exception('Firebase Storage returned no data for: $storagePath');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/validate_audio.wav');
    await file.writeAsBytes(data, flush: true);
    return file.path;
  }
}
