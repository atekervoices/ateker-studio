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
import '../repos/admin_auth_service.dart';
import '../repos/admin_prompts_repository.dart';
import 'add_prompt_dialog.dart';
import 'admin_login_page.dart';
import 'admin_sidebar.dart';
import 'csv_bulk_upload_dialog.dart';

class AdminPromptsPage extends StatefulWidget {
  const AdminPromptsPage({super.key});

  static const routeName = '/admin/prompts';

  @override
  State<AdminPromptsPage> createState() => _AdminPromptsPageState();
}

class _AdminPromptsPageState extends State<AdminPromptsPage>
    with SingleTickerProviderStateMixin {
  late AdminPromptsRepository _repository;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminPromptsRepository>();
    _repository.loadPrompts();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const atekerOrange = Color(0xFFD06E1A);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1A1C23),
              foregroundColor: Colors.white,
              title: const Text('Prompts', style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                selectedRoute: AdminPromptsPage.routeName,
                onSignOut: () => _confirmSignOut(context),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AdminSidebar(
              selectedRoute: AdminPromptsPage.routeName,
              onSignOut: () => _confirmSignOut(context),
            ),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  // Page header
                  Container(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recording Prompts',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E293B),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Manage the prompts shown to contributors in the mobile app.',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 13),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showBulkUploadDialog(context),
                                  icon: const Icon(Icons.upload_file_rounded),
                                  label: const Text('Bulk Upload (CSV)'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: atekerOrange,
                                    side: const BorderSide(color: atekerOrange),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: () => _showAddPromptDialog(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Prompt'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(icon: Icon(Icons.text_snippet_outlined), text: 'Read Speech'),
                            Tab(icon: Icon(Icons.image_outlined), text: 'Spontaneous Speech'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tab content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Consumer<AdminPromptsRepository>(
                        builder: (context, repository, _) {
                          if (repository.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(color: atekerOrange),
                            );
                          }
                          if (repository.error != null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                                  const SizedBox(height: 16),
                                  Text(repository.error ?? 'Unknown error',
                                      style: const TextStyle(color: Colors.black)),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: () => repository.loadPrompts(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }
                          final textPrompts = repository.prompts.where((p) => p.kind == 'text').toList();
                          final imagePrompts = repository.prompts.where((p) => p.kind == 'image').toList();
                          return TabBarView(
                            controller: _tabController,
                            children: [
                              _buildTextPromptsTab(context, textPrompts),
                              _buildImagePromptsTab(context, imagePrompts, isDesktop),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPromptsTab(
      BuildContext context, List<AdminPromptItem> prompts) {
    if (prompts.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.text_snippet_outlined,
        label: 'No text prompts yet',
        description:
            'Text prompts are shown to contributors to read aloud for recording.',
        buttonLabel: 'Add Text Prompt',
        kind: 'text',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Read Speech Prompts',
          count: prompts.length,
          description:
              'Contributors read these text prompts aloud for speech recording.',
          icon: Icons.record_voice_over_outlined,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: prompts.length,
            itemBuilder: (context, index) {
              final prompt = prompts[index];
              return _TextPromptCard(
                prompt: prompt,
                onEdit: () => _showEditPromptDialog(context, prompt),
                onDelete: () => _showDeleteDialog(context, prompt),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImagePromptsTab(
      BuildContext context, List<AdminPromptItem> prompts, bool isDesktop) {
    if (prompts.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.image_outlined,
        label: 'No image prompts yet',
        description:
            'Image prompts trigger spontaneous/unscripted speech from contributors.',
        buttonLabel: 'Add Image Prompt',
        kind: 'image',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Spontaneous Speech Prompts',
          count: prompts.length,
          description:
              'Contributors describe these images freely, producing spontaneous speech.',
          icon: Icons.mic_external_on_outlined,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemCount: prompts.length,
            itemBuilder: (context, index) {
              final prompt = prompts[index];
              return _ImagePromptCard(
                prompt: prompt,
                onEdit: () => _showEditPromptDialog(context, prompt),
                onDelete: () => _showDeleteDialog(context, prompt),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required String description,
    required IconData icon,
  }) {
    const atekerOrange = Color(0xFFD0630E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: atekerOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: atekerOrange, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: atekerOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count prompts',
              style: const TextStyle(
                color: atekerOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required String buttonLabel,
    required String kind,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.black.withAlpha(50)),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddPromptDialog(context, initialKind: kind),
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  void _showAddPromptDialog(BuildContext context, {String? initialKind}) {
    showDialog(
      context: context,
      builder: (context) => AddPromptDialog(initialKind: initialKind),
    );
  }

  void _showBulkUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CsvBulkUploadDialog(),
    );
  }

  void _showEditPromptDialog(BuildContext context, AdminPromptItem prompt) {
    showDialog(
      context: context,
      builder: (context) => AddPromptDialog(promptToEdit: prompt),
    );
  }

  void _showDeleteDialog(BuildContext context, AdminPromptItem prompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prompt',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this prompt?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              context.read<AdminPromptsRepository>().deletePrompt(prompt.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext ctx) async {
    final auth = ctx.read<AdminAuthService>();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD06E1A)),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      await auth.signOut();
      if (ctx.mounted) {
        Navigator.pushNamedAndRemoveUntil(ctx, AdminLoginPage.routeName, (r) => false);
      }
    }
  }
}

// ── Text Prompt Card (for Read Speech) ──────────────────────────────────────

class _TextPromptCard extends StatelessWidget {
  final AdminPromptItem prompt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TextPromptCard({
    required this.prompt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const atekerOrange = Color(0xFFD0630E);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Quote icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: atekerOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.format_quote,
                  color: atekerOrange, size: 24),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _topicColor(prompt.topic).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      prompt.topic.displayName,
                      style: TextStyle(
                        color: _topicColor(prompt.topic),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prompt.text,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 15,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit',
                  color: atekerOrange,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Delete',
                  color: Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _topicColor(ImagePromptTopic topic) {
    switch (topic) {
      case ImagePromptTopic.animals:
        return const Color(0xFF8B5E3C);
      case ImagePromptTopic.food:
        return const Color(0xFFD0630E);
      case ImagePromptTopic.nature:
        return const Color(0xFF4CAF50);
      case ImagePromptTopic.objects:
        return const Color(0xFF42A5F5);
      case ImagePromptTopic.people:
        return const Color(0xFFAB47BC);
    }
  }
}

// ── Image Prompt Card (for Spontaneous Speech) ──────────────────────────────

class _ImagePromptCard extends StatelessWidget {
  final AdminPromptItem prompt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ImagePromptCard({
    required this.prompt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
              ),
              child: prompt.imageUrl != null
                  ? Image.network(
                      prompt.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.white24, size: 40),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.white24, size: 40),
                    ),
            ),
          ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _topicColor(prompt.topic).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    prompt.topic.displayName,
                    style: TextStyle(
                      color: _topicColor(prompt.topic),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  prompt.text,
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _topicColor(ImagePromptTopic topic) {
    switch (topic) {
      case ImagePromptTopic.animals:
        return const Color(0xFF8B5E3C);
      case ImagePromptTopic.food:
        return const Color(0xFFD0630E);
      case ImagePromptTopic.nature:
        return const Color(0xFF4CAF50);
      case ImagePromptTopic.objects:
        return const Color(0xFF42A5F5);
      case ImagePromptTopic.people:
        return const Color(0xFFAB47BC);
    }
  }
}
