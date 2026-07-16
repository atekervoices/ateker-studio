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
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/image_prompt.dart';
import 'ateker_storage_service.dart';

class AdminPromptsRepository extends ChangeNotifier {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;

  static const String _promptsCollection = 'admin_prompts';
  static const String _promptImagesFolder = 'admin_prompt_images';

  List<AdminPromptItem> _prompts = [];
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  UnmodifiableListView<AdminPromptItem> get prompts =>
      UnmodifiableListView(_prompts);
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminPromptsRepository() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
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

  Future<void> loadPrompts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final querySnapshot =
          await _firestore.collection(_promptsCollection).orderBy('createdAt', descending: true).get();

      _prompts = querySnapshot.docs
          .map((doc) => AdminPromptItem.fromFirestore(doc))
          .toList();
      _error = null;
    } catch (e) {
      developer.log('Error loading prompts: $e');
      _error = 'Failed to load prompts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPrompt({
    required String kind,
    required String text,
    required ImagePromptTopic topic,
    Uint8List? imageData,
    required String imageFileName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      String? imageUrl;
      if (imageData != null && imageData.isNotEmpty) {
        imageUrl = await _uploadImage(imageFileName, imageData);
      }

      final newPrompt = AdminPromptItem(
        id: '',
        kind: kind,
        text: text,
        topic: topic,
        imageUrl: imageUrl,
        imageFileName: imageFileName,
        createdAt: DateTime.now(),
        createdBy: uid,
      );

      final docRef =
          await _firestore.collection(_promptsCollection).add(newPrompt.toFirestore());
      
      newPrompt.id = docRef.id;
      _prompts.insert(0, newPrompt);
      _error = null;
    } catch (e) {
      developer.log('Error adding prompt: $e');
      _error = 'Failed to add prompt: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPromptsBatch(List<AdminPromptItem> newPrompts) async {
    if (newPrompts.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      final List<AdminPromptItem> savedPrompts = [];

      for (final prompt in newPrompts) {
        final docRef = _firestore.collection(_promptsCollection).doc();
        
        final savedPrompt = AdminPromptItem(
          id: docRef.id,
          kind: prompt.kind,
          text: prompt.text,
          topic: prompt.topic,
          imageUrl: prompt.imageUrl,
          imageFileName: prompt.imageFileName.isNotEmpty
              ? prompt.imageFileName
              : 'prompt_${docRef.id}.jpg',
          createdAt: DateTime.now(),
          createdBy: uid,
        );

        batch.set(docRef, savedPrompt.toFirestore());
        savedPrompts.add(savedPrompt);
      }

      await batch.commit();

      _prompts.insertAll(0, savedPrompts);
      _error = null;
    } catch (e) {
      developer.log('Error batch adding prompts: $e');
      _error = 'Failed to upload prompts: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePrompt({
    required String promptId,
    required String text,
    required String kind,
    required ImagePromptTopic topic,
    Uint8List? imageData,
    required String imageFileName,
    String? existingImageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? imageUrl = existingImageUrl;
      
      if (imageData != null && imageData.isNotEmpty) {
        imageUrl = await _uploadImage(imageFileName, imageData);
      }

      final updates = {
        'kind': kind,
        'text': text,
        'topic': topic.name,
        'imageUrl': imageUrl,
        'imageFileName': imageFileName,
        'updatedAt': DateTime.now(),
      };

      await _firestore
          .collection(_promptsCollection)
          .doc(promptId)
          .update(updates);

      final index = _prompts.indexWhere((p) => p.id == promptId);
      if (index != -1) {
        _prompts[index] = AdminPromptItem(
          id: promptId,
          kind: kind,
          text: text,
          topic: topic,
          imageUrl: imageUrl,
          imageFileName: imageFileName,
          createdAt: _prompts[index].createdAt,
          createdBy: _prompts[index].createdBy,
        );
      }
      _error = null;
    } catch (e) {
      developer.log('Error updating prompt: $e');
      _error = 'Failed to update prompt: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePrompt(String promptId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection(_promptsCollection).doc(promptId).delete();

      _prompts.removeWhere((p) => p.id == promptId);
      _error = null;
    } catch (e) {
      developer.log('Error deleting prompt: $e');
      _error = 'Failed to delete prompt: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _uploadImage(String fileName, Uint8List imageData) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    final objectPath = '$_promptImagesFolder/$uid/$fileName';
    await AtekerStorageService.instance.uploadData(
      objectPath,
      imageData,
      contentType: 'image/jpeg',
    );

    return await AtekerStorageService.instance.getDownloadUrl(objectPath);
  }

  Future<void> deleteImage(String imageFileName) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final objectPath = '$_promptImagesFolder/$uid/$imageFileName';
        await AtekerStorageService.instance.deleteObject(objectPath);
      }
    } catch (e) {
      developer.log('Error deleting image: $e');
    }
  }
}

class AdminPromptItem {
  String id;
  final String kind; // 'text' or 'image'
  final String text;
  final ImagePromptTopic topic;
  final String? imageUrl;
  final String imageFileName;
  final DateTime createdAt;
  final String createdBy;

  AdminPromptItem({
    required this.id,
    required this.kind,
    required this.text,
    required this.topic,
    this.imageUrl,
    required this.imageFileName,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'kind': kind,
      'text': text,
      'topic': topic.name,
      'imageUrl': imageUrl,
      'imageFileName': imageFileName,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  factory AdminPromptItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminPromptItem(
      id: doc.id,
      kind: (data['kind'] as String?) ?? 'image',
      text: data['text'] ?? '',
      topic: ImagePromptTopic.values.firstWhere(
        (topic) => topic.name == data['topic'],
        orElse: () => ImagePromptTopic.objects,
      ),
      imageUrl: data['imageUrl'],
      imageFileName: data['imageFileName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }
}
