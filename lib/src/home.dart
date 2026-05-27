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

import 'auth/auth_view.dart';
import 'generated/l10n/app_localizations.dart';
import 'modes/image_prompt_controller.dart';
import 'modes/progress_view.dart';
import 'modes/train_mode_controller.dart';
import 'modes/validate_mode_controller.dart';
import 'onboarding/onboarding_view.dart';
import 'profile/profile_view.dart';
import 'repos/auth_repository.dart';
import 'repos/image_prompts_repository.dart';
import 'repos/onboarding_repository.dart';
import 'repos/phrases_repository.dart';
import 'repos/settings_repository.dart';
import 'repos/uploader.dart';
import 'settings/settings_controller.dart';
import 'ui/core/themes/colors.dart';

class HomeController extends StatefulWidget {
  const HomeController({super.key});

  @override
  State<HomeController> createState() => _HomeControllerState();
}

class _HomeControllerState extends State<HomeController> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const TrainModeController(),
    const ImagePromptController(),
    const ValidateModeController(),
    const ProgressView(),
  ];

  @override
  void initState() {
    super.initState();
    // Repos are already initialised by SplashScreen before navigation here.
    // The _loadingFuture guard in each repo ensures calling init again is a no-op.
    Provider.of<PhrasesRepository>(context, listen: false).initFromAssetFile();
    Provider.of<ImagePromptsRepository>(context, listen: false)
        .initFromAssetFile();
    Provider.of<SettingsRepository>(context, listen: false)
        .initFromPreferences();
    Provider.of<OnboardingRepository>(context, listen: false)
        .initFromPreferences();
    Provider.of<Uploader>(context, listen: false).attachPhrasesRepository(
        Provider.of<PhrasesRepository>(context, listen: false));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Consumer<AuthRepository>(
        builder: (context, auth, _) {
          if (auth.currentUser == null) {
            return const AuthView();
          }
          return Consumer<OnboardingRepository>(
            builder: (context, onboarding, _) {
              if (!onboarding.isComplete) {
                return const OnboardingView();
              }
              return _widgetOptions[_selectedIndex];
            },
          );
        },
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.secondary],
                ),
              ),
              child: Consumer<AuthRepository>(
                builder: (context, auth, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white.withAlpha(40),
                      child: Text(
                        auth.currentUser?.displayName?.isNotEmpty == true
                            ? auth.currentUser!.displayName![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      auth.currentUser?.displayName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      auth.currentUser?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_sharp),
              title: Text(
                  AppLocalizations.of(context)!.settingsMenuDrawerTitle),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsController(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileView(),
                  ),
                );
              },
            ),
            const Divider(),
            Consumer<AuthRepository>(
              builder: (context, auth, _) => ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context); // close drawer
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    context.read<AuthRepository>().signOut();
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<AuthRepository>(
        builder: (context, auth, _) {
          if (auth.currentUser == null) return const SizedBox.shrink();
          return Consumer<OnboardingRepository>(
            builder: (context, onboarding, _) {
              if (!onboarding.isComplete) return const SizedBox.shrink();
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  backgroundColor: theme.colorScheme.surface,
                  indicatorColor: AppColors.primary.withAlpha(30),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.mic_none_rounded),
                      selectedIcon: Icon(Icons.mic_rounded,
                          color: AppColors.primary),
                      label: 'Speech',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.image_outlined),
                      selectedIcon: Icon(Icons.image_rounded,
                          color: AppColors.primary),
                      label: 'Images',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.fact_check_outlined),
                      selectedIcon: Icon(Icons.fact_check_rounded,
                          color: AppColors.primary),
                      label: 'Validate',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights_rounded,
                          color: AppColors.primary),
                      label: 'Progress',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
