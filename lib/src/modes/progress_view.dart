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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repos/image_prompts_repository.dart';
import '../repos/phrases_repository.dart';
import '../repos/uploader.dart';
import '../ui/core/themes/colors.dart';
import '../ui/core/widgets/standard_app_bar.dart';
import 'upload_status.dart';

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Re-run animations every time this tab is revisited
  @override
  void didUpdateWidget(ProgressView old) {
    super.didUpdateWidget(old);
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer3<PhrasesRepository, ImagePromptsRepository, Uploader>(
      builder: (context, phrasesRepo, imageRepo, uploader, _) {
        // ── Stats ──────────────────────────────────────────────────
        final totalPhrases = phrasesRepo.phrases.length;
        final recordedPhrases = phrasesRepo.recordedCount;

        final totalImages = imageRepo.totalImageCount;
        final recordedImages = imageRepo.recordedCount;

        final totalPrompts = totalPhrases + totalImages;
        final totalRecorded = recordedPhrases + recordedImages;

        final overallPct =
            totalPrompts == 0 ? 0.0 : totalRecorded / totalPrompts;
        final phrasesPct =
            totalPhrases == 0 ? 0.0 : recordedPhrases / totalPhrases;
        final imagesPct =
            totalImages == 0 ? 0.0 : recordedImages / totalImages;

        final uploadedCount = uploader.uploadedCount;
        final pendingCount = uploader.queuedCount;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              // ── App Bar ─────────────────────────────────────────
              buildStandardSliverAppBar(
                context: context,
                title: 'Your Progress',
                subtitle: 'Track your recording milestones',
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Overall Ring Card ──────────────────────────
                    _OverallRingCard(
                      animation: _controller,
                      overallPct: overallPct,
                      totalRecorded: totalRecorded,
                      totalPrompts: totalPrompts,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // ── Speech + Images side-by-side ───────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            animation: _controller,
                            icon: Icons.mic_rounded,
                            label: 'Speech',
                            recorded: recordedPhrases,
                            total: totalPhrases,
                            fraction: phrasesPct,
                            color: AppColors.primary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            animation: _controller,
                            icon: Icons.image_rounded,
                            label: 'Images',
                            recorded: recordedImages,
                            total: totalImages,
                            fraction: imagesPct,
                            color: AppColors.secondary,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Upload Status Card ─────────────────────────
                    _UploadCard(
                      animation: _controller,
                      uploadedCount: uploadedCount,
                      pendingCount: pendingCount,
                      uploadStatus: uploader.showProgressIndicator
                          ? UploadStatus.started
                          : pendingCount > 0
                              ? UploadStatus.queued
                              : uploadedCount > 0
                                  ? UploadStatus.completed
                                  : UploadStatus.notStarted,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // ── Breakdown bars ─────────────────────────────
                    _BreakdownCard(
                      animation: _controller,
                      phrasesRepo: phrasesRepo,
                      imageRepo: imageRepo,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // ── Milestone card ─────────────────────────────
                    _MilestoneCard(
                      overallPct: overallPct,
                      totalRecorded: totalRecorded,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Large animated ring showing overall completion
// ─────────────────────────────────────────────────────────────────────────────
class _OverallRingCard extends StatelessWidget {
  final AnimationController animation;
  final double overallPct;
  final int totalRecorded;
  final int totalPrompts;
  final bool isDark;

  const _OverallRingCard({
    required this.animation,
    required this.overallPct,
    required this.totalRecorded,
    required this.totalPrompts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
    final label = _motivationLabel(overallPct);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Completion',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: overallPct * 100),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => Text(
                      '${val.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalRecorded of $totalPrompts recordings',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: overallPct),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: val,
                      ringColor: AppColors.primary,
                      trackColor: isDark
                          ? Colors.white.withAlpha(20)
                          : Colors.black.withAlpha(10),
                      strokeWidth: 10,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.mic_rounded,
                        size: 36,
                        color: AppColors.primary.withAlpha(200),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Full-width linear bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: overallPct),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => _LinearBar(
              fraction: val,
              color: AppColors.primary,
              trackColor:
                  isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(12),
              height: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _motivationLabel(double pct) {
    if (pct == 0) return 'Start recording to see your progress!';
    if (pct < 0.10) return 'Great start — keep it going! 🎉';
    if (pct < 0.25) return "You're building momentum! 🚀";
    if (pct < 0.50) return "Fantastic work — you're making a real difference!";
    if (pct < 0.75) return 'More than halfway there — amazing! 🔥';
    if (pct < 1.00) return "Almost done — finish strong! 🏁";
    return 'All recordings complete! Outstanding work! 🏆';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Speech / Images stat card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final AnimationController animation;
  final IconData icon;
  final String label;
  final int recorded;
  final int total;
  final double fraction;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.animation,
    required this.icon,
    required this.label,
    required this.recorded,
    required this.total,
    required this.fraction,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 18),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: recorded.toDouble()),
            duration: const Duration(milliseconds: 1300),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => Text(
              val.toInt().toString(),
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
              ),
            ),
          ),
          Text(
            'of $total',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: fraction),
            duration: const Duration(milliseconds: 1300),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => _LinearBar(
              fraction: val,
              color: color,
              trackColor: isDark
                  ? Colors.white.withAlpha(18)
                  : Colors.black.withAlpha(10),
              height: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            total == 0
                ? 'No prompts yet'
                : '${(fraction * 100).toStringAsFixed(0)}% complete',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upload status card
// ─────────────────────────────────────────────────────────────────────────────
class _UploadCard extends StatelessWidget {
  final AnimationController animation;
  final int uploadedCount;
  final int pendingCount;
  final UploadStatus uploadStatus;
  final bool isDark;

  const _UploadCard({
    required this.animation,
    required this.uploadedCount,
    required this.pendingCount,
    required this.uploadStatus,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (uploadStatus) {
      case UploadStatus.started:
        statusColor = AppColors.primary;
        statusIcon = Icons.cloud_upload_rounded;
        statusText = 'Uploading…';
        break;
      case UploadStatus.queued:
        statusColor = Colors.amber.shade600;
        statusIcon = Icons.pending_rounded;
        statusText = 'Uploads pending';
        break;
      case UploadStatus.completed:
        statusColor = Colors.green.shade600;
        statusIcon = Icons.cloud_done_rounded;
        statusText = 'All uploads complete';
        break;
      case UploadStatus.interrupted:
        statusColor = Colors.red.shade500;
        statusIcon = Icons.cloud_off_rounded;
        statusText = 'Upload interrupted — will retry';
        break;
      default:
        statusColor = Colors.grey.shade400;
        statusIcon = Icons.cloud_upload_rounded;
        statusText = 'No uploads yet';
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 18),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, size: 20, color: statusColor),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cloud Uploads',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (uploadStatus == UploadStatus.started) ...[
                const Spacer(),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniStatTile(
                  value: uploadedCount,
                  label: 'Uploaded',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  animation: animation,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatTile(
                  value: pendingCount,
                  label: 'Pending',
                  icon: Icons.schedule_rounded,
                  color: Colors.amber.shade600,
                  animation: animation,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-prompt-type breakdown with individual row bars
// ─────────────────────────────────────────────────────────────────────────────
class _BreakdownCard extends StatelessWidget {
  final AnimationController animation;
  final PhrasesRepository phrasesRepo;
  final ImagePromptsRepository imageRepo;
  final bool isDark;

  const _BreakdownCard({
    required this.animation,
    required this.phrasesRepo,
    required this.imageRepo,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);

    final totalPhrases = phrasesRepo.phrases.length;
    final recordedPhrases = phrasesRepo.recordedCount;
    final remainingPhrases = totalPhrases - recordedPhrases;

    final totalImages = imageRepo.totalImageCount;
    final recordedImages = imageRepo.recordedCount;
    final remainingImages = totalImages - recordedImages;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 18),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recording Breakdown',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _BreakdownRow(
            label: 'Speech prompts',
            icon: Icons.mic_rounded,
            color: AppColors.primary,
            recorded: recordedPhrases,
            remaining: remainingPhrases,
            total: totalPhrases,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: 'Image descriptions',
            icon: Icons.image_rounded,
            color: AppColors.secondary,
            recorded: recordedImages,
            remaining: remainingImages,
            total: totalImages,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int recorded;
  final int remaining;
  final int total;
  final bool isDark;

  const _BreakdownRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.recorded,
    required this.remaining,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : recorded / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            Text(
              '$recorded / $total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: fraction),
          duration: const Duration(milliseconds: 1300),
          curve: Curves.easeOutCubic,
          builder: (_, val, __) => _LinearBar(
            fraction: val,
            color: color,
            trackColor:
                isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(10),
            height: 7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          remaining == 0
              ? '✓ All done!'
              : '$remaining remaining',
          style: TextStyle(
            fontSize: 11,
            color: remaining == 0 ? Colors.green.shade500 : Colors.grey.shade400,
            fontWeight:
                remaining == 0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Motivational milestone card
// ─────────────────────────────────────────────────────────────────────────────
class _MilestoneCard extends StatelessWidget {
  final double overallPct;
  final int totalRecorded;

  const _MilestoneCard({
    required this.overallPct,
    required this.totalRecorded,
  });

  @override
  Widget build(BuildContext context) {
    final milestone = _nextMilestone(overallPct, totalRecorded);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withAlpha(220),
            AppColors.secondary.withAlpha(230),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Text(
            milestone.emoji,
            style: const TextStyle(fontSize: 38),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  milestone.subtitle,
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _MilestoneInfo _nextMilestone(double pct, int recorded) {
    if (pct == 0) {
      return _MilestoneInfo(
        emoji: '🎙️',
        title: 'Ready to begin?',
        subtitle: 'Head to Speech or Image tabs and make your first recording!',
      );
    }
    if (pct < 0.25) {
      return _MilestoneInfo(
        emoji: '🚀',
        title: 'Great start!',
        subtitle:
            'You\'ve recorded $recorded so far. Reach 25% to hit your first milestone!',
      );
    }
    if (pct < 0.50) {
      return _MilestoneInfo(
        emoji: '⚡',
        title: 'On fire!',
        subtitle:
            'Past the first quarter! Keep going — every recording trains the model.',
      );
    }
    if (pct < 0.75) {
      return _MilestoneInfo(
        emoji: '🏅',
        title: 'Halfway champion!',
        subtitle: 'More than half complete. Your voice data is making an impact!',
      );
    }
    if (pct < 1.00) {
      return _MilestoneInfo(
        emoji: '🏁',
        title: 'Almost there!',
        subtitle:
            'Just a few left — finish strong to complete your full dataset!',
      );
    }
    return _MilestoneInfo(
      emoji: '🏆',
      title: 'Dataset complete!',
      subtitle:
          'You\'ve recorded all $recorded prompts. Thank you for your contribution!',
    );
  }
}

class _MilestoneInfo {
  final String emoji;
  final String title;
  final String subtitle;
  _MilestoneInfo(
      {required this.emoji, required this.title, required this.subtitle});
}

// ─────────────────────────────────────────────────────────────────────────────
// Small numeric tile used inside the upload card
// ─────────────────────────────────────────────────────────────────────────────
class _MiniStatTile extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final AnimationController animation;
  final bool isDark;

  const _MiniStatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tileBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: value.toDouble()),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => Text(
                  val.toInt().toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.1,
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable rounded linear progress bar
// ─────────────────────────────────────────────────────────────────────────────
class _LinearBar extends StatelessWidget {
  final double fraction;
  final Color color;
  final Color trackColor;
  final double height;

  const _LinearBar({
    required this.fraction,
    required this.color,
    required this.trackColor,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final filled = (w * fraction.clamp(0.0, 1.0));
        return Stack(
          children: [
            Container(
              width: w,
              height: height,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
            Container(
              width: filled.clamp(0.0, w),
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular ring painter (tracks + filled arc)
// ─────────────────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Track ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Filled arc — start at top (-π/2)
    final sweepAngle = math.pi * 2 * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.ringColor != ringColor;
}
