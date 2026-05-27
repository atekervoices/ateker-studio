import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/l10n/app_localizations.dart';
import '../repos/onboarding_repository.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _selectedAge = '';
  String _selectedGender = '';
  String _selectedLanguage = '';
  String _selectedDialect = '';

  static const _ageRanges = [
    'Under 18',
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55-64',
    '65+',
  ];

  static const _genders = [
    'Male',
    'Female',
  ];

  static const _languages = [
    'Ng\'akarimojong',
    'Ateso',
  ];

  static const _dialectsByLanguage = <String, List<String>>{
    "Ng'akarimojong": ['Jie', 'Dodoth', 'Bokora', 'Matheniko', 'Pian'],
    'Ateso': [],
  };

  List<String> get _currentDialects {
    if (_selectedLanguage.isEmpty) return [];
    return _dialectsByLanguage[_selectedLanguage] ?? [];
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return _selectedAge.isNotEmpty;
      case 1:
        return _selectedGender.isNotEmpty;
      case 2:
        return _selectedLanguage.isNotEmpty;
      case 3:
        if (_currentDialects.isEmpty) return true;
        return _selectedDialect.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      // If language has no dialects, skip dialect page
      if (_currentPage == 2 && _currentDialects.isEmpty) {
        _completeOnboarding();
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  void _completeOnboarding() {
    final dialect = _selectedDialect.isEmpty ? _selectedLanguage : _selectedDialect;
    Provider.of<OnboardingRepository>(context, listen: false).saveProfile(
      age: _selectedAge,
      gender: _selectedGender,
      language: _selectedLanguage,
      dialect: dialect,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildDropdownPage(
                    icon: Icons.cake_outlined,
                    title: l10n.onboardingAgeTitle,
                    subtitle: l10n.onboardingAgeSubtitle,
                    options: _ageRanges,
                    selected: _selectedAge,
                    onSelect: (v) => setState(() => _selectedAge = v),
                  ),
                  _buildChoicePage(
                    icon: Icons.person_outline,
                    title: l10n.onboardingGenderTitle,
                    subtitle: l10n.onboardingGenderSubtitle,
                    options: _genders,
                    selected: _selectedGender,
                    onSelect: (v) => setState(() => _selectedGender = v),
                  ),
                  _buildDropdownPage(
                    icon: Icons.translate,
                    title: l10n.onboardingLanguageTitle,
                    subtitle: "This helps us collect and digitise your language",
                    options: _languages,
                    selected: _selectedLanguage,
                    onSelect: (v) => setState(() {
                      _selectedLanguage = v;
                      _selectedDialect = '';
                    }),
                  ),
                  _buildDropdownPage(
                    icon: Icons.record_voice_over_outlined,
                    title: l10n.onboardingDialectTitle,
                    subtitle: l10n.onboardingDialectSubtitle,
                    options: _currentDialects,
                    selected: _selectedDialect,
                    onSelect: (v) => setState(() => _selectedDialect = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                        child: Text(l10n.onboardingBack),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canProceed ? _nextPage : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor:
                            theme.colorScheme.primary.withAlpha(100),
                      ),
                      child: Text(
                        _currentPage == 3 ||
                                (_currentPage == 2 &&
                                    _currentDialects.isEmpty)
                            ? l10n.onboardingGetStarted
                            : l10n.onboardingNext,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownPage({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          DropdownButtonFormField<String>(
            initialValue: selected.isEmpty ? null : selected,
            decoration: InputDecoration(
              labelText: title,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onSelect(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChoicePage({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ...options.map((option) {
            final isSelected = selected == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onSelect(option),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withAlpha(25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withAlpha(50),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle,
                            color: theme.colorScheme.primary, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
