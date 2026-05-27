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

enum ImagePromptTopic {
  animals('Animals'),
  food('Food'),
  nature('Nature'),
  objects('Objects'),
  people('People');

  const ImagePromptTopic(this.displayName);
  final String displayName;
}

class ImagePrompt {
  final int id;
  final String filename;
  final ImagePromptTopic topic;
  final String description;

  const ImagePrompt({
    required this.id,
    required this.filename,
    required this.topic,
    required this.description,
  });

  factory ImagePrompt.fromJson(Map<String, dynamic> json) {
    return ImagePrompt(
      id: json['id'] as int,
      filename: json['filename'] as String,
      topic: ImagePromptTopic.values.firstWhere(
        (topic) => topic.name == json['topic'],
        orElse: () => ImagePromptTopic.objects,
      ),
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'topic': topic.name,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImagePrompt &&
        other.id == id &&
        other.filename == filename &&
        other.topic == topic &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        filename.hashCode ^
        topic.hashCode ^
        description.hashCode;
  }

  @override
  String toString() {
    return 'ImagePrompt(id: $id, filename: $filename, topic: $topic, description: $description)';
  }
}
