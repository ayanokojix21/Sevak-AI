import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) SnackbarUtils.showError(context, next.error.toString());
    });

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: widget.isEditing
          ? AppBar(
              title: const Text('Edit Profile'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isEditing) ...[
                  // M3 step indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Step 2 of 2 — Your Profile',
                      style: GoogleFonts.roboto(
                        color: cs.onTertiaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Complete your\nprofile',
                    style: tt.headlineLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help us match you with the right opportunities.',
                    style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Form Card ────────────────────────────────────────
                Card(
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
                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Phone number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          // City + GPS detect
                          TextFormField(
                            controller: _cityController,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'City',
                              prefixIcon: const Icon(Icons.location_city_outlined),
                              suffixIcon: _isDetectingLocation
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: cs.primary,
                                        ),
                                      ),
                                    )
                                  : Tooltip(
                                      message: 'Auto-detect my city',
                                      child: IconButton(
                                        icon: Icon(Icons.my_location,
                                            color: cs.primary),
                                        onPressed: _detectCity,
                                      ),
                                    ),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Skills Card ───────────────────────────────────────
                Card(
                  color: cs.surfaceContainerLow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.volunteer_activism,
                                size: 18, color: cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Your skills',
                              style: tt.titleMedium?.copyWith(
                                  color: cs.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select all that apply (at least 1)',
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
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
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Submit ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: authState.isLoading ? null : _onComplete,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            widget.isEditing ? 'Save changes' : 'Complete setup',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
