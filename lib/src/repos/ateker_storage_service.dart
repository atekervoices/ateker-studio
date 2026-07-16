// Copyright 2026 Ateker Voices Authors
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
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:minio/minio.dart';
import 'package:path_provider/path_provider.dart';
import 'ateker_storage_config.dart';

class AtekerStorageService {
  static final AtekerStorageService instance = AtekerStorageService._internal();

  AtekerStorageService._internal();

  late final Minio minio = Minio(
    endPoint: AtekerStorageConfig.defaultEndpoint,
    port: AtekerStorageConfig.port,
    accessKey: AtekerStorageConfig.accessKey,
    secretKey: AtekerStorageConfig.secretKey,
    useSSL: AtekerStorageConfig.useSSL,
  );

  bool _bucketExistsChecked = false;

  Future<void> ensureBucketExists() async {
    if (_bucketExistsChecked) return;
    try {
      final exists = await minio.bucketExists(AtekerStorageConfig.bucket);
      if (!exists) {
        await minio.makeBucket(AtekerStorageConfig.bucket);
      }
      _bucketExistsChecked = true;
    } catch (e) {
      print('AtekerStorageService.ensureBucketExists error: $e');
    }
  }

  Future<String> getDownloadUrl(String objectName) async {
    await ensureBucketExists();
    return await minio.presignedGetObject(AtekerStorageConfig.bucket, objectName, expires: 86400);
  }

  Future<void> uploadData(String objectName, Uint8List data, {String? contentType}) async {
    await ensureBucketExists();
    await minio.putObject(
      AtekerStorageConfig.bucket,
      objectName,
      Stream<Uint8List>.value(data),
      size: data.length,
      metadata: contentType != null ? {'Content-Type': contentType} : null,
    );
  }

  Future<void> uploadFile(String objectName, File file, {String? contentType}) async {
    await ensureBucketExists();
    final data = await file.readAsBytes();
    await uploadData(objectName, data, contentType: contentType);
  }

  Future<void> uploadString(String objectName, String content, {String? contentType}) async {
    final data = Uint8List.fromList(content.codeUnits);
    await uploadData(objectName, data, contentType: contentType ?? 'text/plain');
  }

  Future<Uint8List> downloadData(String objectName) async {
    await ensureBucketExists();
    final stream = await minio.getObject(AtekerStorageConfig.bucket, objectName);
    final List<int> bytes = [];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
    return Uint8List.fromList(bytes);
  }

  Future<String> downloadAudioToTemp(String objectName) async {
    if (kIsWeb) {
      return await getDownloadUrl(objectName);
    }
    await ensureBucketExists();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/validate_audio.wav');
    if (file.existsSync()) {
      await file.delete();
    }
    final stream = await minio.getObject(AtekerStorageConfig.bucket, objectName);
    await stream.pipe(file.openWrite());
    return file.path;
  }

  Future<void> deleteObject(String objectName) async {
    await ensureBucketExists();
    await minio.removeObject(AtekerStorageConfig.bucket, objectName);
  }

  Future<void> deleteObjectByUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf(AtekerStorageConfig.bucket);
      if (bucketIdx != -1 && bucketIdx < segments.length - 1) {
        final objectPath = segments.sublist(bucketIdx + 1).join('/');
        await deleteObject(objectPath);
      } else {
        // Fallback
        if (segments.length >= 2) {
          final objectPath = segments.sublist(1).join('/');
          await deleteObject(objectPath);
        }
      }
    } catch (e) {
      print('AtekerStorageService.deleteObjectByUrl error: $e');
    }
  }
}
