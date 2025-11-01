import 'package:flutter/material.dart';
import 'package:kirameki_flutter/core/constants/app_sizes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme controls, offline auth, and sync toggles will live here.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSizes.lg),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.qr_code),
              label: const Text('Set up device pairing'),
            ),
          ],
        ),
      ),
    );
  }
}
