import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../repos/admin_auth_service.dart';
import '../ui/core/themes/colors.dart';
import 'admin_gallery_page.dart';
import 'admin_login_page.dart';
import 'admin_prompts_page.dart';
import 'admin_sidebar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  static const routeName = '/dashboard';

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ── Stats ──
  int? _usersCount;
  int? _recordingsCount;
  int? _textPromptsCount;
  int? _imagePromptsCount;
  bool _statsLoading = true;
  bool _statsError = false;

  // ── Recent Recordings ──
  List<Map<String, dynamic>> _recordings = [];
  bool _recordingsLoading = true;

  // ── Recent Users ──
  List<Map<String, dynamic>> _users = [];
  bool _usersLoading = true;

  /// Indices of recording rows that are currently fetching a download URL.
  final Set<int> _fetchingUrl = {};

  VideoPlayerController? _activePlayerController;
  int? _activePlayerIdx;
  bool _activePlayerIsPlaying = false;

  // ── Helpers ──
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formattedDate() {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '—';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // ── Data Loading ──
  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadRecordings();
    _loadUsers();
  }

  @override
  void dispose() {
    _activePlayerController?.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final db = FirebaseFirestore.instance;
      final results = await Future.wait([
        db.collection('users').count().get(),
        db.collection('recordings').count().get(),
        db.collection('admin_prompts').where('kind', isEqualTo: 'text').count().get(),
        db.collection('admin_prompts').where('kind', isEqualTo: 'image').count().get(),
      ]);
      if (!mounted) return;
      setState(() {
        _usersCount = results[0].count;
        _recordingsCount = results[1].count;
        _textPromptsCount = results[2].count;
        _imagePromptsCount = results[3].count;
        _statsLoading = false;
      });
    } catch (e) {
      developer.log('Stats load error: $e');
      if (!mounted) return;
      setState(() {
        _statsLoading = false;
        _statsError = true;
      });
    }
  }

  Future<void> _loadRecordings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recordings')
          .limit(10)
          .get();
      final docs = snapshot.docs.map((d) => d.data()).toList()
        ..sort((a, b) {
          final aT = a['uploadedAt'] as Timestamp?;
          final bT = b['uploadedAt'] as Timestamp?;
          if (aT == null && bT == null) return 0;
          if (aT == null) return 1;
          if (bT == null) return -1;
          return bT.compareTo(aT);
        });
      if (!mounted) return;
      setState(() {
        _recordings = docs;
        _recordingsLoading = false;
      });
    } catch (e) {
      developer.log('Recordings load error: $e');
      if (!mounted) return;
      setState(() => _recordingsLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(8)
          .get();
      final docs = snapshot.docs.map((d) => d.data()).toList()
        ..sort((a, b) {
          final aT = (a['lastSignInAt'] ?? a['createdAt']) as Timestamp?;
          final bT = (b['lastSignInAt'] ?? b['createdAt']) as Timestamp?;
          if (aT == null && bT == null) return 0;
          if (aT == null) return 1;
          if (bT == null) return -1;
          return bT.compareTo(aT);
        });
      if (!mounted) return;
      setState(() {
        _users = docs;
        _usersLoading = false;
      });
    } catch (e) {
      developer.log('Users load error: $e');
      if (!mounted) return;
      setState(() => _usersLoading = false);
    }
  }

  Future<void> _playRecording(int index, String path) async {
    if (_fetchingUrl.contains(index)) return;

    // Toggle play/pause if this row is already active
    if (_activePlayerIdx == index && _activePlayerController != null) {
      if (_activePlayerController!.value.isPlaying) {
        await _activePlayerController!.pause();
      } else {
        await _activePlayerController!.play();
      }
      return;
    }

    // Stop and dispose any previous player
    await _activePlayerController?.pause();
    await _activePlayerController?.dispose();
    if (mounted) {
      setState(() {
        _activePlayerController = null;
        _activePlayerIdx = null;
        _activePlayerIsPlaying = false;
        _fetchingUrl.add(index);
      });
    }

    try {
      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      if (!mounted) return;

      final controller =
          VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      controller.addListener(() {
        if (!mounted) return;
        final playing = controller.value.isPlaying;
        if (_activePlayerIsPlaying != playing) {
          setState(() => _activePlayerIsPlaying = playing);
        }
      });

      await controller.play();
      if (mounted) {
        setState(() {
          _activePlayerController = controller;
          _activePlayerIdx = index;
          _activePlayerIsPlaying = true;
        });
      }
    } catch (e) {
      developer.log('Play error for "$path": $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play recording: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingUrl.remove(index));
    }
  }

  Future<void> _stopPlayer() async {
    await _activePlayerController?.pause();
    await _activePlayerController?.dispose();
    if (mounted) {
      setState(() {
        _activePlayerController = null;
        _activePlayerIdx = null;
        _activePlayerIsPlaying = false;
      });
    }
  }

  Future<void> _confirmSignOut(BuildContext ctx, AdminAuthService auth) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out of the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD06E1A)),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      await auth.signOut();
      if (ctx.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          ctx,
          AdminLoginPage.routeName,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AdminAuthService>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                selectedRoute: DashboardPage.routeName,
                onSignOut: () => _confirmSignOut(context, auth),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AdminSidebar(
              selectedRoute: DashboardPage.routeName,
              onSignOut: () => _confirmSignOut(context, auth),
            ),
          Expanded(child: _buildMainContent(context, isDesktop)),
        ],
      ),
    );
  }

  // ── Main Content ──
  Widget _buildMainContent(BuildContext context, bool isDesktop) {
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildStatsRow(context, isDesktop)),
          SliverToBoxAdapter(child: _buildRecordingsCard(context, isDesktop)),
          SliverToBoxAdapter(child: _buildUsersCard(context, isDesktop)),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_greeting()}, Admin 👋',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _formattedDate(),
            style: const TextStyle(color: Colors.black, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──
  Widget _buildStatsRow(BuildContext context, bool isDesktop) {
    String _val(int? v) =>
        _statsLoading ? '' : (_statsError || v == null) ? '—' : '$v';

    final statCards = [
      _StatCard(
        label: 'Total Users',
        value: _val(_usersCount),
        loading: _statsLoading,
        icon: Icons.people_rounded,
        color: const Color(0xFF6366F1),
      ),
      _StatCard(
        label: 'Total Recordings',
        value: _val(_recordingsCount),
        loading: _statsLoading,
        icon: Icons.mic_rounded,
        color: AppColors.primary,
      ),
      _StatCard(
        label: 'Text Prompts',
        value: _val(_textPromptsCount),
        loading: _statsLoading,
        icon: Icons.text_snippet_rounded,
        color: const Color(0xFF10B981),
      ),
      _StatCard(
        label: 'Image Prompts',
        value: _val(_imagePromptsCount),
        loading: _statsLoading,
        icon: Icons.image_rounded,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: statCards[0]),
                const SizedBox(width: 16),
                Expanded(child: statCards[1]),
                const SizedBox(width: 16),
                Expanded(child: statCards[2]),
                const SizedBox(width: 16),
                Expanded(child: statCards[3]),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: statCards[0]),
                    const SizedBox(width: 16),
                    Expanded(child: statCards[1]),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: statCards[2]),
                    const SizedBox(width: 16),
                    Expanded(child: statCards[3]),
                  ],
                ),
              ],
            ),
    );
  }

  // ── Recent Recordings Card ──
  Widget _buildRecordingsCard(BuildContext context, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 16, 0, isDesktop ? 32 : 16, 24),
      child: _ContentCard(
        header: Row(
          children: [
            Text(
              'Recent Recordings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFD06E1A)),
              child: const Text('View All'),
            ),
          ],
        ),
        body: _recordingsLoading
            ? const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            : _recordings.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Text(
                        'No recordings found.',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(
                      _recordings.length,
                      (i) => _buildRecordingRow(i, _recordings[i], isDesktop),
                    ),
                  ),
      ),
    );
  }

  Widget _buildRecordingRow(int idx, Map<String, dynamic> rec, bool isDesktop) {
    final promptType = (rec['promptType'] as String? ?? 'speech').toLowerCase();
    final rawText = rec['promptText'] as String? ?? rec['prompt'] as String? ?? '—';
    final displayText = rawText.length > 60 ? '${rawText.substring(0, 60)}…' : rawText;
    final uid = rec['ownerUid'] as String? ?? rec['userId'] as String? ?? '????';
    final userLabel =
        'User #${uid.length >= 4 ? uid.substring(uid.length - 4) : uid}';
    final uploadedAt = rec['uploadedAt'] as Timestamp?;
    final path = rec['recordingPath'] as String? ?? rec['path'] as String? ?? '';
    final isSpeech = promptType == 'speech' || promptType == 'text';

    final isLast = idx == _recordings.length - 1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
      ),
      child: Row(
        children: [
          // Type chip
          _TypeChip(label: isSpeech ? 'Speech' : 'Image', isSpeech: isSpeech),
          const SizedBox(width: 16),
          // Prompt text and potentially user/time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayText,
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                ),
                if (!isDesktop) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$userLabel • ${_timeAgo(uploadedAt)}',
                    style: const TextStyle(color: Colors.black, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // User
          if (isDesktop) ...[
            Text(
              userLabel,
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
            const SizedBox(width: 16),
            // Time ago
            SizedBox(
              width: 64,
              child: Text(
                _timeAgo(uploadedAt),
                textAlign: TextAlign.end,
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Inline player controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_fetchingUrl.contains(idx))
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: Icon(
                    (_activePlayerIdx == idx && _activePlayerIsPlaying)
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 22,
                  ),
                  color: const Color(0xFF6366F1),
                  tooltip: (_activePlayerIdx == idx && _activePlayerIsPlaying)
                      ? 'Pause'
                      : 'Play',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed:
                      path.isEmpty ? null : () => _playRecording(idx, path),
                ),
              if (_activePlayerIdx == idx) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, size: 22),
                  color: Colors.redAccent,
                  tooltip: 'Stop',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _stopPlayer,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Recent Users Card ──
  Widget _buildUsersCard(BuildContext context, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 16, 0, isDesktop ? 32 : 16, 24),
      child: _ContentCard(
        header: Text(
          'Recent Users',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
        ),
        body: _usersLoading
            ? const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            : _users.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Text(
                        'No users found.',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(
                      _users.length,
                      (i) => _buildUserRow(i, _users[i], isDesktop),
                    ),
                  ),
      ),
    );
  }

  Widget _buildUserRow(int idx, Map<String, dynamic> user, bool isDesktop) {
    final displayName = user['displayName'] as String? ?? 'Anonymous';
    final email = user['email'] as String? ?? '—';
    final lastSeen =
        (user['lastSignInAt'] ?? user['createdAt']) as Timestamp?;
    final isActive = lastSeen != null &&
        DateTime.now().difference(lastSeen.toDate()).inDays < 30;

    final parts = displayName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : '?';

    final isLast = idx == _users.length - 1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                const Color(0xFF6366F1).withValues(alpha: 0.15),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
                if (!isDesktop && lastSeen != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last seen ${_timeAgo(lastSeen)}',
                    style: const TextStyle(color: Colors.black, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (isDesktop) ...[
            Text(
              lastSeen != null ? 'Last seen ${_timeAgo(lastSeen)}' : '—',
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
            const SizedBox(width: 16),
          ],
          _BadgeChip(
            label: isActive ? 'Active' : '—',
            color: isActive ? const Color(0xFF10B981) : Colors.black,
          ),
        ],
      ),
    );
  }
}



// ══════════════════════════════════════════════════════════════
// Stat Card
// ══════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool loading;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.loading,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                loading
                    ? const SizedBox(
                        width: 48,
                        child: LinearProgressIndicator(minHeight: 3),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Content Card (white rounded card with header + body)
// ══════════════════════════════════════════════════════════════

class _ContentCard extends StatelessWidget {
  final Widget header;
  final Widget body;

  const _ContentCard({required this.header, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
            child: header,
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          body,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Small reusable chips
// ══════════════════════════════════════════════════════════════

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSpeech;
  const _TypeChip({required this.label, required this.isSpeech});

  @override
  Widget build(BuildContext context) {
    final fg =
        isSpeech ? const Color(0xFFD06E1A) : const Color(0xFF0891B2);
    final bg = fg.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _BadgeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
