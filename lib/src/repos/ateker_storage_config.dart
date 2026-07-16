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

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

abstract final class AtekerStorageConfig {
  static String get defaultEndpoint {
    if (kIsWeb) {
      return 'localhost';
    }
    // If running on Android emulator, redirect to host's localhost (10.0.2.2)
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static const int port = 9800; // Unique port requested by user
  static const String accessKey = 'minioadmin';
  static const String secretKey = 'minioadmin';
  static const bool useSSL = false;
  static const String bucket = 'ateker-voices';
}
