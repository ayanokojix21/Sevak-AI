import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../providers/auth_providers.dart';

/// Page for registering a new NGO. Creates with status: 'pending'.
/// Super Admin must approve before it appears in discovery.
class RegisterNgoPage extends ConsumerStatefulWidget {
  const RegisterNgoPage({super.key});

  @override
  ConsumerState<RegisterNgoPage> createState() => _RegisterNgoPageState();
}

class _RegisterNgoPageState extends ConsumerState<RegisterNgoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _descController = TextEditingController();
  final Set<String> _operatingAreas = {};
  bool _isLoading = false;

  static const _areaOptions = [
    'Medical Aid',
    'Food Distribution',
    'Shelter',
    'Education',
    'Disaster Relief',
    'Clothing',
    'Counseling',
    'Rescue Operations',
    'Women Empowerment',
    'Child Welfare',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_operatingAreas.isEmpty) {
      SnackbarUtils.showError(context, 'Select at least one operating area');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = ref.read(volunteerProfileProvider).value;
      if (profile == null) throw Exception('Not logged in');

      await FirebaseFirestore.instance
          .collection(AppConstants.ngosCollection)
          .add({
        'name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'description': _descController.text.trim(),
        'status': 'pending',
        'adminUid': profile.uid,
        'coordinatorUid': profile.uid,
        'hqLat': 0.0,
        'hqLng': 0.0,
        'volunteerCount': 0,
        'operatingAreas': _operatingAreas.toList(),
        'sharedSkillCategories': <String>[],
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'NGO registered! Awaiting Super Admin approval.');
        context.pop();
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your NGO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: cs.surfaceContainerLow,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon header
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.add_business,
                          color: cs.onPrimaryContainer, size: 32),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Create Your Organization',
                      style: tt.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    'Your NGO will be reviewed by a Super Admin before going live.',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'NGO Name',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Headquarters City',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('OPERATING AREAS',
                      style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant, letterSpacing: 1.0)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _areaOptions.map((area) {
                      final selected = _operatingAreas.contains(area);
                      return FilterChip(
                        label: Text(area),
                        selected: selected,
                        onSelected: (val) => setState(() {
                          val
                              ? _operatingAreas.add(area)
                              : _operatingAreas.remove(area);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  FilledButton(
                    onPressed: _isLoading ? null : _onSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Submit for Approval'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
