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

import '../repos/admin_gallery_repository.dart';
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
      duration: const Duration(milliseconds: 1000),
    );

    _heroOpacity = CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
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

  // ── Scroll-triggered section animation state ──────────────────────────────
  bool _statsVisible = false;
  bool _featuresVisible = false;
  bool _stepsVisible = false;
  bool _galleryVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reveal all sections shortly after the widget is laid out
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _statsVisible = true;
        _featuresVisible = true;
        _stepsVisible = true;
        _galleryVisible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 1000;
    const darkSlate = Color(0xFF0F172A);

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
                    vertical: isMobile ? 48 : 96,
                    horizontal: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: isMobile 
                          ? Column(
                              children: [
                                _buildHeroContent(context, isMobile: true),
                                const SizedBox(height: 64),
                                const _HeroLogo(),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _buildHeroContent(context, isMobile: false),
                                ),
                                const SizedBox(width: 64),
                                const Expanded(
                                  flex: 5,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: _HeroLogo(),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Typography-First Stats ──
            AnimatedOpacity(
              opacity: _statsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: Transform.translate(
                offset: _statsVisible ? Offset.zero : const Offset(0, 20),
                child: _buildStatsSection(isMobile),
              ),
            ),

            // ── Features Section (Bento Grid) ──
            _SectionWrapper(
              title: 'Linguistic Technology Redefined',
              subtitle: 'An institutional-grade platform built to preserve native speech datasets, structure metadata, and cross-validate translations.',
              isMobile: isMobile,
              backgroundColor: const Color(0xFFF8FAFC),
              child: AnimatedOpacity(
              opacity: _featuresVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: Transform.translate(
                offset: _featuresVisible ? Offset.zero : const Offset(0, 24),
                child: _buildBentoGrid(isMobile),
              ),
            ),
            ),

            // ── How It Works Section ──
            _SectionWrapper(
              title: 'The Dataset Lifecycle',
              subtitle: 'A clean, multi-layered approach to capturing, refining, and validating voice assets.',
              isMobile: isMobile,
              child: AnimatedOpacity(
              opacity: _stepsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: Transform.translate(
                offset: _stepsVisible ? Offset.zero : const Offset(0, 24),
                child: _buildStepsSection(isMobile),
              ),
            ),
            ),

            // ── Community Gallery ──
            _SectionWrapper(
              title: 'Community & Heritage',
              subtitle: 'Archiving and documenting the languages, traditions, and native territories of Ateker peoples.',
              isMobile: isMobile,
              backgroundColor: const Color(0xFFF8FAFC),
              child: AnimatedOpacity(
                opacity: _galleryVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                child: Transform.translate(
                  offset: _galleryVisible ? Offset.zero : const Offset(0, 24),
                  child: Consumer<AdminGalleryRepository>(
                builder: (context, repo, _) {
                  if (repo.isLoading && repo.images.isEmpty) {
                    return const SizedBox(
                      height: 250,
                      child: Center(child: CircularProgressIndicator(color: darkSlate)),
                    );
                  }

                  if (repo.images.isEmpty) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'No images loaded in community archives.', 
                          style: TextStyle(color: Colors.black, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  int crossAxisCount = 4;
                  if (width <= 600) {
                    crossAxisCount = 1;
                  } else if (width <= 900) {
                    crossAxisCount = 2;
                  } else if (width <= 1200) {
                    crossAxisCount = 3;
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: repo.images.length > 8 ? 8 : repo.images.length,
                    itemBuilder: (context, index) {
                      return _GalleryCard(image: repo.images[index]);
                    },
                  );
                },
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

  Widget _buildHeroContent(BuildContext context, {required bool isMobile}) {
    final theme = Theme.of(context);
    const atekerOrange = Color(0xFFD97706);
    const darkSlate = Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Clean modern tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text(
            'BETA ACCESS OPEN',
            style: TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Headline
        RichText(
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          text: TextSpan(
            style: (isMobile
                    ? theme.textTheme.headlineMedium
                    : theme.textTheme.displayMedium)
                ?.copyWith(
              fontWeight: FontWeight.w900,
              color: darkSlate,
              letterSpacing: isMobile ? -0.8 : -1.8,
              height: 1.1,
            ),
            children: const [
              TextSpan(text: 'Preserving Our '),
              TextSpan(
                text: 'Heritage',
                style: TextStyle(color: atekerOrange),
              ),
              TextSpan(text: ',\nOne Voice at a Time.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Subtitle
        Text(
          'We gather and structure speech datasets for Ateker languages. By pairing local speaker networks with automated verification, we generate clean audio assets to bridge the digital language gap.',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: (isMobile
                  ? theme.textTheme.bodyMedium
                  : theme.textTheme.titleMedium)
              ?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 36),
        // Action Buttons
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/datasets');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: darkSlate,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Explore Open Datasets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/about');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Learn About Us', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(bool isMobile) {
    final stats = [
      {'val': '55.7 HRS', 'lbl': 'AUDIO RECORDED'},
      {'val': '175+', 'lbl': 'NATIVE SPEAKERS'},
      {'val': '3 DIALECTS', 'lbl': 'ACTIVE COVERAGE'},
      {'val': '99.2%', 'lbl': 'VERIFIED ACCURACY'},
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile
              ? Column(
                  children: stats.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: _StatWidget(value: s['val']!, label: s['lbl']!),
                  )).toList(),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: stats.map((s) => Expanded(
                    child: _StatWidget(value: s['val']!, label: s['lbl']!),
                  )).toList(),
                ),
        ),
      ),
    );
  }

  Widget _buildBentoGrid(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildLanguageBentoCard(),
          const SizedBox(height: 24),
          _buildQualityBentoCard(),
          const SizedBox(height: 24),
          _buildAccessBentoCard(),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildLanguageBentoCard()),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildQualityBentoCard()),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildAccessBentoCard()),
            const SizedBox(width: 24),
            Expanded(flex: 3, child: _buildCommunityBentoCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageBentoCard() {
    return _BentoCard(
      title: 'Multilingual Coverage',
      description: 'Supporting distinct dialects within the Ateker language family to ensure accurate vocabulary and structural representation.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          _DialectBadge(name: 'Karimojong', detail: 'Moroto & Kotido'),
          _DialectBadge(name: 'Turkana', detail: 'Lodwar Valley'),
          _DialectBadge(name: 'Iteso', detail: 'Eastern Region'),
        ],
      ),
    );
  }

  Widget _buildQualityBentoCard() {
    return _BentoCard(
      title: 'Acoustic Precision',
      description: 'Audio formats are locked at standardized recording outputs to support machine learning ingestion.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _BentoListRow(label: 'WAV Container • 16kHz Mono'),
          SizedBox(height: 8),
          _BentoListRow(label: 'Double-Verifier Cross Checks'),
          SizedBox(height: 8),
          _BentoListRow(label: 'Background Noise Thresholding'),
        ],
      ),
    );
  }

  Widget _buildAccessBentoCard() {
    return _BentoCard(
      title: 'CC-BY-SA 4.0 License',
      description: 'Our corpora are open-source and structured for public access, enabling researcher-driven model development.',
      child: Row(
        children: const [
          Icon(Icons.gavel_rounded, color: Colors.black, size: 18),
          SizedBox(width: 8),
          Text(
            'Open-Source Licensing Standard',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityBentoCard() {
    return _BentoCard(
      title: 'Speaker Network Model',
      description: 'Built by and for the speakers themselves. Native networks coordinate narratives, folklore translations, and contextual spelling alignment.',
      child: Row(
        children: const [
          Icon(Icons.forum_outlined, color: Colors.black, size: 18),
          SizedBox(width: 8),
          Text(
            'Direct Community Translation Loops',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsSection(bool isMobile) {
    final steps = [
      const _StepWidget(
        step: '01',
        title: 'Network Intake',
        description: 'Speakers connect and establish their profile, setting specific regional dialect accents.',
      ),
      const _StepWidget(
        step: '02',
        title: 'Audio Capture',
        description: 'Contributors record prompted voice samples or spontaneously describe local imagery cards.',
      ),
      const _StepWidget(
        step: '03',
        title: 'Metadata Curation',
        description: 'Peers validate transcripts, tag acoustic quality flags, and approve dataset export chunks.',
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          steps[0],
          const SizedBox(height: 40),
          steps[1],
          const SizedBox(height: 40),
          steps[2],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: steps[0]),
        const SizedBox(width: 48),
        Expanded(child: steps[1]),
        const SizedBox(width: 48),
        Expanded(child: steps[2]),
      ],
    );
  }
}

// ── Typography Stats Widget ────────────────────────────────────────────────
class _StatWidget extends StatelessWidget {
  final String value;
  final String label;

  const _StatWidget({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Bento Grid Card Widget ──────────────────────────────────────────────────
class _BentoCard extends StatefulWidget {
  final String title;
  final String description;
  final Widget child;

  const _BentoCard({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  State<_BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<_BentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.05 : 0.01),
              blurRadius: _isHovered ? 12 : 4,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _DialectBadge extends StatelessWidget {
  final String name;
  final String detail;

  const _DialectBadge({required this.name, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: const TextStyle(fontSize: 9, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _BentoListRow extends StatelessWidget {
  final String label;

  const _BentoListRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── Chronological Step Widget ───────────────────────────────────────────────
class _StepWidget extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _StepWidget({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w200,
            color: Color(0xFF94A3B8),
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Floating Logo Widget (Replaced Phone Simulator) ─────────────────────────
class _HeroLogo extends StatefulWidget {
  const _HeroLogo();

  @override
  State<_HeroLogo> createState() => _HeroLogoState();
}

class _HeroLogoState extends State<_HeroLogo> with SingleTickerProviderStateMixin {
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
    const atekerOrange = Color(0xFFD97706);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -12 * _controller.value),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: atekerOrange.withValues(alpha: 0.04 * _controller.value),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Image.asset(
        'assets/images/atekervoices-logo.png',
        width: 260,
        height: 260,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ── Community Gallery Card ──────────────────────────────────────────────────
class _GalleryCard extends StatefulWidget {
  final GalleryImage image;

  const _GalleryCard({required this.image});

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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.04 : 0.01),
              blurRadius: _isHovered ? 12 : 4,
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.image.url, 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF8FAFC),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, color: Color(0xFFCBD5E1), size: 24),
                  ),
                );
              },
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _isHovered ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                alignment: Alignment.bottomLeft,
                child: Text(
                  widget.image.caption,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Clean Section Wrapper ───────────────────────────────────────────────────
class _SectionWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool isMobile;
  final Color? backgroundColor;

  const _SectionWrapper({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isMobile,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundColor ?? Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 48 : 80,
        horizontal: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
