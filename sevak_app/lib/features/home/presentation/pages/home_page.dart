import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
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
                ElevatedButton.icon(
                  onPressed: () => context.push('/submit-need'),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Report a Need'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                if (volunteer.platformRole == 'CU' || volunteer.platformRole == 'VL')
                  TextButton.icon(
                    onPressed: () {
                      final textController = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Redeem Invite Code'),
                          content: TextField(
                            controller: textController,
                            decoration: const InputDecoration(labelText: 'Enter 6-digit code'),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                try {
                                  await ref.read(authControllerProvider.notifier).consumeInviteCode(textController.text.trim());
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully assigned role!')));
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              },
                              child: const Text('Redeem'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Join an NGO (Enter Code)'),
                  ),
                const SizedBox(height: 16),
                // Phase 3 — Coordinator Dashboard access
                if (volunteer.platformRole == 'SA' || volunteer.platformRole == 'NA' || volunteer.platformRole == 'CO')
                  OutlinedButton.icon(
                    onPressed: () => context.push('/dashboard'),
                    icon: const Icon(Icons.dashboard_rounded),
                    label: const Text('Coordinator Dashboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                const SizedBox(height: 16),
                if (volunteer.platformRole == 'SA')
                  OutlinedButton.icon(
                    onPressed: () => context.push('/super-admin'),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Super Admin Panel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                const SizedBox(height: 16),
                if (volunteer.platformRole == 'NA' || volunteer.platformRole == 'SA')
                  OutlinedButton.icon(
                    onPressed: () => context.push('/ngo-admin/${volunteer.primaryNgoId.isNotEmpty ? volunteer.primaryNgoId : "test-ngo-id"}'),
                    icon: const Icon(Icons.business),
                    label: const Text('NGO Admin Panel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
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
