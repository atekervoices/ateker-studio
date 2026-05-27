import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repos/admin_auth_service.dart';
import '../repos/admin_gallery_repository.dart';
import '../repos/admin_prompts_repository.dart';
import 'admin_gallery_page.dart';
import 'admin_login_page.dart';
import 'admin_prompts_page.dart';
import 'dashboard_page.dart';
import 'landing_page.dart';

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  // AtekerVoices brand colors
  static const Color atekerOrange = Color(0xFFD06E1A);
  static const Color atekerLightBg = Colors.white;
  static const Color atekerCardBg = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthService()),
        ChangeNotifierProvider(create: (_) => AdminPromptsRepository()),
        ChangeNotifierProvider(create: (_) => AdminGalleryRepository()..loadGallery()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ateker Voices Admin',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: atekerOrange,
            brightness: Brightness.light,
            surface: atekerLightBg,
          ),
          scaffoldBackgroundColor: atekerLightBg,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E293B),
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
            titleTextStyle: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            shape: Border(
              bottom: BorderSide(color: Colors.grey.withAlpha(50), width: 1),
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withAlpha(50), width: 1),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: atekerOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: atekerOrange,
              side: const BorderSide(color: atekerOrange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: atekerOrange, width: 2),
            ),
            labelStyle: const TextStyle(color: Color(0xFF64748B)),
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor: atekerOrange,
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: atekerOrange,
            dividerColor: Colors.transparent,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: atekerOrange, width: 3),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        initialRoute: LandingPage.routeName,
        routes: {
          LandingPage.routeName: (_) => const LandingPage(),
          AdminLoginPage.routeName: (_) => const AdminLoginPage(),
          DashboardPage.routeName: (_) => const _AdminGuard(child: DashboardPage()),
          AdminPromptsPage.routeName: (_) => const _AdminGuard(child: AdminPromptsPage()),
          AdminGalleryPage.routeName: (_) => const _AdminGuard(child: AdminGalleryPage()),
        },
      ),
    );
  }
}

/// A guard that redirects to login if the user is not an authenticated admin.
class _AdminGuard extends StatelessWidget {
  final Widget child;
  const _AdminGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthService>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AdminWebApp.atekerOrange,
              ),
            ),
          );
        }

        if (!auth.isLoggedIn) {
          // Use a post-frame callback to redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AdminLoginPage.routeName);
          });
          return const Scaffold();
        }

        return child;
      },
    );
  }
}
