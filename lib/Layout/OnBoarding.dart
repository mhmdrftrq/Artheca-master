import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart'; // Jangan lupa install package ini

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'image': 'https://images.unsplash.com/photo-1579783928621-7a13d66a62d1?q=80&w=690&auto=format&fit=crop',
      'title': 'Explore Thousands of World Artworks',
      'artInfo': 'MASTERPIECE NO. 402\nVincent van Gogh, 1889',
    },
    {
      'image': 'https://images.unsplash.com/photo-1611273651216-29b4f282d36b?q=80&w=1074&auto=format&fit=crop',
      'title': 'Discover History Through Every Brushstroke',
      'artInfo': 'CLASSIC COLLECTION\nJohannes Vermeer, 1665',
    },
    {
      'image': 'https://images.metmuseum.org/CRDImages/ep/original/DT1961.jpg',
      'title': 'Immerse Yourself in Digital Gallery',
      'artInfo': 'MODERN EXHIBITION\nClaude Monet, 1899',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea wajib biar gak nabrak notch/kamera
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) => setState(() => _currentPage = page),
                itemCount: _slides.length,
                itemBuilder: (context, index) => _buildSlide(_slides[index]),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    // LayoutBuilder + SingleChildScrollView = OBAT OVERFLOW PALING AMPUH
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Container Gambar dengan Ukuran Responsif
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.network(
                        slide['image'],
                        height: MediaQuery.of(context).size.height * 0.4, // 40% dari tinggi layar
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            color: Colors.grey[100],
                            child: const Center(child: CircularProgressIndicator(color: Color(0xFFAC9362))),
                          );
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 20, right: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.white.withOpacity(0.9),
                        child: Text(
                          slide['artInfo'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.bodoniModa( // Pakai font Art biar konsisten
                            fontSize: 10,
                            letterSpacing: 1,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Text(
                  'T H E   A R T H E C A',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFAC9362),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.bodoniModa(
                        fontSize: 28,
                        height: 1.1,
                        color: Colors.black,
                      ),
                      children: [
                        const TextSpan(text: 'Explore '),
                        TextSpan(
                          text: slide['title'].split('Explore ').last,
                          style: TextStyle(
                            color: const Color(0xFFAC9362).withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Immerse yourself in a curated digital experience where every brushstroke tells a story.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20), // Kasih napas dikit di bawah
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ROOM 0${_currentPage + 1} / 03',
            style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (_currentPage < 2) {
                _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
              } else {
                _finishOnboarding();
              }
            },
            child: Container(
              width: double.infinity,
              height: 55,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF8C7647), Color(0xFFC9A03D)]),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPage == 2 ? 'BEGIN YOUR JOURNEY' : 'CONTINUE EXPLORING',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }
}