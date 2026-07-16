import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../repos/admin_auth_service.dart';
import '../repos/admin_gallery_repository.dart';
import '../repos/admin_prompts_repository.dart';
import 'admin_gallery_page.dart';
import 'admin_login_page.dart';
import 'admin_prompts_page.dart';
import 'dashboard_page.dart';
import 'landing_page.dart';
import 'datasets_page.dart';
import 'about_page.dart';

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
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
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
              textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(80, 40),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: atekerOrange,
              side: const BorderSide(color: atekerOrange, width: 1.5),
              textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(80, 40),
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
            labelStyle: const TextStyle(color: Colors.black),
            hintStyle: const TextStyle(color: Colors.black),
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor: atekerOrange,
            unselectedLabelColor: Colors.black,
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
        onGenerateRoute: (settings) {
          Widget buildWidget(BuildContext context) {
            switch (settings.name) {
              case LandingPage.routeName:
                return const LandingPage();
              case DatasetsPage.routeName:
                return const DatasetsPage();
              case AboutPage.routeName:
                return const AboutPage();
              case AdminLoginPage.routeName:
                return const AdminLoginPage();
              case DashboardPage.routeName:
                return const _AdminGuard(child: DashboardPage());
              case AdminPromptsPage.routeName:
                return const _AdminGuard(child: AdminPromptsPage());
              case AdminGalleryPage.routeName:
                return const _AdminGuard(child: AdminGalleryPage());
              default:
                return const LandingPage();
            }
          }
          return _AnimatedRoute(
            child: Builder(builder: buildWidget),
            settings: settings,
          );
        },
      ),
    );
  }
}



/// Smooth animated route that fades and slightly slides the new page in.
class _AnimatedRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  _AnimatedRoute({required this.child, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}/// A guard that redirects to login if the user is not an authenticated admin.
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
