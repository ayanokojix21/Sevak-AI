import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/need_entity.dart';

class NeedModel extends NeedEntity {
  const NeedModel({
    required super.id,
    required super.rawText,
    super.imageUrl,
    required super.location,
    required super.lat,
    required super.lng,
    required super.needType,
    required super.urgencyScore,
    required super.urgencyReason,
    required super.peopleAffected,
    required super.status,
    required super.submittedBy,
    super.assignedTo,
    super.matchReason,
    required super.ngoId,
    required super.createdAt,
  });

  factory NeedModel.fromEntity(NeedEntity entity) {
    return NeedModel(
      id: entity.id,
      rawText: entity.rawText,
      imageUrl: entity.imageUrl,
      location: entity.location,
      lat: entity.lat,
      lng: entity.lng,
      needType: entity.needType,
      urgencyScore: entity.urgencyScore,
      urgencyReason: entity.urgencyReason,
      peopleAffected: entity.peopleAffected,
      status: entity.status,
      submittedBy: entity.submittedBy,
      assignedTo: entity.assignedTo,
      matchReason: entity.matchReason,
      ngoId: entity.ngoId,
      createdAt: entity.createdAt,
    );
  }

  factory NeedModel.fromJson(Map<String, dynamic> json, String id) {
    return NeedModel(
      id: id,
      rawText: json['rawText'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      location: json['location'] as String? ?? 'Unknown',
      lat: ((json['lat'] ?? 0) as num).toDouble(),
      lng: ((json['lng'] ?? 0) as num).toDouble(),
      needType: json['needType'] as String? ?? 'OTHER',
      urgencyScore: (json['urgencyScore'] as num?)?.toInt() ?? 0,
      urgencyReason: json['urgencyReason'] as String? ?? '',
      peopleAffected: (json['peopleAffected'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'RAW',
      submittedBy: json['submittedBy'] as String? ?? '',
      assignedTo: json['assignedTo'] as String?,
      matchReason: json['matchReason'] as String?,
      ngoId: json['ngoId'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rawText': rawText,
      'imageUrl': imageUrl,
      'location': location,
      'lat': lat,
      'lng': lng,
      'needType': needType,
      'urgencyScore': urgencyScore,
      'urgencyReason': urgencyReason,
      'peopleAffected': peopleAffected,
      'status': status,
      'submittedBy': submittedBy,
      'assignedTo': assignedTo,
      'matchReason': matchReason,
      'ngoId': ngoId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
