import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

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
      if (mounted) {
        SnackbarUtils.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your NGO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgSurface.withAlpha(150),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.add_business, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create Your Organization',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your NGO will be reviewed by a Super Admin before going live.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'NGO Name',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Headquarters City',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
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

                    const Text(
                      'OPERATING AREAS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _areaOptions.map((area) {
                        final selected = _operatingAreas.contains(area);
                        return FilterChip(
                          label: Text(area),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              val ? _operatingAreas.add(area) : _operatingAreas.remove(area);
                            });
                          },
                          selectedColor: AppColors.primary.withAlpha(40),
                          checkmarkColor: AppColors.primary,
                          side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                          labelStyle: TextStyle(
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _onSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Submit for Approval',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
