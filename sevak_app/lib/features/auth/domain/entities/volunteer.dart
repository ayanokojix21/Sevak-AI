import 'package:equatable/equatable.dart';

class NgoMembership extends Equatable {
  final String ngoId;
  final String role; // e.g., "VOLUNTEER"
  final DateTime joinedAt;
  final bool crossNgoConsent;
  final String status; // e.g., "ACTIVE", "PAUSED"

  const NgoMembership({
    required this.ngoId,
    required this.role,
    required this.joinedAt,
    required this.crossNgoConsent,
    required this.status,
  });

  factory NgoMembership.fromJson(Map<String, dynamic> json) {
    return NgoMembership(
      ngoId: json['ngoId'] as String? ?? '',
      role: json['role'] as String? ?? 'VOLUNTEER',
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt'] as String) : DateTime.now(),
      crossNgoConsent: json['crossNgoConsent'] as bool? ?? false,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ngoId': ngoId,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'crossNgoConsent': crossNgoConsent,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [ngoId, role, joinedAt, crossNgoConsent, status];
}

/// Represents a registered Volunteer in the SevakAI platform.
class Volunteer extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String primaryNgoId;
  final List<NgoMembership> ngoMemberships;
  final List<String> skills;
  final int activeTasks;
  final DateTime createdAt;

  const Volunteer({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.primaryNgoId,
    required this.ngoMemberships,
    required this.skills,
    this.activeTasks = 0,
    required this.createdAt,
  });

  /// Factory constructor to create a Volunteer from Firestore JSON data
  factory Volunteer.fromJson(Map<String, dynamic> json, String documentId) {
    return Volunteer(
      uid: documentId,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      primaryNgoId: json['primaryNgoId'] as String? ?? (json['ngoId'] as String? ?? ''),
      ngoMemberships: (json['ngoMemberships'] as List<dynamic>?)
              ?.map((e) => NgoMembership.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      skills: json['skills'] != null ? List<String>.from(json['skills'] as Iterable) : [],
      activeTasks: json['activeTasks'] as int? ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
    );
  }

  /// Converts a Volunteer instance into a JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'primaryNgoId': primaryNgoId,
      'ngoMemberships': ngoMemberships.map((m) => m.toJson()).toList(),
      'skills': skills,
      'activeTasks': activeTasks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [uid, name, email, phone, primaryNgoId, ngoMemberships, skills, activeTasks, createdAt];
}
