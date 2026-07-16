import 'package:flutter/material.dart';
import 'web_components.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const routeName = '/about';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 800;
    const atekerOrange = Color(0xFFD06E1A);
    const darkSlate = Color(0xFF1E293B);

    return Scaffold(
      appBar: const WebNavBar(currentRoute: '/about'),
      drawer: const WebDrawer(currentRoute: '/about'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Section ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 80, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: atekerOrange.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'OUR MISSION',
                          style: TextStyle(
                            color: atekerOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'About Ateker Voices',
                        style: TextStyle(
                          fontSize: isMobile ? 32 : 48,
                          fontWeight: FontWeight.w900,
                          color: darkSlate,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bridging the digital divide by building speech technology for underserved languages.',
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 18,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content Sections ──
            Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      // Section 1: The Core Mission
                      _buildTwoColumnRow(
                        isMobile: isMobile,
                        title: 'Why Ateker Voices?',
                        content: 'Ateker languages (such as Karimojong, Turkana, and Iteso) are spoken by millions of people across East Africa. Yet, these languages are virtually non-existent in modern digital technology. We believe that voice assistants, automated translations, and speech-to-text systems must serve all communities. Ateker Voices was started to gather the necessary data so that future AI applications can speak and understand Ateker languages fluently.',
                        imageWidget: Container(
                          height: 240,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD06E1A),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: Icon(Icons.record_voice_over_rounded, size: 80, color: Colors.white),
                          ),
                        ),
                        imageFirst: false,
                      ),
                      SizedBox(height: isMobile ? 60 : 100),

                      // Section 2: Technical Approach
                      _buildTwoColumnRow(
                        isMobile: isMobile,
                        title: 'Acoustic Quality & Accuracy',
                        content: 'Ateker Voices leverages advanced machine learning frameworks and recording pipelines to ensure dataset quality and acoustic accuracy. By employing speech recognition methodologies tailored to understand accent variants, regional dialects, and distinct speech styles, we build high-performing datasets that make voice technology inclusive and accessible to everyone.',
                        imageWidget: Container(
                          height: 240,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B2A05),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: Icon(Icons.language_rounded, size: 80, color: Colors.white),
                          ),
                        ),
                        imageFirst: true,
                      ),
                      SizedBox(height: isMobile ? 60 : 100),

                      // Section 3: Our Technology Flow
                      Column(
                        children: [
                          Text(
                            'How Our Technology Works',
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 32,
                              fontWeight: FontWeight.bold,
                              color: darkSlate,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'From speech recording to open-source dataset deployment.',
                            style: TextStyle(color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          isMobile
                              ? Column(
                                  children: [
                                    _buildTechStep(
                                      icon: Icons.phone_android_rounded,
                                      title: '1. Mobile Recording',
                                      description: 'Contributors record prompts using their native language directly within the mobile application.',
                                    ),
                                    const SizedBox(height: 24),
                                    _buildTechStep(
                                      icon: Icons.check_circle_outline_rounded,
                                      title: '2. Community Validation',
                                      description: 'Other speakers review the recorded voice clips to ensure high audio clarity and exact script matching.',
                                    ),
                                    const SizedBox(height: 24),
                                    _buildTechStep(
                                      icon: Icons.cloud_done_outlined,
                                      title: '3. Dataset Curation',
                                      description: 'Audio recordings are anonymized, structured, and packaged into open corpora for developers and researchers.',
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildTechStep(
                                        icon: Icons.phone_android_rounded,
                                        title: '1. Mobile Recording',
                                        description: 'Contributors record prompts using their native language directly within the mobile application.',
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    Expanded(
                                      child: _buildTechStep(
                                        icon: Icons.check_circle_outline_rounded,
                                        title: '2. Community Validation',
                                        description: 'Other speakers review the recorded voice clips to ensure high audio clarity and exact script matching.',
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    Expanded(
                                      child: _buildTechStep(
                                        icon: Icons.cloud_done_outlined,
                                        title: '3. Dataset Curation',
                                        description: 'Audio recordings are anonymized, structured, and packaged into open corpora for developers and researchers.',
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 60 : 100),

                      // Section: Meet the Team
                      Column(
                        children: [
                          Text(
                            'Meet the Team',
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 32,
                              fontWeight: FontWeight.bold,
                              color: darkSlate,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'The passionate individuals driving the Ateker Voices initiative.',
                            style: TextStyle(color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(color: Colors.grey.withAlpha(40)),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 24 : 40),
                              child: isMobile
                                  ? Column(
                                      children: [
                                        _buildTeamImage(),
                                        const SizedBox(height: 24),
                                        _buildTeamDetails(isMobile, atekerOrange),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildTeamImage(),
                                        const SizedBox(width: 48),
                                        Expanded(
                                          child: _buildTeamDetails(isMobile, atekerOrange),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 60 : 100),

                      // Section 4: Get Involved Call-To-Action
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: Colors.grey.withAlpha(40)),
                        ),
                        color: const Color(0xFFF8FAFC),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 24 : 48),
                          child: Column(
                            children: [
                              const Icon(Icons.people_rounded, size: 48, color: atekerOrange),
                              const SizedBox(height: 16),
                              Text(
                                'Get Involved Today',
                                style: TextStyle(
                                  fontSize: isMobile ? 22 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: darkSlate,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Whether you speak an Ateker language, validate translations, write code, or represent an educational research institute, there is a place for you in the Ateker Voices Initiative.',
                                style: TextStyle(color: Colors.black, height: 1.6),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/');
                                    },
                                    icon: const Icon(Icons.mobile_screen_share_rounded),
                                    label: const Text('Download App'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: atekerOrange,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/datasets');
                                    },
                                    icon: const Icon(Icons.folder_open_rounded),
                                    label: const Text('View Datasets'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: darkSlate,
                                      side: const BorderSide(color: darkSlate),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildTwoColumnRow({
    required bool isMobile,
    required String title,
    required String content,
    required Widget imageWidget,
    required bool imageFirst,
  }) {
    final textCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          content,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            height: 1.6,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          imageWidget,
          const SizedBox(height: 24),
          textCol,
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (imageFirst) ...[
            Expanded(child: imageWidget),
            const SizedBox(width: 64),
          ],
          Expanded(flex: 2, child: textCol),
          if (!imageFirst) ...[
            const SizedBox(width: 64),
            Expanded(child: imageWidget),
          ],
        ],
      );
    }
  }

  Widget _buildTechStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD06E1A), size: 36),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.black, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamImage() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD06E1A), width: 3),
        image: const DecorationImage(
          image: AssetImage('assets/images/simon.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTeamDetails(bool isMobile, Color themeColor) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const Text(
          'Simon',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ML Researcher - Makerere University Centre for Artificial Intelligence (MAK-AI)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeColor,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 16),
        Text(
          'Simon is a researcher at the MAK-AI Center, focusing on Computer Vision and NLP.',
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.5,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 20),
        const Text(
          'Interests:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _buildInterestChip('Voice AI for low-resource African languages.'),
            _buildInterestChip('AI for Social good'),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF334155),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
