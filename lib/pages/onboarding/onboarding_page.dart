import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const List<_SlideData> _slides = <_SlideData>[
    _SlideData(
      title: 'Welcome to EduAI',
      subtitle:
          'A focused learning space where students learn better and teachers manage everything in one place.',
      icon: Icons.school_rounded,
    ),
    _SlideData(
      title: 'Smart Study Materials',
      subtitle:
          'Students can access class-wise subject notes, chapters, and PDFs organized by their assigned class.',
      icon: Icons.menu_book_rounded,
    ),
    _SlideData(
      title: 'Quiz and Progress Tracking',
      subtitle:
          'Practice quizzes, review attempts, and monitor performance with clear subject-wise progress.',
      icon: Icons.quiz_rounded,
    ),
    _SlideData(
      title: 'AI Chat and Wellbeing',
      subtitle:
          'Students can ask learning doubts with AI support and track daily mood and reflection for balanced growth.',
      icon: Icons.chat_bubble_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_index == _slides.length - 1) {
      widget.onComplete();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppTheme.pageBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                child: Row(
                  children: <Widget>[
                    const Spacer(),
                    if (_index != _slides.length - 1)
                      TextButton(
                        onPressed: widget.onComplete,
                        child: const Text('Skip'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (int value) {
                    setState(() => _index = value);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final _SlideData slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration(radius: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                gradient: AppTheme.heroGradient,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                slide.icon,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkText,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.secondaryText,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Row(
                  children: <Widget>[
                    ...List<Widget>.generate(_slides.length, (int dotIndex) {
                      final bool active = dotIndex == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.primaryBlue
                              : const Color(0xFFBFD1EE),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _goNext,
                      icon: Icon(
                        _index == _slides.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        _index == _slides.length - 1 ? 'Get Started' : 'Next',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
