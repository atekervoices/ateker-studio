import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repos/admin_auth_service.dart';
import '../repos/admin_gallery_repository.dart';
import 'admin_login_page.dart';
import 'dashboard_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  static const routeName = '/';

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _heroController;
  late Animation<double> _heroOpacity;
  late Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _heroOpacity = CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const atekerOrange = Color(0xFFD06E1A);
    const darkSlate = Color(0xFF1E293B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ateker Voices'),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: false,
        actions: [
          Consumer<AdminAuthService>(
            builder: (context, auth, _) {
              if (auth.isLoggedIn) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      auth.user?.email ?? '',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        await auth.signOut();
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      tooltip: 'Sign Out',
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AdminLoginPage.routeName);
                    },
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text('Admin Login'),
                    style: TextButton.styleFrom(
                      foregroundColor: atekerOrange,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Section ──
            FadeTransition(
              opacity: _heroOpacity,
              child: SlideTransition(
                position: _heroSlide,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF8FAFC), Colors.white],
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        children: [
                          _AnimatedLogo(atekerOrange: atekerOrange),
                          const SizedBox(height: 40),
                          Text(
                            'Preserving Our Heritage,\nOne Voice at a Time',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: darkSlate,
                              letterSpacing: -1.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Building the world\'s first high-quality speech datasets\nfor Ateker languages using advanced AI technology.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 56),
                          Consumer<AdminAuthService>(
                            builder: (context, auth, _) {
                              if (auth.isLoggedIn) {
                                return FilledButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, DashboardPage.routeName);
                                  },
                                  icon: const Icon(Icons.dashboard_rounded),
                                  label: const Text('Access Admin Dashboard'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Stats Strip ──
            Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatBadge(value: '500+', label: 'Recordings Collected'),
                      _StatDivider(),
                      _StatBadge(value: '12', label: 'Active Contributors'),
                      _StatDivider(),
                      _StatBadge(value: '3', label: 'Languages Supported'),
                      _StatDivider(),
                      _StatBadge(value: '99%', label: 'Upload Success Rate'),
                    ],
                  ),
                ),
              ),
            ),

            // ── Community Gallery ──
            _SectionWrapper(
              title: 'Community & Culture',
              subtitle: 'The faces and traditions that drive the Ateker Voices initiative.',
              child: Consumer<AdminGalleryRepository>(
                builder: (context, repo, _) {
                  if (repo.isLoading && repo.images.isEmpty) {
                    return const SizedBox(
                      height: 400,
                      child: Center(child: CircularProgressIndicator(color: atekerOrange)),
                    );
                  }

                  if (repo.images.isEmpty) {
                    return Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text('Gallery images will appear here soon.', style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: repo.images.length > 8 ? 8 : repo.images.length,
                    itemBuilder: (context, index) {
                      return _GalleryCard(image: repo.images[index], index: index);
                    },
                  );
                },
              ),
            ),

            // ── Features Section ──
            _SectionWrapper(
              title: 'Why It Matters',
              subtitle: 'Leveraging technology to protect linguistic diversity.',
              child: Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.language_rounded,
                      title: 'Linguistic Pride',
                      description: 'Ensuring that Ateker languages are represented in the digital landscape for future generations.',
                      delay: 0,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Innovation',
                      description: 'Training cutting-edge voice models that understand local accents and speech patterns perfectly.',
                      delay: 200,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.people_alt_rounded,
                      title: 'Local Impact',
                      description: 'Creating tools that help people communicate, learn, and access information in their mother tongue.',
                      delay: 400,
                    ),
                  ),
                ],
              ),
            ),

            // ── How It Works ──
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
              width: double.infinity,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Text(
                        'How It Works',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Three simple steps to contribute your voice to the dataset.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                      ),
                      const SizedBox(height: 64),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _StepCard(step: '01', title: 'Sign Up', description: 'Create your account on the Ateker Voices mobile app in under 2 minutes.')),
                          const SizedBox(width: 32),
                          Expanded(child: _StepCard(step: '02', title: 'Record', description: 'Read speech prompts and describe images using your natural voice.')),
                          const SizedBox(width: 32),
                          Expanded(child: _StepCard(step: '03', title: 'Validate', description: 'Help verify other contributors\' recordings to improve dataset quality.')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80),
              color: const Color(0xFF0F172A),
              width: double.infinity,
              child: Column(
                children: [
                  Image.asset('assets/images/atekervoices-logo.png', width: 60, height: 60),
                  const SizedBox(height: 24),
                  const Text(
                    'Ateker Voices Initiative',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Empowering languages through technology.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 48),
                  const Divider(color: Colors.white10, indent: 100, endIndent: 100),
                  const SizedBox(height: 32),
                  Text(
                    '© ${DateTime.now().year} Ateker Voices Initiative. Part of Project Euphonia.',
                    style: const TextStyle(color: Colors.white24, fontSize: 12),
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

class _AnimatedLogo extends StatefulWidget {
  final Color atekerOrange;
  const _AnimatedLogo({required this.atekerOrange});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.atekerOrange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.atekerOrange.withValues(alpha: 0.2 * _controller.value),
                blurRadius: 40 * _controller.value,
                spreadRadius: 10 * _controller.value,
              )
            ],
          ),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/atekervoices-logo.png',
        width: 140,
        height: 140,
      ),
    );
  }
}

class _SectionWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionWrapper({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
            const SizedBox(height: 64),
            child,
          ],
        ),
      ),
    );
  }
}

class _GalleryCard extends StatefulWidget {
  final GalleryImage image;
  final int index;
  const _GalleryCard({required this.image, required this.index});

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -12.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(_isHovered ? 20 : 5),
              blurRadius: _isHovered ? 30 : 10,
              offset: Offset(0, _isHovered ? 15 : 5),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(widget.image.url, fit: BoxFit.cover),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isHovered ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(200)],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomLeft,
                child: Text(
                  widget.image.caption,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    const atekerOrange = Color(0xFFD06E1A);

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: atekerOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: atekerOrange, size: 32),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(color: Color(0xFF64748B), height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  const _StatBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFD06E1A),
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 50, width: 1, color: Colors.white12);
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  const _StepCard({required this.step, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step,
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: Color(0xFFD06E1A),
            height: 1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(color: Color(0xFF64748B), height: 1.6),
        ),
      ],
    );
  }
}
