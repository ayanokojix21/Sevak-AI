import 'package:equatable/equatable.dart';

/// Represents a volunteer's membership in a single NGO.
class NgoMembership extends Equatable {
  final String ngoId;
  final String role; // 'VL', 'CO', 'NA'
  final bool crossNgoConsent;
  final String status; // 'active', 'suspended'

  const NgoMembership({
    required this.ngoId,
    required this.role,
    this.crossNgoConsent = false,
    this.status = 'active',
  });

  factory NgoMembership.fromJson(Map<String, dynamic> json) {
    return NgoMembership(
      ngoId: json['ngoId'] as String? ?? '',
      role: json['role'] as String? ?? 'VL',
      crossNgoConsent: json['crossNgoConsent'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'ngoId': ngoId,
        'role': role,
        'crossNgoConsent': crossNgoConsent,
        'status': status,
      };

  NgoMembership copyWith({
    String? ngoId,
    String? role,
    bool? crossNgoConsent,
    String? status,
  }) {
    return NgoMembership(
      ngoId: ngoId ?? this.ngoId,
      role: role ?? this.role,
      crossNgoConsent: crossNgoConsent ?? this.crossNgoConsent,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [ngoId, role, crossNgoConsent, status];
}

/// Core Volunteer entity — supports multi-NGO memberships.
class Volunteer extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String primaryNgoId;
  final List<NgoMembership> ngoMemberships;
  final String platformRole; // 'SA', 'NA', 'CO', 'VL', 'CU'
  final List<String> skills;
  final int activeTasks;
  final bool isProfileComplete;
  final bool isAvailable;
  final DateTime createdAt;

  const Volunteer({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.city = '',
    required this.primaryNgoId,
    required this.ngoMemberships,
    required this.platformRole,
    this.skills = const [],
    this.activeTasks = 0,
    this.isProfileComplete = false,
    this.isAvailable = true,
    required this.createdAt,
  });

  /// Create from Firestore document data.
  factory Volunteer.fromJson(Map<String, dynamic> json, String uid) {
    final memberships = (json['ngoMemberships'] as List<dynamic>?)
            ?.map((m) => NgoMembership.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    return Volunteer(
      uid: uid,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
      primaryNgoId: json['primaryNgoId'] as String? ?? '',
      ngoMemberships: memberships,
      platformRole: json['platformRole'] as String? ?? 'CU',
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      activeTasks: (json['activeTasks'] as num?)?.toInt() ?? 0,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'city': city,
        'primaryNgoId': primaryNgoId,
        'ngoMemberships': ngoMemberships.map((m) => m.toJson()).toList(),
        'platformRole': platformRole,
        'skills': skills,
        'activeTasks': activeTasks,
        'isProfileComplete': isProfileComplete,
        'isAvailable': isAvailable,
        'createdAt': createdAt.toIso8601String(),
      };

  Volunteer copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? city,
    String? primaryNgoId,
    List<NgoMembership>? ngoMemberships,
    String? platformRole,
    List<String>? skills,
    int? activeTasks,
    bool? isProfileComplete,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return Volunteer(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      primaryNgoId: primaryNgoId ?? this.primaryNgoId,
      ngoMemberships: ngoMemberships ?? this.ngoMemberships,
      platformRole: platformRole ?? this.platformRole,
      skills: skills ?? this.skills,
      activeTasks: activeTasks ?? this.activeTasks,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Whether this volunteer is a member of a specific NGO.
  bool isMemberOf(String ngoId) {
    return ngoMemberships.any((m) => m.ngoId == ngoId && m.status == 'active');
  }

  @override
  List<Object?> get props => [
        uid, name, email, phone, city, primaryNgoId,
        ngoMemberships, platformRole, skills, activeTasks,
        isProfileComplete, isAvailable, createdAt,
      ];
}
