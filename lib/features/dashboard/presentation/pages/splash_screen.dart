import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.go('/onboarding'); // ✅ always
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Kachra Alert',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
