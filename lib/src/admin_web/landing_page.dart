import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repos/admin_auth_service.dart';
import '../repos/admin_gallery_repository.dart';
import 'dashboard_page.dart';
import 'web_components.dart';

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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 800;
    const atekerOrange = Color(0xFFD06E1A);
    const darkSlate = Color(0xFF1E293B);

    return Scaffold(
      appBar: const WebNavBar(currentRoute: '/'),
      drawer: const WebDrawer(currentRoute: '/'),
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
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 60 : 120,
                    horizontal: 24,
                  ),
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
                          _AnimatedLogo(
                            atekerOrange: atekerOrange,
                            size: isMobile ? 100 : 140,
                          ),
                          SizedBox(height: isMobile ? 24 : 40),
                          Text(
                            'Preserving Our Heritage, One Voice at a Time',
                            textAlign: TextAlign.center,
                            style: (isMobile
                                    ? theme.textTheme.headlineMedium
                                    : theme.textTheme.displayMedium)
                                ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: darkSlate,
                              letterSpacing: isMobile ? -0.5 : -1.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Building the world\'s first high-quality speech datasets for Ateker languages using advanced AI technology.',
                            textAlign: TextAlign.center,
                            style: (isMobile
                                    ? theme.textTheme.titleMedium
                                    : theme.textTheme.headlineSmall)
                                ?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: isMobile ? 36 : 56),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 24 : 32,
                                      vertical: isMobile ? 16 : 20,
                                    ),
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
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 40 : 48,
                horizontal: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: isMobile
                      ? Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children: [
                            _StatBadge(value: '500+', label: 'Recordings Collected'),
                            _StatBadge(value: '12', label: 'Active Contributors'),
                            _StatBadge(value: '3', label: 'Languages Supported'),
                            _StatBadge(value: '99%', label: 'Upload Success Rate'),
                          ],
                        )
                      : Row(
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
              isMobile: isMobile,
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
                        child: Text('Gallery images will appear here soon.', style: TextStyle(color: Colors.black)),
                      ),
                    );
                  }

                  int crossAxisCount = 3;
                  if (width <= 500) {
                    crossAxisCount = 1;
                  } else if (width <= 850) {
                    crossAxisCount = 2;
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: isMobile ? 16 : 24,
                      mainAxisSpacing: isMobile ? 16 : 24,
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
              isMobile: isMobile,
              child: _buildFeaturesList(isMobile),
            ),

            // ── How It Works ──
            Container(
              color: const Color(0xFFF8FAFC),
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 60 : 100,
                horizontal: 24,
              ),
              width: double.infinity,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Text(
                        'How It Works',
                        style: (isMobile
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.headlineMedium)
                            ?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Three simple steps to contribute your voice to the dataset.',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: isMobile ? 14 : 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 40 : 64),
                      _buildStepsList(isMobile),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ──
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList(bool isMobile) {
    final features = [
      const _FeatureCard(
        icon: Icons.language_rounded,
        title: 'Linguistic Pride',
        description: 'Ensuring that Ateker languages are represented in the digital landscape for future generations.',
      ),
      const _FeatureCard(
        icon: Icons.auto_awesome_rounded,
        title: 'AI Innovation',
        description: 'Training cutting-edge voice models that understand local accents and speech patterns perfectly.',
      ),
      const _FeatureCard(
        icon: Icons.people_alt_rounded,
        title: 'Local Impact',
        description: 'Creating tools that help people communicate, learn, and access information in their mother tongue.',
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          features[0],
          const SizedBox(height: 20),
          features[1],
          const SizedBox(height: 20),
          features[2],
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: features[0]),
          const SizedBox(width: 32),
          Expanded(child: features[1]),
          const SizedBox(width: 32),
          Expanded(child: features[2]),
        ],
      );
    }
  }

  Widget _buildStepsList(bool isMobile) {
    final steps = [
      const _StepCard(
        step: '01',
        title: 'Sign Up',
        description: 'Create your account on the Ateker Voices mobile app in under 2 minutes.',
      ),
      const _StepCard(
        step: '02',
        title: 'Record',
        description: 'Read speech prompts and describe images using your natural voice.',
      ),
      const _StepCard(
        step: '03',
        title: 'Validate',
        description: 'Help verify other contributors\' recordings to improve dataset quality.',
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          steps[0],
          const SizedBox(height: 32),
          steps[1],
          const SizedBox(height: 32),
          steps[2],
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: steps[0]),
          const SizedBox(width: 32),
          Expanded(child: steps[1]),
          const SizedBox(width: 32),
          Expanded(child: steps[2]),
        ],
      );
    }
  }
}

class _AnimatedLogo extends StatefulWidget {
  final Color atekerOrange;
  final double size;
  const _AnimatedLogo({required this.atekerOrange, required this.size});

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
          padding: EdgeInsets.all(widget.size * 0.15),
          decoration: BoxDecoration(
            color: widget.atekerOrange.withAlpha(25),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.atekerOrange.withAlpha((50 * _controller.value).toInt()),
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
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}

class _SectionWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool isMobile;

  const _SectionWrapper({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 60 : 100,
        horizontal: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            Text(
              title,
              style: (isMobile
                      ? Theme.of(context).textTheme.headlineSmall
                      : Theme.of(context).textTheme.headlineMedium)
                  ?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.black,
                fontSize: isMobile ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 40 : 64),
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

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    const atekerOrange = Color(0xFFD06E1A);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 800;

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
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
              color: atekerOrange.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: atekerOrange, size: 32),
          ),
          SizedBox(height: isMobile ? 20 : 32),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(color: Colors.black, height: 1.6),
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 800;

    return SizedBox(
      width: isMobile ? 160 : null,
      child: Column(
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
            style: const TextStyle(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 800;

    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
          style: const TextStyle(color: Colors.black, height: 1.6),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }
}
