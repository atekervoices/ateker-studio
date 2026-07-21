import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repos/admin_auth_service.dart';
import '../repos/admin_gallery_repository.dart';
import 'admin_login_page.dart';
import 'admin_sidebar.dart';

class AdminGalleryPage extends StatefulWidget {
  const AdminGalleryPage({super.key});

  static const routeName = '/admin/gallery';

  @override
  State<AdminGalleryPage> createState() => _AdminGalleryPageState();
}

class _AdminGalleryPageState extends State<AdminGalleryPage> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1A1C23),
              foregroundColor: Colors.white,
              title: const Text('Community Gallery', style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                selectedRoute: AdminGalleryPage.routeName,
                onSignOut: () => _confirmSignOut(context),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AdminSidebar(
              selectedRoute: AdminGalleryPage.routeName,
              onSignOut: () => _confirmSignOut(context),
            ),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  // Page header
                  Container(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Community Gallery',
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
                              'Manage images shown on the public landing page.',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 13),
                            ),
                          ],
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => _showUploadDialog(context),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add to Gallery'),
                        ),
                      ],
                    ),
                  ),
                  // Grid content
                  Expanded(
                    child: Consumer<AdminGalleryRepository>(
                      builder: (context, repo, _) {
                        if (repo.isLoading && repo.images.isEmpty) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (repo.images.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_library_outlined,
                                    size: 64,
                                    color: Colors.grey.withAlpha(80)),
                                const SizedBox(height: 16),
                                const Text('No images in the gallery yet.',
                                    style:
                                        TextStyle(color: Colors.black)),
                                const SizedBox(height: 24),
                                FilledButton(
                                  onPressed: () => _showUploadDialog(context),
                                  child: const Text('Upload First Image'),
                                ),
                              ],
                            ),
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(28),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : 1,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: repo.images.length,
                          itemBuilder: (context, index) {
                            final image = repo.images[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(image.url,
                                      fit: BoxFit.cover),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      color: Colors.black.withAlpha(160),
                                      child: Text(
                                        image.caption,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.white),
                                      style: IconButton.styleFrom(
                                          backgroundColor:
                                              Colors.red.withAlpha(200)),
                                      onPressed: () =>
                                          repo.deleteImage(image.id, image.url),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
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

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _UploadDialog(),
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

class _UploadDialog extends StatefulWidget {
  const _UploadDialog();

  @override
  State<_UploadDialog> createState() => __UploadDialogState();
}

class __UploadDialogState extends State<_UploadDialog> {
  final _captionController = TextEditingController();
  Uint8List? _selectedImageData;
  String? _selectedFileName;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
    if (result != null) {
      setState(() {
        _selectedImageData = result.files.first.bytes;
        _selectedFileName = result.files.first.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload to Gallery'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImageData != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_selectedImageData!, height: 200, fit: BoxFit.cover),
              )
            else
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withAlpha(50)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.black),
                      SizedBox(height: 8),
                      Text('Click to select image'),
                    ],
                  ),
                ),
              ),
            if (_selectedImageData != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Change Image'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: 'Caption'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: (_selectedImageData == null || _isUploading)
              ? null
              : () async {
                  setState(() => _isUploading = true);
                  try {
                    await context.read<AdminGalleryRepository>().uploadImage(
                      imageData: _selectedImageData!,
                      fileName: _selectedFileName!,
                      caption: _captionController.text,
                    );
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  } finally {
                    if (mounted) setState(() => _isUploading = false);
                  }
                },
          child: _isUploading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Upload'),
        ),
      ],
    );
  }
}
