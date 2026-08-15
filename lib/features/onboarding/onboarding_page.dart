import 'package:flutter/material.dart';
import '../../app/routes.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'image': 'assets/images/mascot/avatar2.png',
      'icon': Icons.search,
      'title': 'Discover\nAccessible Places',
      'description':
          'Find destinations, attractions, and facilities that match your accessibility needs.',
      'imageOffset': 0.0,
    },
    {
      'image': 'assets/images/mascot/avatar6.png',
      'icon': Icons.calendar_today_outlined,
      'title': 'Plan\nYour Journey',
      'description':
          'Build a travel itinerary designed around your mobility and accessibility needs.',
      'imageOffset': 15.0,
    },
    {
      'image': 'assets/images/mascot/avatar7.png',
      'icon': Icons.verified_user_outlined,
      'title': 'Travel\nWith Confidence',
      'description':
          'Get accessibility information before you go, so every journey feels easier and more comfortable.',
      'imageOffset': 50.0,
    },
  ];

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/other/splashscreen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.welcome);
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Color(0xFF5B7D46),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return OnboardingContent(
                    image: _onboardingData[index]['image'],
                    icon: _onboardingData[index]['icon'],
                    title: _onboardingData[index]['title'],
                    description: _onboardingData[index]['description'],
                    imageOffsetX: _onboardingData[index]['imageOffset'] ?? 0.0,
                  );
                },
              ),
            ),
            // Bottom section: Indicators and Button
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 64.0),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => buildDot(index, context),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage == _onboardingData.length - 1
                            ? const Color(0xFF4A6B38)
                            : const Color(0xFF86A867),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _onboardingData.length - 1
                            ? 'Start'
                            : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget buildDot(int index, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? const Color(0xFF5B7D46) : Colors.transparent,
        border: Border.all(
          color: const Color(0xFF5B7D46),
          width: 1,
        ),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String image;
  final IconData icon;
  final String title;
  final String description;
  final double imageOffsetX;

  const OnboardingContent({
    super.key,
    required this.image,
    required this.icon,
    required this.title,
    required this.description,
    this.imageOffsetX = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Transform.translate(
              offset: Offset(imageOffsetX, 0),
              child: FractionallySizedBox(
                heightFactor: 0.7, // Reduce size to 70% of available space
                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0DF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5B7D46),
              size: 28,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4A6B38),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
