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

import '../models/image_prompt.dart';

final class ImagePromptsRepository extends ChangeNotifier {
  static const lastRecordedImageIndexKey = 'LAST_RECORDED_IMAGE_INDEX_KEY';
  static const recordedImageIndicesKey = 'RECORDED_IMAGE_INDICES_V1';

  final List<ImagePrompt> _imagePrompts = [];
  int _currentImageIndex = 0;
  final Set<int> _recordedImageIndices = <int>{};
  Future<void>? _loadingFuture;

  UnmodifiableListView<ImagePrompt> get imagePrompts =>
      UnmodifiableListView(_imagePrompts);
  int get currentImageIndex => _currentImageIndex;
  int get recordedCount => _recordedImageIndices.length;
  int get totalImageCount => _imagePrompts.length;
  bool isRecorded(int imageIndex) => _recordedImageIndices.contains(imageIndex);
  ImagePrompt? get currentImage =>
      _currentImageIndex < 0 || _currentImageIndex >= _imagePrompts.length
          ? null
          : _imagePrompts[_currentImageIndex];

  List<ImagePrompt> get filteredImages {
    return _imagePrompts
        .where((image) => isRecorded(image.id) == false)
        .toList();
  }

  /// Initialises image prompts. On the first call it loads from Firestore
  /// (admin-created prompts with kind == 'image'). Subsequent calls reuse the
  /// same in-flight future so the data is only fetched once.
  Future<void> initFromAssetFile() {
    _loadingFuture ??= _loadImagePrompts();
    return _loadingFuture!;
  }

  Future<void> _loadImagePrompts() async {
    final prefs = await SharedPreferences.getInstance();

    // Restore saved progress.
    _currentImageIndex = prefs.getInt(lastRecordedImageIndexKey) ?? 0;
    final recordedRaw = prefs.getString(recordedImageIndicesKey);
    _recordedImageIndices.clear();
    if (recordedRaw != null && recordedRaw.isNotEmpty) {
      final decoded = jsonDecode(recordedRaw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is int) _recordedImageIndices.add(item);
        }
      }
    }

    // Load from Firestore admin_prompts (kind == 'image')
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('admin_prompts')
          .where('kind', isEqualTo: 'image')
          .get();

      // Sort client-side by createdAt (oldest first) — avoids a composite index.
      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return aTime.compareTo(bTime);
        });

      final prompts = <ImagePrompt>[];
      for (var i = 0; i < docs.length; i++) {
        final data = docs[i].data();
        final imageUrl = (data['imageUrl'] as String?) ?? '';
        final text = (data['text'] as String?) ?? '';
        if (imageUrl.isNotEmpty) {
          prompts.add(ImagePrompt(
            id: i,
            filename: imageUrl,
            topic: ImagePromptTopic.values.firstWhere(
              (t) => t.name == (data['topic'] as String?),
              orElse: () => ImagePromptTopic.objects,
            ),
            description: text,
          ));
        }
      }
      _imagePrompts
        ..clear()
        ..addAll(prompts);
      developer.log(
          'ImagePromptsRepository: loaded ${prompts.length} image prompts from Firestore');
      // Clamp saved index to valid range after loading
      if (_imagePrompts.isNotEmpty) {
        _currentImageIndex = _currentImageIndex.clamp(0, _imagePrompts.length - 1);
      }
      notifyListeners();
    } catch (e) {
      developer.log('ImagePromptsRepository: Firestore error: $e');
    }
  }

  void _createDefaultPrompts() {
    _imagePrompts.addAll([
      const ImagePrompt(
        id: 1,
        filename: 'assets/farm.jpg',
        topic: ImagePromptTopic.nature,
        description: 'A peaceful farm scene with animals and fields',
      ),
      const ImagePrompt(
        id: 2,
        filename: 'assets/food.jpg',
        topic: ImagePromptTopic.food,
        description: 'A delicious meal ready to be enjoyed',
      ),
      const ImagePrompt(
        id: 3,
        filename: 'assets/nature.jpg',
        topic: ImagePromptTopic.nature,
        description: 'Beautiful natural landscape',
      ),
    ]);
    notifyListeners();
  }

  Future<void> markAsRecorded(int imageId) async {
    _recordedImageIndices.add(imageId);
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      recordedImageIndicesKey,
      jsonEncode(_recordedImageIndices.toList()),
    );
    notifyListeners();
  }

  Future<void> unmarkRecorded(int imageId) async {
    if (_recordedImageIndices.remove(imageId)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        recordedImageIndicesKey,
        jsonEncode(_recordedImageIndices.toList()),
      );
      notifyListeners();
    }
  }

  Future<void> nextImage() async {
    if (_currentImageIndex < _imagePrompts.length - 1) {
      _currentImageIndex++;
      await _saveCurrentIndex();
      notifyListeners();
    }
  }

  Future<void> previousImage() async {
    if (_currentImageIndex > 0) {
      _currentImageIndex--;
      await _saveCurrentIndex();
      notifyListeners();
    }
  }

  Future<void> setCurrentImageIndex(int index) async {
    if (index >= 0 && index < _imagePrompts.length) {
      _currentImageIndex = index;
      await _saveCurrentIndex();
      notifyListeners();
    }
  }

  Future<void> _saveCurrentIndex() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lastRecordedImageIndexKey, _currentImageIndex);
  }

  List<ImagePrompt> getImagesByTopic(ImagePromptTopic topic) {
    return _imagePrompts.where((image) => image.topic == topic).toList();
  }

  Future<void> resetProgress() async {
    _recordedImageIndices.clear();
    _currentImageIndex = 0;

    var prefs = await SharedPreferences.getInstance();
    await prefs.remove(recordedImageIndicesKey);
    await prefs.setInt(lastRecordedImageIndexKey, 0);

    notifyListeners();
  }
}
