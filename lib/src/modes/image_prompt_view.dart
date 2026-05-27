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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/image_prompt.dart';
import '../modes/upload_status.dart';
import '../repos/image_prompts_repository.dart';
import '../repos/uploader.dart';

class ImagePromptView extends StatelessWidget {
  const ImagePromptView({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Consumer<ImagePromptsRepository>(
            builder: (context, repo, child) {
              final currentImage = repo.currentImage;
              if (currentImage == null) {
                return const Center(
                  child: Text('No image prompts available'),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Image Display with Flexible to prevent overflow
                    Flexible(
                      child: _buildImageDisplay(context, currentImage),
                    ),
                    const SizedBox(height: 16),
                    
                    // Recording Status
                    _buildRecordingStatus(context, currentImage),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildImageDisplay(BuildContext context, ImagePrompt image) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          height: 300,
          child: image.filename.startsWith('http')
              ? Image.network(
                  image.filename,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      ),
                    );
                  },
                )
              : Image.asset(
                  image.filename,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildRecordingStatus(BuildContext context, ImagePrompt image) {
    return Consumer<Uploader>(
      builder: (context, uploader, child) {
        final imagesRepo = Provider.of<ImagePromptsRepository>(context, listen: false);
        final isRecorded = imagesRepo.isRecorded(image.id);
        final uploadStatus = uploader.statusForPhrase(image.id);
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Upload status icon (only show if recorded)
            if (isRecorded) ...[
              Icon(
                switch (uploadStatus) {
                  UploadStatus.completed => Icons.cloud_done_rounded,
                  UploadStatus.started => Icons.cloud_upload_rounded,
                  UploadStatus.queued => Icons.pending_rounded,
                  UploadStatus.interrupted => Icons.cloud_off_rounded,
                  _ => Icons.cloud_upload_rounded,
                },
                color: switch (uploadStatus) {
                  UploadStatus.completed => Colors.green,
                  UploadStatus.interrupted => Colors.red,
                  UploadStatus.started => Theme.of(context).colorScheme.primary,
                  UploadStatus.queued => Theme.of(context).colorScheme.secondary,
                  _ => Colors.transparent,
                },
              ),
              const SizedBox(width: 8),
            ],
            
          ],
        );
      },
    );
  }
}
