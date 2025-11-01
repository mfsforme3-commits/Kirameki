import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kirameki_flutter/routes/app_router.dart';
import 'package:kirameki_flutter/shared/widgets/kirameki_badge.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      context.go(BrowseRoute.path);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.2, -0.5),
            radius: 1.4,
            colors: [
              Color(0x33DC2626),
              Colors.black,
            ],
          ),
        ),
        child: const Center(
          child: KiramekiBadge(size: 96),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            'Kirameki — ignite your anime journey',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
