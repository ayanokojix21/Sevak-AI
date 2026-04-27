import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../providers/auth_providers.dart';
import '../../../location/data/location_service.dart';
import '../../../needs/data/datasources/nominatim_datasource.dart';

/// Post-signup profile completion page — also reused as "Edit Profile"
/// when [isEditing] is true (navigated from the home drawer).
class ProfileSetupPage extends ConsumerStatefulWidget {
  final bool isEditing;

  const ProfileSetupPage({super.key, this.isEditing = false});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final Set<String> _selectedSkills = {};
  bool _isDetectingLocation = false;

  static const _availableSkills = [
    'Medical',
    'Food Distribution',
    'Shelter',
    'Logistics',
    'Teaching',
    'Counseling',
    'Clothing',
    'Rescue',
    'First Aid',
    'Driving',
    'Cooking',
    'Translation',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data if available (also used for editing)
    final profile = ref.read(volunteerProfileProvider).value;
    if (profile != null) {
      _nameController.text = profile.name;
      _phoneController.text = profile.phone;
      _cityController.text = profile.city;
      _selectedSkills.addAll(profile.skills);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// Auto-detects the current GPS position and fills the City field
  /// via Nominatim reverse geocoding (takes only the first segment of
  /// the display_name, e.g. "Lucknow" from "Lucknow, Lucknow District, …").
  Future<void> _detectCity() async {
    setState(() => _isDetectingLocation = true);
    try {
      // 1. Check / request location permission
      final hasPerm = await LocationService.hasLocationPermission();
      if (!hasPerm) {
        final result = await LocationService.requestLocationPermission();
        if (result == LocationPermission.denied ||
            result == LocationPermission.deniedForever) {
          if (mounted) {
            SnackbarUtils.showError(context, 'Location permission denied');
          }
          return;
        }
      }

      // 2. Check GPS is enabled
      final isGpsOn = await LocationService.isLocationServiceEnabled();
      if (!isGpsOn) {
        if (mounted) {
          SnackbarUtils.showError(
              context, 'Please enable GPS to auto-detect your city');
        }
        return;
      }

      // 3. Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // 4. Reverse geocode → extract city (first comma-segment of display_name)
      final rawAddress = await NominatimDatasource()
          .reverseGeocode(position.latitude, position.longitude);
      final city = rawAddress.split(',').first.trim();

      if (mounted) {
        setState(() => _cityController.text = city);
        SnackbarUtils.showSuccess(context, 'City detected: $city');
      }
    } catch (e) {
      debugPrint('[ProfileSetup] City detection failed: $e');
      if (mounted) {
        SnackbarUtils.showError(
            context, 'Could not detect location. Please type manually.');
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _onComplete() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      SnackbarUtils.showError(context, 'Please select at least one skill');
      return;
    }

    await ref.read(authControllerProvider.notifier).completeProfileSetup(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          city: _cityController.text.trim(),
          skills: _selectedSkills.toList(),
        );

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      await LocationService().updateVolunteerLocation(uid, force: true);
    }

    if (mounted) {
      if (widget.isEditing) {
        // Return to home after editing
        SnackbarUtils.showSuccess(context, 'Profile updated successfully!');
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) {
        SnackbarUtils.showError(context, next.error.toString());
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.bgBase,
                  Color(0xFF0F2C24),
                  AppColors.bgBase,
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withAlpha(40),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Step / Edit indicator chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withAlpha(60)),
                    ),
                    child: Text(
                      widget.isEditing
                          ? 'Edit Your Profile'
                          : 'Step 2 of 2 — Your Profile',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    widget.isEditing
                        ? 'Update Your\nProfile'
                        : 'Complete Your\nProfile',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isEditing
                        ? 'Change your details and skills anytime.'
                        : 'Help us match you with the right volunteer opportunities.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphic form card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface.withAlpha(150),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withAlpha(20),
                            width: 1.5,
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),

                              // Phone
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),

                              // City — with GPS auto-detect button
                              TextFormField(
                                controller: _cityController,
                                decoration: InputDecoration(
                                  labelText: 'City',
                                  prefixIcon: const Icon(Icons.location_city_outlined),
                                  suffixIcon: _isDetectingLocation
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        )
                                      : Tooltip(
                                          message: 'Auto-detect my city',
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.my_location,
                                              color: AppColors.accent,
                                            ),
                                            onPressed: _detectCity,
                                          ),
                                        ),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 24),

                              // Skills header
                              const Text(
                                'YOUR SKILLS',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Select all that apply (at least 1)',
                                style: TextStyle(
                                  color: AppColors.textDisabled,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableSkills.map((skill) {
                                  final selected = _selectedSkills.contains(skill);
                                  return FilterChip(
                                    label: Text(skill),
                                    selected: selected,
                                    onSelected: (val) {
                                      setState(() {
                                        if (val) {
                                          _selectedSkills.add(skill);
                                        } else {
                                          _selectedSkills.remove(skill);
                                        }
                                      });
                                    },
                                    selectedColor: AppColors.accent.withAlpha(40),
                                    checkmarkColor: AppColors.accent,
                                    side: BorderSide(
                                      color: selected
                                          ? AppColors.accent
                                          : AppColors.border,
                                    ),
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? AppColors.accent
                                          : AppColors.textSecondary,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 32),

                              // Submit button
                              SizedBox(
                                height: 56,
                                child: FilledButton(
                                  onPressed: authState.isLoading ? null : _onComplete,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: authState.isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : Text(
                                          widget.isEditing
                                              ? 'Save Changes'
                                              : 'Complete Setup',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.bgBase,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
