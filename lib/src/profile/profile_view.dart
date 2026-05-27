import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repos/auth_repository.dart';
import '../settings/settings_controller.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Consumer<AuthRepository>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          if (user == null) {
            return const Center(child: Text('No user logged in'));
          }

          final children = [
            const SizedBox(height: 24),

            // Account section header
            ListTile(
              title: Text(
                'Account',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            // User info
            ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary,
                child: user.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          user.photoURL!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 24),
                        ),
                      )
                    : const Icon(Icons.person, size: 24, color: Colors.white),
              ),
              title: Text(
                user.displayName ?? 'User',
                style: theme.textTheme.headlineSmall,
              ),
              subtitle: Text(user.email ?? ''),
            ),

            const SizedBox(height: 24),

            // Preferences section header
            ListTile(
              title: Text(
                'Preferences',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Implement edit profile
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsController(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Danger zone section header
            ListTile(
              title: Text(
                'Danger Zone',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showSignOutDialog(context, auth, theme);
              },
            ),

            const SizedBox(height: 64),
          ];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                flexibleSpace: AppBar(
                  centerTitle: false,
                  title: const Text('Profile'),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => children[index],
                  childCount: children.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthRepository auth, ThemeData theme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                auth.signOut();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
