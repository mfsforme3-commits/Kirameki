import 'package:flutter/material.dart';

class KiramekiBadge extends StatelessWidget {
  const KiramekiBadge({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(size / 3),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
      child: Text(
        'K',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}
