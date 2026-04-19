import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volunteerAsync = ref.watch(volunteerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SevakAI Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: volunteerAsync.when(
          data: (volunteer) {
            if (volunteer == null) return const Text('No profile found');
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Welcome, ${volunteer.name}!',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Email: ${volunteer.email}'),
                Text('Phone: ${volunteer.phone}'),
                const SizedBox(height: 24),
                const Text('Phase 2 Needs & Tasks will appear here.'),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text('Error loading profile: $err'),
        ),
      ),
    );
  }
}
