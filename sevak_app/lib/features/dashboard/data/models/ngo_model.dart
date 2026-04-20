import '../../domain/entities/ngo_entity.dart';

/// Firestore-serializable model for NGO entities.
class NgoModel extends NgoEntity {
  const NgoModel({
    required super.id,
    required super.name,
    required super.coordinatorUid,
    required super.city,
  });

  factory NgoModel.fromJson(Map<String, dynamic> json, String documentId) {
    return NgoModel(
      id: documentId,
      name: json['name'] as String? ?? '',
      coordinatorUid: json['coordinatorUid'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'coordinatorUid': coordinatorUid,
      'city': city,
    };
  }
}
