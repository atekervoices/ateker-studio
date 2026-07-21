import 'package:flutter/material.dart';
import 'web_components.dart';

class DatasetsPage extends StatefulWidget {
  const DatasetsPage({super.key});

  static const routeName = '/datasets';

  @override
  State<DatasetsPage> createState() => _DatasetsPageState();
}

class _DatasetsPageState extends State<DatasetsPage> with TickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedLanguage = 'All';
  int? _playingDatasetIndex;
  late AnimationController _waveController;

  final List<Map<String, dynamic>> _datasets = [
    {
      'id': 1,
      'name': 'Karimojong Speech Corpus',
      'language': 'Karimojong',
      'hours': '18.4 hrs',
      'speakers': 52,
      'phrases': 7420,
      'format': 'WAV, 16kHz, Mono',
      'license': 'CC-BY-SA 4.0',
      'description': 'A high-fidelity speech dataset containing everyday conversations, prompts reading, and description audio files. Spoken by native speakers in Moroto and Kotido districts.',
      'size': '3.2 GB',
      'sampleText': 'Ejok konyen, ebuni edia a ekon ekes.',
    },
    {
      'id': 2,
      'name': 'Turkana Audio Dataset',
      'language': 'Turkana',
      'hours': '12.8 hrs',
      'speakers': 38,
      'phrases': 5110,
      'format': 'WAV, 16kHz, Mono',
      'license': 'CC-BY-SA 4.0',
      'description': 'A clean speech collection recorded in Lodwar and surrounding areas, focusing on core agricultural and health terminologies alongside conversational phrases.',
      'size': '2.1 GB',
      'sampleText': 'Mata, ekoni ngikeju ka ngipese.',
    },
    {
      'id': 3,
      'name': 'Iteso Voice Collection',
      'language': 'Iteso',
      'hours': '24.5 hrs',
      'speakers': 85,
      'phrases': 10240,
      'format': 'WAV, 16kHz, Mono',
      'license': 'CC-BY-SA 4.0',
      'description': 'The largest speech corpus in the collection. Features recordings of historical narrations, folk tales, and standard sentences from both eastern Uganda and western Kenya.',
      'size': '4.8 GB',
      'sampleText': 'Yogera, eipone bo akaulo a atesot.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _togglePlay(int index) {
    setState(() {
      if (_playingDatasetIndex == index) {
        _playingDatasetIndex = null;
        _waveController.stop();
      } else {
        _playingDatasetIndex = index;
        _waveController.repeat(reverse: true);
      }
    });
  }

  void _showRequestAccessDialog(BuildContext context, String datasetName) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final purposeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Request Access to Dataset',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are requesting access to download the $datasetName.',
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: 'Enter your name'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Enter your email'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Research/Usage Purpose', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: purposeController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Briefly explain how you plan to use this dataset...',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Purpose is required' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);
                      
                      // Simulate api call
                      await Future.delayed(const Duration(milliseconds: 1200));
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Access request for $datasetName submitted! We will email you shortly.'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD06E1A)),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 800;
    const atekerOrange = Color(0xFFD06E1A);
    const darkSlate = Color(0xFF1E293B);

    final filteredDatasets = _datasets.where((d) {
      final matchesSearch = d['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d['description'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesLanguage = _selectedLanguage == 'All' || d['language'] == _selectedLanguage;
      return matchesSearch && matchesLanguage;
    }).toList();

    return Scaffold(
      appBar: const WebNavBar(currentRoute: '/datasets'),
      drawer: const WebDrawer(currentRoute: '/datasets'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero / Header Strip ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 80, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FAFC), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
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
                          'OPEN SOURCE DATASETS',
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
                        'Ateker Open Datasets',
                        style: TextStyle(
                          fontSize: isMobile ? 32 : 48,
                          fontWeight: FontWeight.w900,
                          color: darkSlate,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Download high-quality voice corpora collected under the Ateker Voices initiative.',
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

            // ── Grid Stats Row ──
            Container(
              color: const Color(0xFF1A1C23),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              width: double.infinity,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: isMobile
                      ? Wrap(
                          spacing: 32,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children: const [
                            _HeaderStat(value: '55.7 Hours', label: 'Audio Collected'),
                            _HeaderStat(value: '175+', label: 'Native Speakers'),
                            _HeaderStat(value: '22,770+', label: 'Verified Phrases'),
                            _HeaderStat(value: '3', label: 'Ateker Dialects'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            _HeaderStat(value: '55.7 Hours', label: 'Audio Collected'),
                            _HeaderStat(value: '175+', label: 'Native Speakers'),
                            _HeaderStat(value: '22,770+', label: 'Verified Phrases'),
                            _HeaderStat(value: '3', label: 'Ateker Dialects'),
                          ],
                        ),
                ),
              ),
            ),

            // ── Filters & Main Content ──
            Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 80, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      // Filter bar
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.withAlpha(40)),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Flex(
                            direction: isMobile ? Axis.vertical : Axis.horizontal,
                            children: [
                              Expanded(
                                flex: isMobile ? 0 : 3,
                                child: TextField(
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                  decoration: InputDecoration(
                                    hintText: 'Search datasets...',
                                    prefixIcon: const Icon(Icons.search_rounded),
                                    fillColor: const Color(0xFFF8FAFC),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              if (isMobile) const SizedBox(height: 12) else const SizedBox(width: 16),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedLanguage,
                                decoration: InputDecoration(
                                  labelText: 'Language Dialect',
                                  constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 200),
                                  fillColor: const Color(0xFFF8FAFC),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: ['All', 'Karimojong', 'Turkana', 'Iteso']
                                    .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => _selectedLanguage = val ?? 'All');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Datasets List
                      if (filteredDatasets.isEmpty)
                        Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.folder_open_rounded, size: 64, color: Colors.black),
                              SizedBox(height: 16),
                              Text(
                                'No datasets match your search parameters.',
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredDatasets.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 24),
                          itemBuilder: (context, index) {
                            final dataset = filteredDatasets[index];
                            final isPlaying = _playingDatasetIndex == dataset['id'];

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(color: Colors.grey.withAlpha(40)),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 20 : 32),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: atekerOrange.withAlpha(25),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            dataset['language'],
                                            style: const TextStyle(
                                              color: atekerOrange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          dataset['size'],
                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      dataset['name'],
                                      style: TextStyle(
                                        fontSize: isMobile ? 20 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: darkSlate,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      dataset['description'],
                                      style: const TextStyle(color: Colors.black, height: 1.6),
                                    ),
                                    const SizedBox(height: 24),

                                    // Quick Stats Row
                                    Wrap(
                                      spacing: 24,
                                      runSpacing: 12,
                                      children: [
                                        _BadgeStat(icon: Icons.timer_outlined, label: dataset['hours']),
                                        _BadgeStat(icon: Icons.people_alt_outlined, label: '${dataset['speakers']} Speakers'),
                                        _BadgeStat(icon: Icons.record_voice_over_outlined, label: '${dataset['phrases']} Phrases'),
                                        _BadgeStat(icon: Icons.audiotrack_outlined, label: dataset['format']),
                                        _BadgeStat(icon: Icons.gavel_outlined, label: dataset['license']),
                                      ],
                                    ),

                                    const SizedBox(height: 32),
                                    const Divider(color: Color(0xFFF1F5F9)),
                                    const SizedBox(height: 16),

                                    // Interactive Sample Row
                                    Flex(
                                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                                      crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                                      children: [
                                        // Play preview
                                        GestureDetector(
                                          onTap: () => _togglePlay(dataset['id']),
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: isPlaying ? atekerOrange.withAlpha(20) : const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isPlaying ? atekerOrange : Colors.grey.withAlpha(40),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                    color: isPlaying ? atekerOrange : Colors.black,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    isPlaying ? 'Playing Preview...' : 'Listen Sample Text',
                                                    style: TextStyle(
                                                      color: isPlaying ? atekerOrange : const Color(0xFF1E293B),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16, height: 16),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.comment_outlined, size: 16, color: Colors.black),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '"${dataset['sampleText']}"',
                                                    style: const TextStyle(
                                                      fontStyle: FontStyle.italic,
                                                      color: Colors.black,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16, height: 16),
                                        FilledButton.icon(
                                          onPressed: () => _showRequestAccessDialog(context, dataset['name']),
                                          icon: const Icon(Icons.download_rounded, size: 16),
                                          label: const Text('Download Access'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: atekerOrange,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderStat({required this.value, required this.label});

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
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BadgeStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BadgeStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
