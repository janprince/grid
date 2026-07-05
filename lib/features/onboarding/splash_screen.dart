import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void initState() {
    super.initState();
    // The router redirect sends the user to onboarding, login or home
    // depending on the persisted session.
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) context.go(Routes.home);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GridLogo(size: 88, onDark: true),
              Gaps.xxl,
              const GridWordmark(fontSize: 34, onDark: true),
              Gaps.md,
              Text(
                'The operating system for your home',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onForestMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
