import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages Super Admin email list from Firestore `platformConfig/superAdmins`.
/// Falls back to hardcoded list if Firestore is unavailable (offline).
class SuperAdminConfig {
  final FirebaseFirestore _firestore;

  /// Hardcoded fallback — used ONLY when Firestore is unreachable.
  static const List<String> _fallbackEmails = [
    'surendrakuma123m@gmail.com',
    'nishchandel21@gmail.com',
    'smarakgartia2415@gmail.com',
    'vinayakgoel012@gmail.com',
  ];

  List<String> _cachedEmails = [];

  SuperAdminConfig({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Loads SA emails from Firestore. Call once at app start.
  Future<void> initialize() async {
    try {
      final doc = await _firestore
          .collection('platformConfig')
          .doc('superAdmins')
          .get();

      if (doc.exists && doc.data() != null) {
        final emails = doc.data()!['emails'];
        if (emails is List) {
          _cachedEmails = emails.cast<String>();
          return;
        }
      }
      // Document doesn't exist yet — create it with defaults
      await _seedDefaults();
      _cachedEmails = List.from(_fallbackEmails);
    } catch (_) {
      // Offline or permission error — use fallback
      _cachedEmails = List.from(_fallbackEmails);
    }
  }

  /// Seeds the Firestore document with default SA emails (first run only).
  Future<void> _seedDefaults() async {
    try {
      await _firestore
          .collection('platformConfig')
          .doc('superAdmins')
          .set({'emails': _fallbackEmails});
    } catch (_) {
      // Ignore — test mode may not have this collection yet
    }
  }

  /// Check if an email is a Super Admin.
  bool isSuperAdmin(String email) {
    final normalizedInput = email.toLowerCase().trim();
    final emails = _cachedEmails.isNotEmpty ? _cachedEmails : _fallbackEmails;
    return emails.any((e) => e.toLowerCase().trim() == normalizedInput);
  }

  /// Get all SA emails.
  List<String> get emails =>
      _cachedEmails.isNotEmpty ? List.unmodifiable(_cachedEmails) : _fallbackEmails;
}

/// Riverpod provider — singleton for the app lifecycle.
final superAdminConfigProvider = Provider<SuperAdminConfig>((ref) {
  return SuperAdminConfig();
});
