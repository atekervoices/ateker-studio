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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../repos/auth_repository.dart';
import '../repos/validation_repository.dart';
import '../ui/core/themes/colors.dart';
import '../ui/core/widgets/standard_app_bar.dart';

// ── Widget ────────────────────────────────────────────────────────────────────

class ValidateModeController extends StatefulWidget {
  const ValidateModeController({super.key});

  @override
  State<ValidateModeController> createState() => _ValidateModeControllerState();
}

// ── State ─────────────────────────────────────────────────────────────────────

class _ValidateModeControllerState extends State<ValidateModeController> {
  ValidationRepository? _repo;

  // Audio playback
  VideoPlayerController? _playerController;
  bool _isDownloading = false;
  bool _isPlaying = false;
  bool _hasPlayed = false;

  // Submission
  bool _isSubmitting = false;
  String? _downloadError;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _repo = Provider.of<ValidationRepository>(context, listen: false);
    _repo!.addListener(_onRepoChanged);

    // Only trigger load when the user is actually signed in.
    final auth = Provider.of<AuthRepository>(context, listen: false);
    if (auth.currentUser != null) {
      _repo!.loadQueue();
    }
  }

  @override
  void dispose() {
    _repo?.removeListener(_onRepoChanged);
    _playerController?.dispose();
    super.dispose();
  }

  // ── Repo listener ──────────────────────────────────────────────────────────

  /// Called whenever [ValidationRepository] notifies listeners.
  /// Rebuilds the UI and auto-loads audio for the first queued recording
  /// once the initial queue fetch completes.
  void _onRepoChanged() {
    if (!mounted) return;
    setState(() {}); // propagate repo state to UI

    // Auto-start audio download when the queue first becomes available.
    if (!_repo!.isLoading &&
        !_isSubmitting &&
        _repo!.currentRecording != null &&
        _playerController == null &&
        !_isDownloading) {
      _loadAudio(_repo!.currentRecording!);
    }
  }

  // ── Audio helpers ──────────────────────────────────────────────────────────

  /// Downloads the audio for [item] from Firebase Storage, initialises a
  /// [VideoPlayerController] and wires up the playback-state listener.
  Future<void> _loadAudio(RecordingToValidate item) async {
    if (!mounted) return;
    setState(() {
      _isDownloading = true;
      _downloadError = null;
    });

    try {
      final path = await _repo!.downloadAudio(item.recordingPath);
      if (!mounted) return;

      final controller = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(path))
          : VideoPlayerController.file(File(path));
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Mirror playback state into our local _isPlaying flag.
      controller.addListener(() {
        if (!mounted) return;
        setState(() => _isPlaying = controller.value.isPlaying);
      });

      // Swap out the old controller safely.
      final old = _playerController;
      setState(() {
        _playerController = controller;
        _isDownloading = false;
      });
      await old?.dispose();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadError = 'Could not load audio. Tap to retry.';
      });
    }
  }

  /// Toggles playback. Pausing also resets the position to the beginning so
  /// a subsequent tap always re-plays from the start.
  void _togglePlay() {
    final ctrl = _playerController;
    if (ctrl == null || _isDownloading) return;

    if (_isPlaying) {
      ctrl.pause();
      ctrl.seekTo(Duration.zero);
    } else {
      ctrl.play();
      if (!_hasPlayed) setState(() => _hasPlayed = true);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Submits a validation decision, disposes the current player, and loads
  /// audio for the next recording in the queue.
  Future<void> _validate(bool isValid) async {
    if (_isSubmitting) return;
    final current = _repo?.currentRecording;
    if (current == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _repo!.submitValidation(
        recordingId: current.id,
        ownerUid: current.ownerUid,
        isValid: isValid,
      );

      // Discard the player for the just-validated recording.
      final old = _playerController;
      _playerController = null;
      await old?.dispose();

      if (!mounted) return;
      setState(() {
        _hasPlayed = false;
        _isPlaying = false;
        _isSubmitting = false;
        _downloadError = null;
      });

      // Eagerly load audio for the next recording, if any.
      final next = _repo?.currentRecording;
      if (next != null) await _loadAudio(next);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _downloadError = 'Submission failed. Please try again.';
      });
    }
  }

  /// Moves the current recording to the back of the queue (skip), resets
  /// player state, and loads audio for what is now the first recording.
  void _skip() {
    _repo?.skipCurrent(); // mutates queue + notifies listeners

    final old = _playerController;
    _playerController = null;
    old?.dispose(); // fire-and-forget; we no longer reference this controller

    setState(() {
      _hasPlayed = false;
      _isPlaying = false;
      _downloadError = null;
    });

    final next = _repo?.currentRecording;
    if (next != null) _loadAudio(next); // fire-and-forget async load
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    if (repo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────
          buildStandardSliverAppBar(
            context: context,
            title: 'Validate',
            subtitle: 'Help improve our dataset',
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  label: Text(
                    '${repo.sessionCount} validated',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: AppColors.secondary.withAlpha(40),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
            ],
          ),

          // ── Body ───────────────────────────────────────────────────────
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildBody(context, repo),
          ),
        ],
      ),
    );
  }

  // ── Body dispatch ──────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, ValidationRepository repo) {
    if (repo.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Loading recordings…',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (repo.error != null) return _buildErrorState(context, repo);

    if (repo.currentRecording == null) return _buildEmptyState(context, repo);

    return _buildValidationCard(context, repo, repo.currentRecording!);
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildErrorState(BuildContext context, ValidationRepository repo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: AppColors.red1,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  repo.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: repo.loadQueue,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty / all-caught-up state ────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, ValidationRepository repo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            const Text(
              "You're all caught up!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No recordings to validate right now.\nCheck back later.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: repo.loadQueue,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main validation card ───────────────────────────────────────────────────

  Widget _buildValidationCard(
    BuildContext context,
    ValidationRepository repo,
    RecordingToValidate recording,
  ) {
    final isText = recording.promptType == 'text';
    final typeColor = isText ? AppColors.primary : AppColors.secondary;
    final typeLabel = isText ? 'Speech Prompt' : 'Image Description';
    final typeIcon =
        isText ? Icons.text_fields_rounded : Icons.image_rounded;

    // Last 4 characters of ownerUid used as an anonymous identifier.
    final shortId = recording.ownerUid.length >= 4
        ? recording.ownerUid.substring(recording.ownerUid.length - 4)
        : recording.ownerUid;

    final actionsEnabled = _hasPlayed && !_isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Type chip ──────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(typeIcon, color: Colors.white, size: 15),
              label: Text(
                typeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              backgroundColor: typeColor,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
          ),
          const SizedBox(height: 12),

          // ── Prompt text card ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.greylight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recorded prompt:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  recording.promptText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Attribution ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Anonymous recording · #$shortId',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Audio player ───────────────────────────────────────────────
          _buildAudioPlayer(context, recording, typeColor),
          const SizedBox(height: 24),

          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 20),

          // ── Validation question ────────────────────────────────────────
          const Text(
            'Does this recording clearly match\nthe text above?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // ── Action buttons ─────────────────────────────────────────────
          _buildActionButtons(actionsEnabled),

          // ── Listen-first hint ──────────────────────────────────────────
          if (!_hasPlayed) ...[
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Listen to the recording first before validating',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ── Session counter ────────────────────────────────────────────
          _buildSessionCounter(repo),
        ],
      ),
    );
  }

  // ── Audio player widget ────────────────────────────────────────────────────

  Widget _buildAudioPlayer(
    BuildContext context,
    RecordingToValidate recording,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : AppColors.grey1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greylight),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Error state ──────────────────────────────────────────────
          if (_downloadError != null) ...[
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.red1,
            ),
            const SizedBox(height: 10),
            Text(
              _downloadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.red1, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _loadAudio(recording),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: accentColor),
            ),
          ]

          // ── Loading / ready state ────────────────────────────────────
          else ...[
            // Icon + label
            Icon(
              _hasPlayed ? Icons.graphic_eq_rounded : Icons.mic_rounded,
              size: 36,
              color: accentColor,
            ),
            const SizedBox(height: 8),
            Text(
              _hasPlayed ? 'Tap to replay' : 'Tap to listen',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),

            // Spinner while downloading/initialising; play button once ready.
            if (_isDownloading || _playerController == null)
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              GestureDetector(
                onTap: _togglePlay,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Action buttons row ─────────────────────────────────────────────────────

  Widget _buildActionButtons(bool actionsEnabled) {
    return Row(
      children: [
        // Poor Quality ────────────────────────────────────────────────────
        Expanded(
          child: OutlinedButton.icon(
            onPressed: actionsEnabled ? () => _validate(false) : null,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Poor Quality'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  actionsEnabled ? AppColors.red1 : Colors.grey.shade400,
              side: BorderSide(
                color: actionsEnabled
                    ? AppColors.red1
                    : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Skip ─────────────────────────────────────────────────────────────
        TextButton(
          onPressed: actionsEnabled ? _skip : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: const Text('Skip'),
        ),
        const SizedBox(width: 8),

        // Sounds Good ──────────────────────────────────────────────────────
        Expanded(
          child: ElevatedButton.icon(
            onPressed: actionsEnabled ? () => _validate(true) : null,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Sounds Good'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  actionsEnabled ? Colors.green.shade600 : Colors.grey.shade300,
              foregroundColor:
                  actionsEnabled ? Colors.white : Colors.grey.shade500,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              elevation: actionsEnabled ? 2 : 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Session counter ────────────────────────────────────────────────────────

  Widget _buildSessionCounter(ValidationRepository repo) {
    final count = repo.sessionCount;
    final hasValidated = count > 0;
    final bgColor = hasValidated ? Colors.green.shade50 : Colors.grey.shade100;
    final iconColor =
        hasValidated ? Colors.green.shade600 : Colors.grey.shade400;
    final textColor =
        hasValidated ? Colors.green.shade700 : Colors.grey.shade500;
    final label = hasValidated
        ? '$count recording${count == 1 ? '' : 's'} validated this session'
        : '0 recordings validated this session';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasValidated
                ? Icons.check_circle_rounded
                : Icons.check_circle_outline_rounded,
            color: iconColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight:
                  hasValidated ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
