import 'package:flutter/material.dart';

/// Central definition of all platform roles.
/// Every file references this enum instead of hardcoded strings like 'SA', 'CO'.
enum PlatformRole {
  SA, // Super Admin — platform-wide management
  NA, // NGO Admin — manages a single NGO
  CO, // Coordinator — operational dashboard, claims needs
  VL, // Volunteer — field worker, accepts tasks
  CU, // Community User — public, can submit needs
}

extension PlatformRoleX on PlatformRole {
  /// Firestore string code (matches existing data).
  String get code {
    switch (this) {
      case PlatformRole.SA: return 'SA';
      case PlatformRole.NA: return 'NA';
      case PlatformRole.CO: return 'CO';
      case PlatformRole.VL: return 'VL';
      case PlatformRole.CU: return 'CU';
    }
  }

  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case PlatformRole.SA: return 'Super Admin';
      case PlatformRole.NA: return 'NGO Admin';
      case PlatformRole.CO: return 'Coordinator';
      case PlatformRole.VL: return 'Volunteer';
      case PlatformRole.CU: return 'Community User';
    }
  }

  /// Icon for role badges and navigation.
  IconData get icon {
    switch (this) {
      case PlatformRole.SA: return Icons.admin_panel_settings;
      case PlatformRole.NA: return Icons.business;
      case PlatformRole.CO: return Icons.dashboard_rounded;
      case PlatformRole.VL: return Icons.volunteer_activism;
      case PlatformRole.CU: return Icons.person_outline;
    }
  }

  /// Brand color per role.
  Color get color {
    switch (this) {
      case PlatformRole.SA: return const Color(0xFFFF4444);
      case PlatformRole.NA: return const Color(0xFFFF7043);
      case PlatformRole.CO: return const Color(0xFF6C63FF);
      case PlatformRole.VL: return const Color(0xFF00C897);
      case PlatformRole.CU: return const Color(0xFF9090A8);
    }
  }

  /// Whether this role can access the Coordinator Dashboard.
  bool get canAccessDashboard => this == PlatformRole.SA || this == PlatformRole.NA || this == PlatformRole.CO;

  /// Whether this role can manage an NGO (admin panel).
  bool get canManageNGO => this == PlatformRole.SA || this == PlatformRole.NA;

  /// Whether this role can approve/reject NGOs platform-wide.
  bool get canManagePlatform => this == PlatformRole.SA;

  /// Whether this role can browse & join NGOs.
  bool get canJoinNGO => this == PlatformRole.CU || this == PlatformRole.VL;

  /// Hierarchy level (higher = more privileged). Used for guard checks.
  int get level {
    switch (this) {
      case PlatformRole.SA: return 100;
      case PlatformRole.NA: return 80;
      case PlatformRole.CO: return 60;
      case PlatformRole.VL: return 40;
      case PlatformRole.CU: return 20;
    }
  }

  /// Parse from Firestore string. Defaults to CU if unknown.
  static PlatformRole fromCode(String? code) {
    switch (code) {
      case 'SA': return PlatformRole.SA;
      case 'NA': return PlatformRole.NA;
      case 'CO': return PlatformRole.CO;
      case 'VL': return PlatformRole.VL;
      default: return PlatformRole.CU;
    }
  }
}
