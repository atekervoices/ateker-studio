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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/image_phrase.dart';
import '../repos/audio_player.dart';
import '../repos/audio_recorder.dart';
import '../repos/image_prompts_repository.dart';

import '../repos/settings_repository.dart';
import '../ui/core/themes/colors.dart';
import '../ui/core/widgets/standard_app_bar.dart';
import 'image_prompt_view.dart';

class ImagePromptController extends StatefulWidget {
  const ImagePromptController({super.key});

  @override
  State<ImagePromptController> createState() => _ImagePromptControllerState();
}

class _ImagePromptControllerState extends State<ImagePromptController> {
  bool _isInitialized = false;

  int? _lastLoadedImageId;

  Future<void> _loadImageAudio(AudioPlayer player, ImagePhrase imagePhrase) async {
    final imageAudioPath = await imagePhrase.localRecordingPath;
    await player.load(audioPath: imageAudioPath);
  }

  Future<void> _deleteImageRecording(
      ImagePhrase imagePhrase, AudioPlayer player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text(
            'This will delete the local copy so you can re-record. Your previously uploaded recording is preserved in the cloud.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await imagePhrase.deleteRecording();
    if (!mounted) return;
    Provider.of<ImagePromptsRepository>(context, listen: false)
        .unmarkRecorded(imagePhrase.index);
    await player.load(audioPath: null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recording deleted')),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    final repo = Provider.of<ImagePromptsRepository>(context, listen: false);
    await repo.initFromAssetFile();

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _stopRecordingAndUpload(
      AudioRecorder recorder, ImagePhrase imagePhrase, AudioPlayer player) async {
    if (!recorder.isRecording) {
      // Set up audio path before starting recording
      recorder.updateAudioPathForPhrase(imagePhrase);
      recorder.start();
      return;
    }
    await recorder.stop();
    if (!mounted) return;
    final imagesRepo = Provider.of<ImagePromptsRepository>(context, listen: false);
    final wasAlreadyRecorded = imagesRepo.isRecorded(imagePhrase.index);
    imagesRepo.markAsRecorded(imagePhrase.index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasAlreadyRecorded ? 'Re-recording saved' : 'Recording saved',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    unawaited(imagePhrase.uploadRecording());
    if (!mounted) return;
    if (Provider.of<SettingsRepository>(context, listen: false).autoAdvance) {
      final repo = Provider.of<ImagePromptsRepository>(context, listen: false);
      if (repo.currentImageIndex < repo.totalImageCount - 1) {
        await repo.nextImage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer3<ImagePromptsRepository, AudioPlayer, AudioRecorder>(
        builder: (_, repo, player, recorder, __) {
      if (repo.totalImageCount == 0) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: buildStandardAppBar(
            context: context,
            title: 'Describe Images',
            subtitle: 'Say what you see in the picture',
          ),
          body: const Center(
            child: Text('No image prompts available'),
          ),
        );
      }

      final currentImage = repo.currentImage;
      if (currentImage == null) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final imagePhrase = ImagePhrase(
        index: currentImage.id,
        text: currentImage.description,
      );
      final isRecorded = repo.isRecorded(currentImage.id);
      // Schedule audio loading after the frame to avoid
      // setState/notifyListeners being called during build.
      if (_lastLoadedImageId != currentImage.id) {
        _lastLoadedImageId = currentImage.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_loadImageAudio(player, imagePhrase));
        });
      }

      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: buildStandardAppBar(
          context: context,
          title: 'Describe Images',
          subtitle: 'Say what you see in the picture',
          actions: [

            if (isRecorded)
              IconButton(
                tooltip: 'Delete recording',
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
                onPressed: () =>
                    _deleteImageRecording(imagePhrase, player),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '${repo.currentImageIndex + 1} / ${repo.totalImageCount}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ImagePromptView(),
        bottomNavigationBar: _buildBottomNavigationBar(
          context,
          repo,
          player,
          recorder,
          imagePhrase,
        ),
      );
    });
  }

  Widget _buildBottomNavigationBar(BuildContext context, ImagePromptsRepository repo, AudioPlayer player, AudioRecorder recorder, ImagePhrase imagePhrase) {
    final currentImage = repo.currentImage;
    if (currentImage == null) return const SizedBox.shrink();

    final isRecorded = repo.isRecorded(currentImage.id);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Navigation controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  onPressed: repo.currentImageIndex > 0
                      ? () async { await repo.previousImage(); }
                      : null,
                  iconSize: 36,
                  icon: const Icon(Icons.skip_previous),
                ),
                const SizedBox(width: 16),
                IconButton.outlined(
                  onPressed: player.canPlay && !recorder.isRecording
                      ? () {
                          if (player.isPlaying) {
                            player.pause();
                          } else {
                            unawaited(() async {
                              await _loadImageAudio(player, imagePhrase);
                              await player.play();
                            }());
                          }
                        }
                      : null,
                  iconSize: 36,
                  icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 16),
                IconButton.outlined(
                  onPressed: repo.currentImageIndex < repo.totalImageCount - 1
                      ? () async { await repo.nextImage(); }
                      : null,
                  iconSize: 36,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Recording button — full width, compact height
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: player.isPlaying
                    ? null
                    : () => _stopRecordingAndUpload(recorder, imagePhrase, player),
                style: FilledButton.styleFrom(
                  backgroundColor: recorder.isRecording
                      ? AppColors.secondary
                      : (isRecorded
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                icon: Icon(
                  recorder.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  recorder.isRecording
                      ? 'Stop Recording'
                      : (isRecorded ? 'Re-record' : 'Record'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
