// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repos/admin_auth_service.dart';
import 'admin_gallery_page.dart';
import 'admin_login_page.dart';
import 'admin_prompts_page.dart';
import 'dashboard_page.dart';

/// The shared dark sidebar used on all admin pages.
/// [selectedRoute] is the routeName of the current page so the correct
/// nav item appears highlighted.
class AdminSidebar extends StatelessWidget {
  final String selectedRoute;
  final VoidCallback onSignOut;

  const AdminSidebar({
    super.key,
    required this.selectedRoute,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthService>();
    return SizedBox(
      width: 220,
      child: ColoredBox(
        color: const Color(0xFF0F172A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo block
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/atekervoices-logo.png',
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ateker Voices',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Color(0xFFD06E1A),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.white12,
            ),
            const SizedBox(height: 20),
            AdminSideNavItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: selectedRoute == DashboardPage.routeName,
              onTap: () {
                if (selectedRoute != DashboardPage.routeName) {
                  Navigator.pushReplacementNamed(context, DashboardPage.routeName);
                }
              },
            ),
            AdminSideNavItem(
              icon: Icons.text_snippet_rounded,
              label: 'Prompts',
              selected: selectedRoute == AdminPromptsPage.routeName,
              onTap: () {
                if (selectedRoute != AdminPromptsPage.routeName) {
                  Navigator.pushReplacementNamed(context, AdminPromptsPage.routeName);
                }
              },
            ),
            AdminSideNavItem(
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              selected: selectedRoute == AdminGalleryPage.routeName,
              onTap: () {
                if (selectedRoute != AdminGalleryPage.routeName) {
                  Navigator.pushReplacementNamed(context, AdminGalleryPage.routeName);
                }
              },
            ),
            const Spacer(),
            AdminSideNavItem(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              selected: false,
              onTap: onSignOut,
            ),
            if (auth.user?.email != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD06E1A).withAlpha(46),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Color(0xFFD06E1A), size: 15),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        auth.user!.email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AdminSideNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AdminSideNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<AdminSideNavItem> createState() => _AdminSideNavItemState();
}

class _AdminSideNavItemState extends State<AdminSideNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.selected
                  ? const Color(0xFFD06E1A).withAlpha(38)
                  : _hovered
                      ? Colors.white.withAlpha(15)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.selected
                      ? const Color(0xFFD06E1A)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.selected
                        ? const Color(0xFFD06E1A)
                        : const Color(0xFFCBD5E1),
                    fontSize: 14,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
