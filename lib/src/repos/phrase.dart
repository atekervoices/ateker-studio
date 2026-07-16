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

import 'dart:io';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'web_audio_cache.dart';
import 'ateker_storage_service.dart';

final class Phrase {
  final int index;
  final String text;

  Phrase({required this.index, required this.text});

  Future<bool> get isRecordingAvailableLocally => kIsWeb
      ? Future.value(WebAudioCache.getAudioUrl(index) != null)
      : localRecordingPath.then((x) => File(x).existsSync());

  Future<String> get localRecordingPath => kIsWeb
      ? Future.value(WebAudioCache.getAudioUrl(index) ?? '')
      : getApplicationDocumentsDirectory().then(
          (value) => '${value.path}/prompt$index.wav',
        );

  Future<String> get localTempPath => kIsWeb
      ? Future.value('')
      : getApplicationDocumentsDirectory().then(
          (value) => '${value.path}/prompt_temp_$index.wav',
        );

  Future<void> downloadRecording() async {
    if (kIsWeb) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final objectPath = uid == null
        ? 'data/$index/recording.wav'
        : 'users/$uid/data/$index/recording.wav';
    final localAudioFile = File(await localRecordingPath);
    final data = await AtekerStorageService.instance.downloadData(objectPath);
    if (data.isEmpty) {
      throw FileSystemException("File doesn't exist", objectPath);
    }
    localAudioFile.writeAsBytesSync(data);
  }

  Future<void> uploadRecording() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final phrasePath = uid == null
        ? 'data/$index/phrase.txt'
        : 'users/$uid/data/$index/phrase.txt';
    final audioPath = uid == null
        ? 'data/$index/recording.wav'
        : 'users/$uid/data/$index/recording.wav';

    if (kIsWeb) {
      final blobUrl = WebAudioCache.getAudioUrl(index);
      if (blobUrl == null) {
        throw Exception('No recording found to upload');
      }
      final response = await http.get(Uri.parse(blobUrl));
      await Future.wait([
        AtekerStorageService.instance.uploadString(phrasePath, text),
        AtekerStorageService.instance.uploadData(audioPath, response.bodyBytes, contentType: 'audio/wav'),
      ]);
    } else {
      final audioPathLocal = await localRecordingPath;
      final localAudioFile = File(audioPathLocal);
      if (!localAudioFile.existsSync()) {
        throw FileSystemException("File doesn't exist", audioPathLocal);
      }
      await Future.wait([
        AtekerStorageService.instance.uploadString(phrasePath, text),
        AtekerStorageService.instance.uploadFile(audioPath, localAudioFile, contentType: 'audio/wav'),
      ]);
    }

    // Register for community validation (non-critical)
    try {
      await FirebaseFirestore.instance
          .collection('recordings')
          .doc('${uid ?? "anon"}_text_$index')
          .set({
        'ownerUid': uid ?? 'anonymous',
        'promptText': text,
        'promptType': 'text',
        'promptIndex': index,
        'recordingPath': uid == null
            ? 'data/$index/recording.wav'
            : 'users/$uid/data/$index/recording.wav',
        'uploadedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log('Phrase: failed to register recording: $e');
    }
  }

  /// Deletes only the LOCAL recording file so the user can re-record.
  /// Cloud copies (Firebase Storage + Firestore) are intentionally preserved
  /// as part of the dataset.
  Future<void> deleteRecording() async {
    if (kIsWeb) {
      WebAudioCache.setAudioUrl(index, null);
      return;
    }
    final localFile = File(await localRecordingPath);
    if (localFile.existsSync()) await localFile.delete();
  }
}
