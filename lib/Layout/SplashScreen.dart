import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), _navigateToNext);
  }

  void _navigateToNext() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_onboarding2') ?? false;
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        hasSeen ? '/home' : '/onboarding',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const double figmaWidth = 390;
    const double figmaHeight = 884;

    final TextStyle letter = GoogleFonts.bodoniModa(
      color: Colors.white,
      fontSize: 148,
      fontWeight: FontWeight.w400,
      height: 1.0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFBFC4C3),
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: ClipRect(
            child: SizedBox(
              width: figmaWidth,
              height: figmaHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [

                  // ─────────────────────────────────────
                  // LAYER 1 — HURUF DI BELAKANG PATUNG
                  // ─────────────────────────────────────
                  Positioned(
                      left: 275, top: 145, child: Text('R', style: letter)),
                  Positioned(
                      left: 18, top: 280, child: Text('T', style: letter)),
                  Positioned(
                      left: 265, top: 552, child: Text('C', style: letter)),
                  Positioned(
                      left: 35, top: 608, child: Text('A', style: letter)),

                  // ─────────────────────────────────────
// LAYER 2 — PATUNG (center, kayak tombol)
// ─────────────────────────────────────
                  Positioned(
                    left: -155,
                    bottom: 109, // 55 (bottom tombol) + 54 (tinggi tombol)
                    child: Image.asset(
                      'assets/image/image_8.png',
                      width: 560,
                      height: 700,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // ─────────────────────────────────────
                  // LAYER 3 — HURUF DI DEPAN PATUNG
                  // ─────────────────────────────────────
                  Positioned(
                      left: 95, top: 27, child: Text('A', style: letter)),
                  Positioned(
                      left: 220, top: 305, child: Text('H', style: letter)),
                  Positioned(
                      left: 100, top: 440, child: Text('E', style: letter)),



                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}