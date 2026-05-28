import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repos/admin_auth_service.dart';
import 'admin_login_page.dart';

class WebNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;
  const WebNavBar({super.key, required this.currentRoute});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 800;
    const atekerOrange = Color(0xFFD06E1A);
    const darkSlate = Color(0xFF1E293B);

    Widget navLink(String label, String route) {
      final isSelected = currentRoute == route;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (currentRoute != route) {
                Navigator.pushNamed(context, route);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? atekerOrange : darkSlate,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: isSelected ? 24 : 0,
                  color: atekerOrange,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppBar(
      toolbarHeight: 70,
      backgroundColor: Colors.white.withAlpha(240),
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      centerTitle: false,
      leadingWidth: isMobile ? 56 : 0,
      leading: isMobile
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: darkSlate),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Open menu',
              ),
            )
          : const SizedBox.shrink(),
      title: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            if (currentRoute != '/') {
              Navigator.pushNamed(context, '/');
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/atekervoices-logo.png',
                height: 36,
                width: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Text(
                'Ateker Voices',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: darkSlate,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (!isMobile) ...[
          navLink('Home', '/'),
          navLink('Datasets', '/datasets'),
          navLink('About', '/about'),
          const SizedBox(width: 24),
        ],
        Consumer<AdminAuthService>(
          builder: (context, auth, _) {
            if (auth.isLoggedIn) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMobile)
                    Text(
                      auth.user?.email ?? '',
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout, size: 20, color: Colors.redAccent),
                    tooltip: 'Sign Out',
                  ),
                  const SizedBox(width: 16),
                ],
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AdminLoginPage.routeName);
                  },
                  icon: const Icon(Icons.login, size: 16),
                  label: Text(isMobile ? 'Login' : 'Admin Login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: atekerOrange,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Colors.grey.withAlpha(30),
          height: 1,
        ),
      ),
    );
  }
}

class WebDrawer extends StatelessWidget {
  final String currentRoute;
  const WebDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    const atekerOrange = Color(0xFFD06E1A);
    const darkSlate = Color(0xFF0F172A);

    Widget drawerItem(String label, IconData icon, String route) {
      final isSelected = currentRoute == route;
      return ListTile(
        leading: Icon(icon, color: isSelected ? atekerOrange : Colors.black),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? atekerOrange : darkSlate,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedTileColor: atekerOrange.withAlpha(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.pop(context); // Close drawer first
          if (currentRoute != route) {
            Navigator.pushNamed(context, route);
          }
        },
      );
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/atekervoices-logo.png',
                    height: 48,
                    width: 48,
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ateker Voices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkSlate,
                        ),
                      ),
                      Text(
                        'Linguistic Preservation',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              drawerItem('Home', Icons.home_rounded, '/'),
              drawerItem('Datasets', Icons.folder_open_rounded, '/datasets'),
              drawerItem('About Us', Icons.info_outline_rounded, '/about'),
              const Spacer(),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),
              Consumer<AdminAuthService>(
                builder: (context, auth, _) {
                  if (auth.isLoggedIn) {
                    return Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            radius: 16,
                            backgroundColor: atekerOrange,
                            child: Icon(Icons.person_rounded, size: 16, color: Colors.white),
                          ),
                          title: Text(
                            auth.user?.email ?? '',
                            style: const TextStyle(fontSize: 13, color: darkSlate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await auth.signOut();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                              }
                            },
                            icon: const Icon(Icons.logout, size: 16),
                            label: const Text('Sign Out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 800;
    const atekerOrange = Color(0xFFD06E1A);

    Widget footerLink(String label, String route) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, route);
            },
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: const Color(0xFF0F172A),
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              if (isMobile)
                Column(
                  children: [
                    Image.asset('assets/images/atekervoices-logo.png', width: 64, height: 64),
                    const SizedBox(height: 20),
                    const Text(
                      'Ateker Voices Initiative',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Empowering languages through technology.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email_outlined, color: atekerOrange, size: 16),
                        const SizedBox(width: 8),
                        const SelectableText(
                          'atekervoices@gmail.com',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset('assets/images/atekervoices-logo.png', width: 48, height: 48),
                              const SizedBox(width: 12),
                              const Text(
                                'Ateker Voices',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Building high-quality speech datasets for Ateker languages to support digital representation and cultural preservation.',
                            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, color: atekerOrange, size: 18),
                              const SizedBox(width: 8),
                              const SelectableText(
                                'atekervoices@gmail.com',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 64),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Links',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          footerLink('Home', '/'),
                          footerLink('Datasets', '/datasets'),
                          footerLink('About Us', '/about'),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 56),
              const Divider(color: Colors.white10),
              const SizedBox(height: 32),
              if (isMobile)
                Column(
                  children: [
                    footerLink('Home', '/'),
                    footerLink('Datasets', '/datasets'),
                    footerLink('About Us', '/about'),
                    const SizedBox(height: 24),
                    Text(
                      '© ${DateTime.now().year} Ateker Voices Initiative. All rights reserved.',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '© ${DateTime.now().year} Ateker Voices Initiative. All rights reserved.',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Text(
                      'Preserving Heritage • Empowering Communities',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
