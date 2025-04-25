import 'dart:async';
import 'package:customer/controller/splash_controller.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Asegúrate de que el PageView esté completamente construido antes de interactuar con el PageController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
        init: SplashController(),
        builder: (controller) {
          return Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Fondo de imagen
                Image.asset(
                  "assets/images/driver-woman.jpg", // Cambia esto por tu imagen
                  fit: BoxFit.cover,
                ),
                PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Página 1 - Solo logo
                    Center(
                      child: Image.asset(
                        "assets/app_logo.png",
                        width: 200,
                      ),
                    ),
                    // Página 2 - Logo + Texto
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/app_logo.png",
                          width: 200,
                        ),
                        const SizedBox(height: 20),
                        AnimatedOpacity(
                          opacity: _currentPage == 1 ? 1.0 : 0.0,
                          duration: const Duration(seconds: 1),
                          child: const Text(
                            'Bienvenidos',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                ),
              ],
            ),
          );
        });
  }
}
