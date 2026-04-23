import '../../domain/entities/ngo_entity.dart';

/// Firestore-serializable model for NGO entities (dashboard context).
class NgoModel extends NgoEntity {
  const NgoModel({
    required super.id,
    required super.name,
    super.status,
    super.description,
    super.adminUid,
    super.coordinatorUid,
    super.city,
    super.hqLat,
    super.hqLng,
    super.volunteerCount,
    super.operatingAreas,
    super.sharedSkillCategories,
    required super.createdAt,
  });

  factory NgoModel.fromJson(Map<String, dynamic> json, String documentId) {
    return NgoModel(
      id: documentId,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      description: json['description'] as String? ?? '',
      adminUid: json['adminUid'] as String? ?? json['coordinatorUid'] as String? ?? '',
      coordinatorUid: json['coordinatorUid'] as String? ?? json['adminUid'] as String? ?? '',
      city: json['city'] as String? ?? '',
      hqLat: (json['hqLat'] as num?)?.toDouble() ?? 0.0,
      hqLng: (json['hqLng'] as num?)?.toDouble() ?? 0.0,
      volunteerCount: (json['volunteerCount'] as num?)?.toInt() ?? 0,
      operatingAreas: (json['operatingAreas'] as List<dynamic>?)?.cast<String>() ?? [],
      sharedSkillCategories: (json['sharedSkillCategories'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      'description': description,
      'adminUid': adminUid,
      'coordinatorUid': coordinatorUid,
      'city': city,
      'hqLat': hqLat,
      'hqLng': hqLng,
      'volunteerCount': volunteerCount,
      'operatingAreas': operatingAreas,
      'sharedSkillCategories': sharedSkillCategories,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
