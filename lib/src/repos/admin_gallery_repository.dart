import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ateker_storage_service.dart';

class GalleryImage {
  final String id;
  final String url;
  final String caption;
  final DateTime createdAt;

  GalleryImage({
    required this.id,
    required this.url,
    required this.caption,
    required this.createdAt,
  });

  factory GalleryImage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryImage(
      id: doc.id,
      url: data['url'] ?? '',
      caption: data['caption'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class AdminGalleryRepository extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<GalleryImage> _images = [];
  List<GalleryImage> get images => _images;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadGallery() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('admin_gallery')
          .orderBy('createdAt', descending: true)
          .get();
      
      _images = snapshot.docs.map((doc) => GalleryImage.fromFirestore(doc)).toList();
    } catch (e) {
      _error = 'Failed to load gallery: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadImage({
    required Uint8List imageData,
    required String fileName,
    required String caption,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Upload to Storage
      final objectPath = 'admin_gallery/$fileName';
      await AtekerStorageService.instance.uploadData(
        objectPath,
        imageData,
        contentType: 'image/jpeg',
      );
      final url = await AtekerStorageService.instance.getDownloadUrl(objectPath);

      // 2. Save to Firestore
      await _firestore.collection('admin_gallery').add({
        'url': url,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await loadGallery();
    } catch (e) {
      _error = 'Failed to upload image: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteImage(String id, String url) async {
    try {
      // 1. Delete from Storage
      await AtekerStorageService.instance.deleteObjectByUrl(url);
      
      // 2. Delete from Firestore
      await _firestore.collection('admin_gallery').doc(id).delete();
      
      await loadGallery();
    } catch (e) {
      _error = 'Failed to delete image: $e';
      notifyListeners();
      rethrow;
    }
  }
}
